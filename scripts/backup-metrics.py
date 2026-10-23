"""Publish Restic service outcomes without changing the backup service result."""

import argparse
import fcntl
import json
import math
import os
import re
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

type Scope = Literal["system", "user"]
type Action = Literal["start", "complete", "seed"]
type Completion = tuple[float, bool]

PREFIX = "restic_backup_"
FIELDS = (
    "last_completion_timestamp_seconds",
    "last_success_timestamp_seconds",
    "last_run_success",
)


@dataclass(frozen=True)
class Backup:
    """Identify a backup and its persistent reporting files."""

    name: str
    directory: Path
    scope: Scope = "system"
    owner: str = "root"
    file_prefix: str = ""

    def path(self, suffix: str) -> Path:
        """Return a reporting file beside this backup's metrics."""
        return self.directory / f"{self.file_prefix}{self.name}.{suffix}"


def properties(backup: Backup) -> dict[str, str]:
    """Read service state from the appropriate systemd manager."""
    command = ["systemctl"]
    if backup.scope == "user":
        command.append("--user")
    output = subprocess.check_output(
        command
        + [
            "show",
            f"restic-backups-{backup.name}.service",
            (
                "--property=ActiveState,Result,ExecMainCode,ExecMainStatus,"
                "ExecMainExitTimestamp,ExecMainExitTimestampMonotonic"
            ),
        ],
        text=True,
        timeout=15,
    )
    return dict(line.split("=", 1) for line in output.splitlines())


def completed_result(backup: Backup, *, historical: bool = False) -> Completion | None:
    """Read a terminal service result, optionally using its recorded exit time."""
    state = properties(backup)
    if state.get("ActiveState") not in {"inactive", "failed"}:
        return None
    timestamp = time.time()
    if historical:
        if int(state.get("ExecMainExitTimestampMonotonic", "0")) == 0:
            return None
        timestamp = float(
            subprocess.check_output(
                ["date", "--date", state["ExecMainExitTimestamp"], "+%s"],
                text=True,
                timeout=15,
            )
        )
    success = (
        state.get("Result") == "success"
        and state.get("ExecMainCode") == "1"
        and state.get("ExecMainStatus") == "0"
    )
    return timestamp, success


def read_values(path: Path) -> dict[str, float]:
    """Read prior outcomes, including metrics written under cluster prefixes."""
    values = dict.fromkeys(FIELDS, math.nan)
    if path.exists():
        for line in path.read_text().splitlines():
            if line.startswith("#") or "_backup_" not in line:
                continue
            metric, value = line.rsplit(" ", 1)
            field = metric.split("{", 1)[0].split("_backup_", 1)[1]
            if field in values:
                values[field] = float(value)
    return values


def write_values(backup: Backup, values: dict[str, float]) -> None:
    """Atomically replace metrics and persist the directory entry."""
    labels = ",".join(
        f"{key}={json.dumps(value)}"
        for key, value in {
            "backup": backup.name,
            "scope": backup.scope,
            "owner": backup.owner,
        }.items()
    )
    descriptor, temporary = tempfile.mkstemp(dir=backup.directory, suffix=".tmp")
    try:
        with os.fdopen(descriptor, "w") as output:
            os.fchmod(output.fileno(), 0o644)
            for field, value in {"job_info": 1.0, **values}.items():
                sample = "NaN" if math.isnan(value) else repr(value)
                output.write(f"# TYPE {PREFIX}{field} gauge\n")
                output.write(f"{PREFIX}{field}{{{labels}}} {sample}\n")
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, backup.path("prom"))
        directory_fd = os.open(backup.directory, os.O_DIRECTORY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    finally:
        Path(temporary).unlink(missing_ok=True)


def report(backup: Backup, action: Action = "complete") -> None:
    """Preserve prior success across failures, interruptions, and boot seeding."""
    backup.directory.mkdir(parents=True, exist_ok=True)
    with backup.path("lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        pending = backup.path("running")
        if action == "start":
            pending.touch()
            return
        values = read_values(backup.path("prom"))
        completion = None
        if action == "complete":
            completion = completed_result(backup)
            if completion is None:
                raise RuntimeError(f"Backup {backup.name} has not finished")
        elif pending.exists():
            state = properties(backup)
            if state.get("ActiveState") in {"inactive", "failed"}:
                completion = completed_result(backup, historical=True)
                if completion is None or int(completion[0]) < int(
                    pending.stat().st_mtime
                ):
                    completion = time.time(), False
        elif not backup.path("prom").exists():
            try:
                completion = completed_result(backup, historical=True)
            except (KeyError, ValueError, subprocess.SubprocessError) as error:
                print(f"Cannot seed {backup.name}: {error}", file=sys.stderr)
        if completion is not None:
            timestamp, success = completion
            values["last_completion_timestamp_seconds"] = timestamp
            values["last_run_success"] = float(success)
            if success:
                values["last_success_timestamp_seconds"] = timestamp
        write_values(backup, values)
        if completion is not None:
            pending.unlink(missing_ok=True)


class Arguments(argparse.Namespace):
    """Typed command-line options for system and user reporters."""

    directory: Path
    scope: Scope
    owner: str
    file_prefix: str
    start: bool
    seed: bool
    jobs: list[str]


def main() -> int:
    """Report each configured job while keeping failures out of backup units."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, required=True)
    parser.add_argument("--scope", choices=["system", "user"], default="system")
    parser.add_argument("--owner", default="root")
    parser.add_argument("--file-prefix", choices=["", "backup-"], default="")
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument("--start", action="store_true")
    actions.add_argument("--seed", action="store_true")
    parser.add_argument("jobs", nargs="*")
    arguments = parser.parse_args(namespace=Arguments())
    if not arguments.seed and len(arguments.jobs) != 1:
        parser.error("Start and completion reporting require one backup job")
    for name in arguments.jobs:
        if not re.fullmatch(r"[A-Za-z0-9_.-]+", name):
            parser.error(f"Invalid backup job name: {name}")
    action: Action = (
        "seed" if arguments.seed else "start" if arguments.start else "complete"
    )
    failed = False
    for name in arguments.jobs:
        backup = Backup(
            name,
            arguments.directory,
            arguments.scope,
            arguments.owner,
            arguments.file_prefix,
        )
        try:
            report(backup, action)
        except (
            KeyError,
            OSError,
            RuntimeError,
            ValueError,
            subprocess.SubprocessError,
        ) as error:
            print(f"Backup metrics for {name}: {error}", file=sys.stderr)
            failed = True
    if arguments.seed and not failed:
        expected = {f"{arguments.file_prefix}{name}.prom" for name in arguments.jobs}
        for path in arguments.directory.glob("*.prom"):
            if path.name in expected:
                continue
            if any(
                line.startswith(PREFIX + "job_info{")
                for line in path.read_text().splitlines()
            ):
                path.unlink()
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
