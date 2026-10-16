"""Publish mounted Btrfs device errors and existing scrub results."""

import argparse
import json
import os
import sys
import tempfile
import time
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


def atomic_write(destination, content):
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


def sample(name, labels, value):
    descriptor = ",".join(f"{key}={json.dumps(value)}" for key, value in labels.items())
    return f"hoenn_btrfs_{name}{{{descriptor}}} {'NaN' if value is None else value}\n"


def scrub_records(path):
    records = {}
    if not path.exists():
        return records
    for line in path.read_text().splitlines():
        if "|" not in line:
            continue
        identity, *fields = line.split("|")
        records[identity] = dict(field.split(":", 1) for field in fields if field)
    return records


def device_metrics(filesystem, device, record, record_mtime, directory):
    labels = {"filesystem": filesystem.name, "device": device.name}
    destination = directory / f"btrfs-{filesystem.name}-{device.name}"
    state_file = destination.with_suffix(".json")
    state = json.loads(state_file.read_text()) if state_file.exists() else {}
    output = [
        "# TYPE hoenn_btrfs_device_errors_total counter\n",
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
        if (finished or canceled) and state.get("record") != record_identity:
            completion = int(record["t_start"]) + int(record["duration"])
            if int(record["t_resumed"]) > int(record["t_start"]):
                # Accumulated scrub duration omits time spent paused.
                completion = record_mtime
            success = (
                finished
                and not canceled
                and int(record["uncorrectable_errors"]) == 0
                and int(record.get("malloc_errors", 0)) == 0
            )
            state.update(
                {
                    "completion": completion,
                    "success": int(success),
                    "duration": int(record["duration"]),
                    "errors": {name: int(record.get(name, 0)) for name in SCRUB_ERRORS},
                    "record": record_identity,
                }
            )
            if success:
                state["last_success"] = completion
            atomic_write(state_file, json.dumps(state))
    else:
        output.append(sample("scrub_finished", labels, None))

    for metric, key in {
        "scrub_last_completion_timestamp_seconds": "completion",
        "scrub_last_success_timestamp_seconds": "last_success",
        "scrub_last_run_success": "success",
        "scrub_duration_seconds": "duration",
    }.items():
        output.append(sample(metric, labels, state.get(key)))
    for name in SCRUB_ERRORS:
        output.append(
            sample(
                "scrub_errors",
                labels | {"kind": name},
                state.get("errors", {}).get(name),
            )
        )
    atomic_write(destination.with_suffix(".prom"), "".join(output))
    return destination.with_suffix(".prom").name


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--directory", type=Path, default=Path("/var/lib/hoenn-metrics/btrfs")
    )
    parser.add_argument("--sysfs", type=Path, default=Path("/sys/fs/btrfs"))
    parser.add_argument("--scrub-directory", type=Path, default=Path("/var/lib/btrfs"))
    arguments = parser.parse_args()
    arguments.directory.mkdir(parents=True, exist_ok=True)
    success = True
    expected = set()
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
            except (OSError, ValueError, KeyError) as error:
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
    output = f"hoenn_btrfs_collector_success {int(success)}\n"
    output += f"hoenn_btrfs_collector_last_run_timestamp_seconds {int(time.time())}\n"
    atomic_write(arguments.directory / "collector.prom", output)


if __name__ == "__main__":
    main()
