#!/usr/bin/env python3
"""Install the pinned Intel macOS developer tools into the workspace."""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import hashlib
import json
import os
import platform
import shutil
import subprocess
import tarfile


def digest(path):
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def install(entry, runtime):
    marker = runtime / "state" / (entry["name"] + ".sha256")
    targets = [runtime / target for target in entry["targets"]]
    ready = (
        marker.exists()
        and marker.read_text().strip() == entry["sha256"]
        and all(target.exists() for target in targets)
    )
    if not ready:
        archive = runtime / "downloads" / entry["filename"]
        archive.parent.mkdir(parents=True, exist_ok=True)
        if not archive.exists() or digest(archive) != entry["sha256"]:
            # Use a separate partial file so failed downloads cannot replace a
            # previously verified artifact.
            partial = archive.with_name(archive.name + ".partial")
            print("Downloading " + entry["name"], flush=True)
            subprocess.run(
                ["curl", "-fLSs", "--connect-timeout", "20", "--max-time", "1200",
                 "--retry", "2", "--continue-at", "-", "-o", str(partial), entry["url"]],
                check=True,
            )
            if digest(partial) != entry["sha256"]:
                raise RuntimeError("SHA256 mismatch: " + entry["filename"])
            partial.replace(archive)
        destination = runtime / entry["destination"]
        if entry["kind"] == "tar":
            destination.mkdir(parents=True, exist_ok=True)
            with tarfile.open(archive) as package:
                for member in package.getmembers():
                    if not (destination / member.name).resolve().is_relative_to(destination.resolve()):
                        raise RuntimeError("Invalid archive path: " + member.name)
                package.extractall(destination)
        else:
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(archive, destination)
            destination.chmod(0o755)
        marker.parent.mkdir(parents=True, exist_ok=True)
        marker.write_text(entry["sha256"] + "\n")
    for link_name, target_name in entry.get("links", {}).items():
        link, target = runtime / link_name, runtime / target_name
        link.parent.mkdir(parents=True, exist_ok=True)
        if link.is_symlink():
            link.unlink()
        elif link.exists():
            raise RuntimeError("Expected a toolchain symlink: " + str(link))
        link.symlink_to(os.path.relpath(target, link.parent))
    print("Ready: " + entry["name"] + " " + entry["version"], flush=True)


def main():
    if platform.system() != "Darwin" or platform.machine() != "x86_64":
        raise SystemExit("This bootstrap targets the current Intel Mac. See README.md for prerequisites on other hosts.")
    directory = Path(__file__).resolve().parent
    runtime = directory.parents[1] / ".runtime"
    manifest = json.loads((directory / "toolchains.lock.json").read_text())
    for name in ("bin", "toolchains", "logs", "docker/cli-plugins", "colima", "colima-cache", "lima"):
        (runtime / name).mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=4) as pool:
        futures = [pool.submit(install, entry, runtime) for entry in manifest["tools"]]
        for future in futures:
            future.result()
    print("Next: bash backend/qingzhui/dev.sh containers-start", flush=True)


if __name__ == "__main__":
    main()
