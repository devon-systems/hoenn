"""Publish mounted Btrfs device errors and existing scrub results."""

import argparse
import json
import os
import sys
import tempfile
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from uuid import UUID

DEVICE_ERRORS = {
    "write_errs": "write",
    "read_errs": "read",
    "flush_errs": "flush",
    "corruption_errs": "corruption",
    "generation_errs": "generation",
}
SCRUB_ERRORS = [
    "read_errors",
    "csum_errors",
    "verify_errors",
    "super_errors",
    "corrected_errors",
    "uncorrectable_errors",
    "unverified_errors",
]


def atomic_write(destination: Path, content: str) -> None:
    """Replace a metrics or state file without exposing partial contents."""
    descriptor, temporary = tempfile.mkstemp(dir=destination.parent, suffix=".tmp")
    try:
        with os.fdopen(descriptor, "w") as output:
            os.fchmod(output.fileno(), 0o644)
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, destination)
    finally:
        Path(temporary).unlink(missing_ok=True)


def sample(name: str, labels: dict[str, str], value: float | None) -> str:
    """Format a Prometheus sample with quoted label values."""
    descriptor = ",".join(f"{key}={json.dumps(value)}" for key, value in labels.items())
    return f"btrfs_{name}{{{descriptor}}} {'NaN' if value is None else value}\n"


def scrub_records(path: Path) -> dict[str, dict[str, str]]:
    """Read existing scrub records without starting a scrub."""
    records: dict[str, dict[str, str]] = {}
    if not path.exists():
        return records
    for line in path.read_text().splitlines():
        if "|" not in line:
            continue
        identity, *fields = line.split("|")
        records[identity] = dict(field.split(":", 1) for field in fields if field)
    return records


@dataclass
class ScrubState:
    """Retain completed scrub outcomes while a later scrub is running."""

    completion: int | None = None
    last_success: int | None = None
    success: int | None = None
    duration: int | None = None
    errors: dict[str, int] = field(default_factory=dict)
    record: list[str] | None = None


def read_state(path: Path, legacy: Path) -> ScrubState:
    """Read persisted history or import Johto's previous scrub metrics."""
    if path.exists():
        return ScrubState(**json.loads(path.read_text()))
    state = ScrubState()
    if legacy.exists():
        values = {
            line.split("{", 1)[0]: float(line.rsplit(" ", 1)[1])
            for line in legacy.read_text().splitlines()
            if line.startswith("johto_btrfs_")
        }
        state.completion = int(values["johto_btrfs_scrub_completion_timestamp_seconds"])
        state.success = int(values["johto_btrfs_scrub_success"])
        if state.success:
            state.last_success = state.completion
    return state


def device_metrics(
    filesystem: Path,
    device: Path,
    record: dict[str, str] | None,
    record_mtime: int | None,
    directory: Path,
) -> str:
    """Publish device counters and preserve the most recent completed scrub."""
    labels = {"filesystem": filesystem.name, "device": device.name}
    destination = directory / f"btrfs-{filesystem.name}-{device.name}"
    state_file = destination.with_suffix(".json")
    state = read_state(
        state_file, directory / f"scrub-{filesystem.name}-{device.name}.prom"
    )
    output = [
        "# TYPE btrfs_device_errors_total counter\n",
        sample("device_info", labels, 1),
    ]
    errors = dict(
        line.split() for line in (device / "error_stats").read_text().splitlines()
    )
    for name, operation in DEVICE_ERRORS.items():
        output.append(
            sample(
                "device_errors_total",
                labels | {"operation": operation},
                int(errors[name]),
            )
        )

    if record is not None:
        finished = int(record["finished"]) == 1
        canceled = int(record["canceled"]) == 1
        output.append(sample("scrub_finished", labels, int(finished and not canceled)))
        record_identity = [
            record[key]
            for key in ["t_start", "t_resumed", "duration", "finished", "canceled"]
        ]
        if (finished or canceled) and state.record != record_identity:
            completion = int(record["t_start"]) + int(record["duration"])
            if int(record["t_resumed"]) > int(record["t_start"]):
                # Accumulated scrub duration omits time spent paused.
                if record_mtime is None:
                    raise ValueError("Resumed scrub has no record modification time")
                completion = record_mtime
            success = (
                finished
                and not canceled
                and int(record["uncorrectable_errors"]) == 0
                and int(record.get("malloc_errors", 0)) == 0
            )
            state.completion = completion
            state.success = int(success)
            state.duration = int(record["duration"])
            state.errors = {name: int(record.get(name, 0)) for name in SCRUB_ERRORS}
            state.record = record_identity
            if success:
                state.last_success = completion
    else:
        output.append(sample("scrub_finished", labels, None))
    atomic_write(state_file, json.dumps(asdict(state)))

    for metric, value in {
        "scrub_last_completion_timestamp_seconds": state.completion,
        "scrub_last_success_timestamp_seconds": state.last_success,
        "scrub_last_run_success": state.success,
        "scrub_duration_seconds": state.duration,
    }.items():
        output.append(sample(metric, labels, value))
    for name in SCRUB_ERRORS:
        output.append(
            sample(
                "scrub_errors",
                labels | {"kind": name},
                state.errors.get(name),
            )
        )
    atomic_write(destination.with_suffix(".prom"), "".join(output))
    return destination.with_suffix(".prom").name


class Arguments(argparse.Namespace):
    """Typed filesystem locations supplied by the service or command line."""

    directory: Path
    sysfs: Path
    scrub_directory: Path


def main() -> None:
    """Collect each mounted filesystem and mark partial collection failures."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, required=True)
    parser.add_argument("--sysfs", type=Path, default=Path("/sys/fs/btrfs"))
    parser.add_argument("--scrub-directory", type=Path, default=Path("/var/lib/btrfs"))
    arguments = parser.parse_args(namespace=Arguments())
    arguments.directory.mkdir(parents=True, exist_ok=True)
    success = True
    expected: set[str] = set()
    for filesystem in arguments.sysfs.glob("*"):
        try:
            UUID(filesystem.name)
        except ValueError:
            continue
        if not (filesystem / "devinfo").is_dir():
            continue
        try:
            record_file = arguments.scrub_directory / f"scrub.status.{filesystem.name}"
            records = scrub_records(record_file)
            record_mtime = int(record_file.stat().st_mtime) if records else None
            devices = list((filesystem / "devinfo").iterdir())
        except (OSError, ValueError) as error:
            print(f"Btrfs metrics for {filesystem.name}: {error}", file=sys.stderr)
            success = False
            continue
        for device in devices:
            if not device.name.isdecimal():
                continue
            try:
                expected.add(
                    device_metrics(
                        filesystem,
                        device,
                        records.get(f"{filesystem.name}:{device.name}"),
                        record_mtime,
                        arguments.directory,
                    )
                )
            except (OSError, TypeError, ValueError, KeyError) as error:
                print(
                    f"Btrfs metrics for {filesystem.name}/{device.name}: {error}",
                    file=sys.stderr,
                )
                success = False
    # Keep prior samples on read failure; dashboards gate on collector status.
    if success:
        for path in arguments.directory.glob("btrfs-*.prom"):
            if path.name not in expected:
                path.unlink()
                path.with_suffix(".json").unlink(missing_ok=True)
        for path in arguments.directory.glob("scrub-*.prom"):
            path.unlink()
    output = f"btrfs_collector_success {int(success)}\n"
    output += f"btrfs_collector_last_run_timestamp_seconds {int(time.time())}\n"
    atomic_write(arguments.directory / "collector.prom", output)


if __name__ == "__main__":
    main()
