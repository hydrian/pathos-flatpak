#!/usr/bin/env python3
"""Build a portable tarball for the direct Wine installer."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import tarfile
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACKAGE_NAME = "PathosLinuxInstaller"
INPUTS = (
    (ROOT / "pathoslinux" / "install.sh", "install.sh"),
    (ROOT / "pathoslinux" / "README.md", "README.md"),
    (ROOT / "pathoslinux" / "assets" / "pathos.svg", "assets/pathos.svg"),
    (ROOT / "installer" / "Pathos-installer.exe", "payload/Pathos-installer.exe"),
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=ROOT / "pathoslinux" / "dist",
        help="where to write PathosLinuxInstaller.tar.gz",
    )
    args = parser.parse_args()
    output_dir = args.output_dir.expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    output_archive = output_dir / f"{PACKAGE_NAME}.tar.gz"

    missing = [str(source) for source, _ in INPUTS if not source.is_file()]
    if missing:
        parser.error("required package inputs are missing: " + ", ".join(missing))

    with tempfile.TemporaryDirectory(prefix="pathoslinux-package-") as temporary:
        stage = Path(temporary) / PACKAGE_NAME
        staged_files: list[Path] = []
        for source, relative in INPUTS:
            destination = stage / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(source.read_bytes())
            if relative == "install.sh":
                destination.chmod(0o755)
            staged_files.append(destination)

        checksums = "".join(
            f"{sha256(stage / relative)}  {relative}\n"
            for _, relative in INPUTS
        )
        checksum_file = stage / "SHA256SUMS"
        checksum_file.write_text(checksums, encoding="utf-8")
        staged_files.append(checksum_file)

        with output_archive.open("wb") as raw_archive:
            with gzip.GzipFile(filename="", mode="wb", fileobj=raw_archive, mtime=0) as compressed:
                with tarfile.open(fileobj=compressed, mode="w", format=tarfile.PAX_FORMAT) as archive:
                    for path in sorted(staged_files, key=lambda item: item.relative_to(stage).as_posix()):
                        relative = path.relative_to(stage).as_posix()
                        info = archive.gettarinfo(str(path), arcname=f"{PACKAGE_NAME}/{relative}")
                        info.uid = info.gid = 0
                        info.uname = info.gname = ""
                        info.mtime = 0
                        with path.open("rb") as source:
                            archive.addfile(info, source)

    print(f"Created {output_archive} ({output_archive.stat().st_size:,} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
