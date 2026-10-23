"""Publish completed Restic service results for Alloy's textfile collector."""

import argparse
import fcntl
import json
import os
import re
import subprocess
import tempfile
import time
from pathlib import Path

PREFIX = "restic_backup_"


def completed_result(job, scope):
    command = ["systemctl"]
    if scope == "user":
        command.append("--user")
    command.extend(
        [
            "show",
            f"restic-backups-{job}.service",
            "--property=ActiveState,Result,ExecMainCode,ExecMainStatus",
        ]
    )
    result = subprocess.check_output(command, text=True, timeout=15)
    properties = dict(line.split("=", 1) for line in result.splitlines())
    if properties.get("ActiveState") not in {"inactive", "failed"}:
        raise RuntimeError(f"Backup {job} has not finished")
    return (
        properties["Result"] == "success"
        and properties.get("ExecMainCode") == "1"
        and properties.get("ExecMainStatus") == "0"
    )


def report(directory, job, scope, owner, seed):
    destination = directory / f"backup-{job}.prom"
    with (directory / f"backup-{job}.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        values = {
            "job_info": 1,
            "last_completion_timestamp_seconds": "NaN",
            "last_success_timestamp_seconds": "NaN",
            "last_run_success": "NaN",
        }
        if destination.exists():
            for line in destination.read_text().splitlines():
                if not line.startswith("#") and "_backup_" in line:
                    metric, value = line.rsplit(" ", 1)
                    name = metric.split("{", 1)[0].split("_backup_", 1)[1]
                    if name in values:
                        values[name] = value
        if not seed:
            success = completed_result(job, scope)
            timestamp = int(time.time())
            values["last_completion_timestamp_seconds"] = timestamp
            values["last_run_success"] = int(success)
            if success:
                values["last_success_timestamp_seconds"] = timestamp
        labels = ",".join(
            f"{name}={json.dumps(value)}"
            for name, value in {"backup": job, "scope": scope, "owner": owner}.items()
        )
        descriptor, temporary = tempfile.mkstemp(dir=directory, suffix=".tmp")
        try:
            with os.fdopen(descriptor, "w") as output:
                os.fchmod(output.fileno(), 0o644)
                for metric, value in values.items():
                    output.write(f"# TYPE {PREFIX}{metric} gauge\n")
                    output.write(f"{PREFIX}{metric}{{{labels}}} {value}\n")
                output.flush()
                os.fsync(output.fileno())
            os.replace(temporary, destination)
        finally:
            Path(temporary).unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, required=True)
    parser.add_argument("--scope", choices=["system", "user"], required=True)
    parser.add_argument("--owner", required=True)
    parser.add_argument("--seed", action="store_true")
    parser.add_argument("jobs", nargs="*")
    arguments = parser.parse_args()
    if not arguments.seed and len(arguments.jobs) != 1:
        parser.error("Completion reporting requires one backup job")
    for job in arguments.jobs:
        if not re.fullmatch(r"[A-Za-z0-9_.-]+", job):
            parser.error(f"Invalid backup job name: {job}")
    arguments.directory.mkdir(parents=True, exist_ok=True)
    for job in arguments.jobs:
        report(
            arguments.directory, job, arguments.scope, arguments.owner, arguments.seed
        )
    if arguments.seed:
        expected = {f"backup-{job}.prom" for job in arguments.jobs}
        for path in arguments.directory.glob("backup-*.prom"):
            if path.name not in expected:
                path.unlink()


if __name__ == "__main__":
    main()
