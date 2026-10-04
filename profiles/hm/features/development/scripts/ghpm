#!/usr/bin/env python3
"""A single-file package manager for programs published in GitHub Releases."""

from __future__ import annotations

import argparse
import contextlib
import datetime as dt
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Iterable, Iterator, Mapping, Sequence
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any

import tomllib

try:
    import fcntl
except ImportError:  # pragma: no cover - Windows has no fcntl.
    fcntl = None


class GhpmError(Exception):
    """Base class for expected errors."""


class ConfigError(GhpmError):
    """An invalid package or manifest definition."""


class StateError(GhpmError):
    """A missing or corrupt local state file."""


class ReleaseError(GhpmError):
    """A GitHub API or download failure."""


class AssetError(GhpmError):
    """No unambiguous release asset was found."""


class ChecksumError(GhpmError):
    """A downloaded asset failed SHA-256 verification."""


def _string(value: Any, field_name: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ConfigError(f"{field_name} must be a non-empty string")
    return value.strip()


def _package_name(value: Any) -> str:
    value = _string(value, "package name")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._+-]*", value):
        raise ConfigError(f"invalid package name: {value!r}")
    return value


def _repo(value: Any) -> str:
    value = _string(value, "repo")
    if not re.fullmatch(r"[^/\\\s]+/[^/\\\s]+", value):
        raise ConfigError(f"repo must have the form owner/name: {value!r}")
    return value


@dataclass(frozen=True)
class PackageSpec:
    """Declarative description of one script-driven GitHub Release package."""

    name: str
    repo: str
    asset_pattern: str
    install_script: str
    uninstall_script: str
    version: str = "latest"
    checksum_asset_pattern: str | None = None
    checksum_required: bool = False

    def __post_init__(self) -> None:
        name = _package_name(self.name)
        object.__setattr__(self, "name", name)
        object.__setattr__(self, "repo", _repo(self.repo))
        object.__setattr__(
            self, "asset_pattern", _string(self.asset_pattern, "asset_pattern")
        )
        object.__setattr__(
            self, "install_script", _string(self.install_script, "install_script")
        )
        object.__setattr__(
            self, "uninstall_script", _string(self.uninstall_script, "uninstall_script")
        )
        object.__setattr__(self, "version", _string(self.version, "version"))
        if self.checksum_asset_pattern is not None:
            object.__setattr__(
                self,
                "checksum_asset_pattern",
                _string(self.checksum_asset_pattern, "checksum.asset_pattern"),
            )
        if not isinstance(self.checksum_required, bool):
            raise ConfigError("checksum.required must be boolean")
        if self.checksum_required and self.checksum_asset_pattern is None:
            raise ConfigError("checksum.required requires checksum.asset_pattern")

    @classmethod
    def from_dict(
        cls, value: Mapping[str, Any], name: str | None = None
    ) -> PackageSpec:
        if not isinstance(value, Mapping):
            raise ConfigError("each package must be an object")
        package_name = name or value.get("name")
        if package_name is None:
            raise ConfigError("package is missing name")
        if name is not None and "name" in value and value["name"] != name:
            raise ConfigError(
                f"package name {value['name']!r} does not match table name {name!r}"
            )
        allowed = {
            "name",
            "repo",
            "asset_pattern",
            "install_script",
            "uninstall_script",
            "version",
            "checksum",
        }
        unknown = sorted(set(value) - allowed)
        if unknown:
            raise ConfigError(
                f"unknown fields for package {package_name!r}: {', '.join(unknown)}"
            )
        checksum = value.get("checksum", {})
        if checksum is None:
            checksum = {}
        if not isinstance(checksum, Mapping):
            raise ConfigError("checksum must be a TOML table")
        unknown_checksum = sorted(set(checksum) - {"asset_pattern", "required"})
        if unknown_checksum:
            raise ConfigError("unknown checksum fields: " + ", ".join(unknown_checksum))
        return cls(
            name=str(package_name),
            repo=value.get("repo"),
            asset_pattern=value.get("asset_pattern"),
            install_script=value.get("install_script"),
            uninstall_script=value.get("uninstall_script"),
            version=value.get("version", "latest"),
            checksum_asset_pattern=checksum.get("asset_pattern"),
            checksum_required=checksum.get("required", False),
        )

    def with_version(self, version: str) -> PackageSpec:
        return replace(self, version=_string(version, "version"))

    def to_dict(self) -> dict[str, Any]:
        result: dict[str, Any] = {
            "name": self.name,
            "repo": self.repo,
            "asset_pattern": self.asset_pattern,
            "install_script": self.install_script,
            "uninstall_script": self.uninstall_script,
            "version": self.version,
        }
        checksum: dict[str, Any] = {}
        if self.checksum_asset_pattern:
            checksum["asset_pattern"] = self.checksum_asset_pattern
        if self.checksum_required:
            checksum["required"] = True
        if checksum:
            result["checksum"] = checksum
        return result


@dataclass(frozen=True)
class Manifest:
    packages: Mapping[str, PackageSpec]
    bin_dir: Path | None = None

    @classmethod
    def load(cls, path: str | os.PathLike[str]) -> Manifest:
        manifest_path = Path(os.path.expandvars(os.path.expanduser(os.fspath(path))))
        try:
            with manifest_path.open("rb") as stream:
                document = tomllib.load(stream)
        except FileNotFoundError as exc:
            raise ConfigError(f"manifest not found: {manifest_path}") from exc
        except tomllib.TOMLDecodeError as exc:
            raise ConfigError(
                f"invalid TOML in manifest {manifest_path}: {exc}"
            ) from exc
        except OSError as exc:
            raise ConfigError(
                f"could not read manifest {manifest_path}: {exc}"
            ) from exc
        if not isinstance(document, Mapping):
            raise ConfigError("manifest root must be an object")
        unknown = sorted(set(document) - {"version", "bin_dir", "packages"})
        if unknown:
            raise ConfigError("unknown manifest fields: " + ", ".join(unknown))
        if "version" not in document:
            raise ConfigError("manifest is missing required field: version")
        manifest_version = document["version"]
        if isinstance(manifest_version, bool) or manifest_version != 1:
            raise ConfigError("unsupported manifest version; expected 1")
        raw_packages = document.get("packages", {})
        if not isinstance(raw_packages, Mapping):
            raise ConfigError(
                "manifest packages must be a TOML table keyed by package name"
            )
        items = ((str(key), value) for key, value in raw_packages.items())
        packages: dict[str, PackageSpec] = {}
        for key, value in items:
            spec = PackageSpec.from_dict(value, name=key)
            if spec.name in packages:
                raise ConfigError(f"duplicate package name: {spec.name}")
            packages[spec.name] = spec
        bin_dir = document.get("bin_dir")
        if bin_dir is not None:
            bin_dir = Path(
                os.path.expandvars(os.path.expanduser(_string(bin_dir, "bin_dir")))
            )
        return cls(packages=packages, bin_dir=bin_dir)

    def get(self, name: str) -> PackageSpec | None:
        return self.packages.get(name)


@dataclass(frozen=True)
class Host:
    os: str
    arch: str

    def __post_init__(self) -> None:
        operating_system = _string(self.os, "host OS").lower()
        architecture = _string(self.arch, "host architecture").lower()
        if operating_system not in {"darwin", "linux"}:
            raise ConfigError(
                f"unsupported host OS {operating_system!r}; supported targets are darwin-aarch64 and linux-amd64"
            )
        architecture = {
            "amd64": "amd64",
            "x86_64": "amd64",
            "x64": "amd64",
            "aarch64": "aarch64",
            "arm64": "aarch64",
            "armv8l": "aarch64",
        }.get(architecture, architecture)
        expected = "aarch64" if operating_system == "darwin" else "amd64"
        if architecture != expected:
            raise ConfigError(
                f"unsupported host target {operating_system}-{architecture}; "
                "supported targets are darwin-aarch64 and linux-amd64"
            )
        object.__setattr__(self, "os", operating_system)
        object.__setattr__(self, "arch", architecture)

    @classmethod
    def current(cls) -> Host:
        system = sys.platform.lower()
        if system.startswith("linux"):
            operating_system = "linux"
        elif system == "darwin":
            operating_system = "darwin"
        else:
            raise ConfigError(
                f"unsupported host OS {system!r}; supported targets are darwin-aarch64 and linux-amd64"
            )
        machine = platform.machine().lower()
        arch = {
            "amd64": "amd64",
            "x64": "amd64",
            "x86_64": "amd64",
            "arm64": "aarch64",
            "aarch64": "aarch64",
            "armv8l": "aarch64",
        }.get(machine, machine)
        return cls(operating_system, arch)

    def os_aliases(self) -> tuple[str, ...]:
        return {
            "darwin": ("darwin", "macos", "mac", "osx"),
            "linux": ("linux",),
        }.get(self.os, (self.os,))

    def arch_aliases(self) -> tuple[str, ...]:
        return {
            "amd64": ("amd64", "x86_64", "x64"),
            "aarch64": ("aarch64", "arm64", "armv8", "armv8l"),
        }.get(self.arch, (self.arch,))


@dataclass(frozen=True)
class ReleaseAsset:
    name: str
    url: str
    size: int | None = None
    digest: str | None = None


@dataclass(frozen=True)
class Release:
    repo: str
    tag: str
    title: str
    assets: tuple[ReleaseAsset, ...]

    @classmethod
    def from_dict(cls, repo: str, value: Mapping[str, Any]) -> Release:
        tag = _string(value.get("tag_name"), "release.tag_name")
        raw_assets = value.get("assets", [])
        if not isinstance(raw_assets, Sequence) or isinstance(
            raw_assets, (str, bytes, bytearray)
        ):
            raise ReleaseError("GitHub release assets are not an array")
        assets = []
        for raw in raw_assets:
            if not isinstance(raw, Mapping):
                continue
            name = raw.get("name")
            url = raw.get("browser_download_url") or raw.get("url")
            if not isinstance(name, str) or not isinstance(url, str):
                continue
            assets.append(
                ReleaseAsset(
                    name=name,
                    url=url,
                    size=raw.get("size") if isinstance(raw.get("size"), int) else None,
                    digest=raw.get("digest")
                    if isinstance(raw.get("digest"), str)
                    else None,
                )
            )
        return cls(repo, tag, str(value.get("name") or tag), tuple(assets))


class GitHubClient:
    """Minimal GitHub Releases client with an injectable API base URL."""

    def __init__(
        self,
        api_url: str = "https://api.github.com",
        token: str | None = None,
        timeout: float = 30.0,
        user_agent: str = "ghpm/1.0",
    ) -> None:
        self.api_url = _string(api_url, "api_url").rstrip("/")
        self.token = (
            token or os.environ.get("GHPM_TOKEN") or os.environ.get("GITHUB_TOKEN")
        )
        self.timeout = timeout
        self.user_agent = user_agent

    def _request(self, url: str, accept: str):
        headers = {"Accept": accept, "User-Agent": self.user_agent}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        try:
            return urllib.request.urlopen(
                urllib.request.Request(url, headers=headers), timeout=self.timeout
            )
        except urllib.error.HTTPError as exc:
            try:
                detail = exc.read(500).decode("utf-8", errors="replace").strip()
            except OSError:
                detail = ""
            suffix = f": {detail}" if detail else ""
            raise ReleaseError(
                f"request failed ({exc.code}) for {url}{suffix}"
            ) from exc
        except urllib.error.URLError as exc:
            raise ReleaseError(f"could not reach {url}: {exc.reason}") from exc
        except TimeoutError as exc:
            raise ReleaseError(f"request timed out: {url}") from exc

    def release(self, repo: str, version: str = "latest") -> Release:
        repo = _repo(repo)
        version = _string(version, "version")
        encoded_repo = urllib.parse.quote(repo, safe="/")
        if version.lower() == "latest":
            path = f"repos/{encoded_repo}/releases/latest"
        else:
            path = f"repos/{encoded_repo}/releases/tags/{urllib.parse.quote(version, safe='')}"
        endpoint = f"{self.api_url}/{path}"
        with self._request(endpoint, "application/vnd.github+json") as response:
            try:
                document = json.load(response)
            except json.JSONDecodeError as exc:
                raise ReleaseError(
                    f"invalid JSON returned for {repo}@{version}"
                ) from exc
        if not isinstance(document, Mapping):
            raise ReleaseError(f"invalid release returned for {repo}@{version}")
        return Release.from_dict(repo, document)

    def download(self, asset: ReleaseAsset, destination: Path) -> None:
        if urllib.parse.urlparse(asset.url).scheme not in {"http", "https"}:
            raise ReleaseError(f"unsupported asset URL: {asset.url}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        partial = destination.with_name(f".{destination.name}.part")
        try:
            with (
                self._request(asset.url, "application/octet-stream") as response,
                partial.open("wb") as output,
            ):
                shutil.copyfileobj(response, output, 1024 * 1024)
            if not partial.is_file() or partial.stat().st_size == 0:
                raise ReleaseError(f"downloaded asset is empty: {asset.name}")
            os.replace(partial, destination)
        except GhpmError:
            partial.unlink(missing_ok=True)
            raise
        except OSError as exc:
            partial.unlink(missing_ok=True)
            raise ReleaseError(f"could not save {asset.name}: {exc}") from exc


def _pattern_values(spec: PackageSpec, tag: str, host: Host) -> dict[str, str]:
    versions = [tag]
    if tag.lower().startswith("v"):
        versions.append(tag[1:])
    else:
        versions.append("v" + tag)
    return {
        "name": re.escape(spec.name),
        "tag": re.escape(tag),
        "version": "(?:"
        + "|".join(re.escape(v) for v in dict.fromkeys(versions))
        + ")",
        "os": "(?:" + "|".join(re.escape(v) for v in host.os_aliases()) + ")",
        "arch": "(?:" + "|".join(re.escape(v) for v in host.arch_aliases()) + ")",
    }


def expand_pattern(pattern: str, spec: PackageSpec, tag: str, host: Host) -> str:
    values = _pattern_values(spec, tag, host)

    def substitute(match: re.Match[str]) -> str:
        key = match.group(1)
        if key not in values:
            raise ConfigError(f"unknown asset pattern placeholder: {{{key}}}")
        return values[key]

    return re.sub(r"\{([A-Za-z][A-Za-z0-9_]*)\}", substitute, pattern)


def select_asset(
    release: Release, spec: PackageSpec, host: Host | None = None
) -> ReleaseAsset:
    """Select the one asset declared by the package's regex."""
    host = host or Host.current()
    if not release.assets:
        raise AssetError(f"release {release.repo}@{release.tag} has no assets")
    try:
        pattern = re.compile(
            expand_pattern(spec.asset_pattern, spec, release.tag, host),
            re.IGNORECASE,
        )
    except re.error as exc:
        raise ConfigError(f"invalid asset_pattern for {spec.name}: {exc}") from exc
    candidates = [asset for asset in release.assets if pattern.search(asset.name)]
    if len(candidates) != 1:
        available = ", ".join(asset.name for asset in release.assets) or "none"
        raise AssetError(
            f"asset_pattern for {spec.name}@{release.tag} matched "
            f"{len(candidates)} assets; expected exactly one; available: {available}"
        )
    return candidates[0]


def _file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _asset_digest(asset: ReleaseAsset) -> str | None:
    if not asset.digest:
        return None
    match = re.fullmatch(r"sha256:([0-9a-fA-F]{64})", asset.digest.strip())
    return match.group(1).lower() if match else None


def _checksum_text_value(text: str, asset_name: str) -> str | None:
    for line in text.splitlines():
        if asset_name in line:
            found = re.findall(r"(?i)(?<![0-9a-f])([0-9a-f]{64})(?![0-9a-f])", line)
            if found:
                return found[0].lower()
    found = re.findall(r"(?i)(?<![0-9a-f])([0-9a-f]{64})(?![0-9a-f])", text)
    return found[0].lower() if len(found) == 1 else None


def _path(value: str | os.PathLike[str] | None, default: Path) -> Path:
    if value is None:
        value = default
    return Path(os.path.expandvars(os.path.expanduser(os.fspath(value)))).absolute()


def default_bin_dir() -> Path:
    return _path(os.environ.get("GHPM_BIN_DIR"), Path.home() / ".local" / "bin")


def default_state_file() -> Path:
    root = os.environ.get("XDG_STATE_HOME")
    default = (
        Path(root) / "ghpm" / "state.json"
        if root
        else Path.home() / ".local" / "state" / "ghpm" / "state.json"
    )
    return _path(None, default)


@dataclass(frozen=True)
class InstallResult:
    name: str
    version: str
    asset: str
    changed: bool


@dataclass(frozen=True)
class RemoveResult:
    name: str
    changed: bool


class PackageManager:
    """Internal implementation for the declarative command-line interface."""

    def __init__(
        self,
        bin_dir: str | os.PathLike[str] | None = None,
        state_file: str | os.PathLike[str] | None = None,
        client: GitHubClient | None = None,
        host: Host | None = None,
    ) -> None:
        self.bin_dir = _path(bin_dir, default_bin_dir())
        self.state_file = _path(state_file, default_state_file())
        self.client = client or GitHubClient()
        self.host = host or Host.current()

    @contextlib.contextmanager
    def _lock(self) -> Iterator[None]:
        lock_path = self.state_file.with_name(self.state_file.name + ".lock")
        lock_path.parent.mkdir(parents=True, exist_ok=True)
        with lock_path.open("a+") as stream:
            if fcntl is not None:
                fcntl.flock(stream.fileno(), fcntl.LOCK_EX)
            try:
                yield
            finally:
                if fcntl is not None:
                    fcntl.flock(stream.fileno(), fcntl.LOCK_UN)

    def _new_state(self) -> dict[str, Any]:
        return {"version": 1, "bin_dir": str(self.bin_dir), "packages": {}}

    def _read_state(self) -> dict[str, Any]:
        if not self.state_file.exists():
            return self._new_state()
        try:
            with self.state_file.open("r", encoding="utf-8") as stream:
                state = json.load(stream)
        except (OSError, json.JSONDecodeError) as exc:
            raise StateError(
                f"could not read state file {self.state_file}: {exc}"
            ) from exc
        if not isinstance(state, Mapping) or state.get("version") != 1:
            raise StateError(f"unsupported state file: {self.state_file}")
        stored_bin_dir = state.get("bin_dir", str(self.bin_dir))
        if not isinstance(stored_bin_dir, str):
            raise StateError(f"invalid bin_dir in state file: {self.state_file}")
        if Path(stored_bin_dir).absolute() != self.bin_dir:
            raise StateError(
                f"state belongs to {stored_bin_dir}; current bin directory is {self.bin_dir}; "
                "use the matching --bin-dir or another --state-file"
            )
        if not isinstance(state.get("packages"), Mapping):
            raise StateError(f"invalid packages in state file: {self.state_file}")
        return {
            "version": 1,
            "bin_dir": str(self.bin_dir),
            "packages": dict(state["packages"]),
        }

    def _write_state(self, state: Mapping[str, Any]) -> None:
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        fd, temporary_name = tempfile.mkstemp(
            prefix=".ghpm-state-", dir=self.state_file.parent
        )
        temporary = Path(temporary_name)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as stream:
                json.dump(state, stream, indent=2, sort_keys=True)
                stream.write("\n")
                stream.flush()
                os.fsync(stream.fileno())
            os.chmod(temporary, 0o600)
            os.replace(temporary, self.state_file)
        except (OSError, TypeError, ValueError) as exc:
            temporary.unlink(missing_ok=True)
            raise StateError(
                f"could not write state file {self.state_file}: {exc}"
            ) from exc

    def installed(self) -> dict[str, dict[str, Any]]:
        with self._lock():
            return dict(self._read_state()["packages"])

    def installed_spec(self, name: str) -> PackageSpec | None:
        record = self.installed().get(name)
        raw = record.get("spec") if isinstance(record, Mapping) else None
        return PackageSpec.from_dict(raw) if isinstance(raw, Mapping) else None

    def _current(
        self,
        record: Mapping[str, Any] | None,
        spec: PackageSpec,
        release: Release,
        asset: ReleaseAsset,
    ) -> bool:
        if (
            not record
            or record.get("resolved_version") != release.tag
            or record.get("asset") != asset.name
        ):
            return False
        if record.get("spec") != spec.to_dict():
            return False
        return record.get("script_installed") is True

    def _verify(
        self,
        downloaded: Path,
        release: Release,
        asset: ReleaseAsset,
        spec: PackageSpec,
        temporary_dir: Path,
    ) -> None:
        digest = _asset_digest(asset)
        expected = digest
        if spec.checksum_asset_pattern:
            try:
                pattern = re.compile(
                    expand_pattern(
                        spec.checksum_asset_pattern, spec, release.tag, self.host
                    ),
                    re.IGNORECASE,
                )
            except re.error as exc:
                raise ConfigError(
                    f"invalid checksum.asset_pattern for {spec.name}: {exc}"
                ) from exc
            candidates = [
                item
                for item in release.assets
                if item.name != asset.name and pattern.search(item.name)
            ]
            if len(candidates) > 1:
                raise ChecksumError(
                    f"checksum pattern matched {len(candidates)} assets; expected one"
                )
            if not candidates:
                if spec.checksum_required:
                    raise ChecksumError(
                        f"checksum pattern matched no asset for {asset.name}"
                    )
            else:
                checksum_path = temporary_dir / Path(candidates[0].name).name
                self.client.download(candidates[0], checksum_path)
                found = _checksum_text_value(
                    checksum_path.read_text(encoding="utf-8", errors="replace"),
                    asset.name,
                )
                if found is None and spec.checksum_required:
                    raise ChecksumError(
                        f"checksum asset {candidates[0].name} has no SHA-256 hash "
                        f"for {asset.name}"
                    )
                if found is not None:
                    if expected and expected != found:
                        raise ChecksumError(
                            f"checksum sources disagree for {asset.name}"
                        )
                    expected = found
        if expected is None:
            if spec.checksum_required:
                raise ChecksumError(
                    f"no SHA-256 checksum is available for {asset.name}"
                )
            return
        actual = _file_sha256(downloaded)
        if actual != expected:
            raise ChecksumError(
                f"SHA-256 mismatch for {asset.name}: expected {expected}, got {actual}"
            )

    def _run_script(
        self,
        script: str,
        *,
        phase: str,
        asset: Path | None,
        work_dir: Path,
        version: str,
        spec: PackageSpec,
    ) -> None:
        environment = os.environ.copy()
        environment.update(
            {
                "GHPM_ASSET": str(asset) if asset is not None else "",
                "GHPM_OUTPUT_DIR": str(self.bin_dir),
                "GHPM_VERSION": version,
                "GHPM_OS": self.host.os,
                "GHPM_ARCH": self.host.arch,
                "GHPM_PACKAGE": spec.name,
                "GHPM_REPO": spec.repo,
                "GHPM_WORK_DIR": str(work_dir),
            }
        )
        try:
            result = subprocess.run(
                ["bash", "-e", "-u", "-o", "pipefail", "-c", script, f"ghpm-{phase}"],
                cwd=work_dir,
                env=environment,
                check=False,
            )
        except FileNotFoundError as exc:
            raise GhpmError("bash is required to run package scripts") from exc
        except OSError as exc:
            raise GhpmError(f"could not start {phase} script: {exc}") from exc
        if result.returncode != 0:
            raise GhpmError(
                f"{phase} script for {spec.name} failed with exit code {result.returncode}"
            )

    def install(
        self,
        spec: PackageSpec | Mapping[str, Any],
        *,
        force: bool = False,
        dry_run: bool = False,
    ) -> InstallResult:
        """Install or upgrade one package."""
        if not isinstance(spec, PackageSpec):
            spec = PackageSpec.from_dict(spec)
        with self._lock():
            state = self._read_state()
            old = state["packages"].get(spec.name)
            release = self.client.release(spec.repo, spec.version)
            asset = select_asset(release, spec, self.host)
            if self._current(old, spec, release, asset) and not force:
                return InstallResult(spec.name, release.tag, asset.name, False)
            if dry_run:
                return InstallResult(spec.name, release.tag, asset.name, True)
            if self.bin_dir.exists() and not self.bin_dir.is_dir():
                raise GhpmError(f"installation path is not a directory: {self.bin_dir}")
            with tempfile.TemporaryDirectory(prefix="ghpm-") as temporary_name:
                temporary_dir = Path(temporary_name).resolve()
                downloaded = temporary_dir / Path(asset.name).name
                self.client.download(asset, downloaded)
                self._verify(downloaded, release, asset, spec, temporary_dir)
                self.bin_dir.parent.mkdir(parents=True, exist_ok=True)
                self.bin_dir.mkdir(parents=True, exist_ok=True)
                self._run_script(
                    spec.install_script,
                    phase="install",
                    asset=downloaded,
                    work_dir=temporary_dir,
                    version=release.tag,
                    spec=spec,
                )
                record = {
                    "name": spec.name,
                    "repo": spec.repo,
                    "spec": spec.to_dict(),
                    "resolved_version": release.tag,
                    "asset": asset.name,
                    "asset_digest": _asset_digest(asset),
                    "script_installed": True,
                    "installed_at": dt.datetime.now(dt.timezone.utc).isoformat(),
                }
                state["packages"][spec.name] = record
                self._write_state(state)
            return InstallResult(spec.name, release.tag, asset.name, True)

    def update(
        self,
        specs: Iterable[PackageSpec] | None = None,
        *,
        force: bool = False,
        dry_run: bool = False,
    ) -> list[InstallResult]:
        if specs is None:
            records = self.installed()
            resolved: list[PackageSpec] = []
            for name, record in records.items():
                if not isinstance(record, Mapping) or not isinstance(
                    record.get("spec"), Mapping
                ):
                    raise StateError(
                        f"installed record for {name} has no package specification"
                    )
                resolved.append(PackageSpec.from_dict(record["spec"]))
            specs = resolved
        return [self.install(spec, force=force, dry_run=dry_run) for spec in specs]

    def remove(self, name: str, *, dry_run: bool = False) -> RemoveResult:
        name = _package_name(name)
        with self._lock():
            state = self._read_state()
            record = state["packages"].get(name)
            if not isinstance(record, Mapping):
                raise GhpmError(f"package is not installed: {name}")
            raw_spec = record.get("spec")
            if not isinstance(raw_spec, Mapping):
                raise StateError(
                    f"installed record for {name} has no package specification"
                )
            spec = PackageSpec.from_dict(raw_spec)
            if dry_run:
                return RemoveResult(name, True)
            with tempfile.TemporaryDirectory(
                prefix=f"ghpm-{name}-uninstall-"
            ) as temporary_name:
                self._run_script(
                    spec.uninstall_script,
                    phase="uninstall",
                    asset=None,
                    work_dir=Path(temporary_name).resolve(),
                    version=str(record.get("resolved_version", spec.version)),
                    spec=spec,
                )
            del state["packages"][name]
            self._write_state(state)
            return RemoveResult(name, True)

    def inspect(
        self, spec: PackageSpec
    ) -> tuple[Release, ReleaseAsset, dict[str, Any] | None]:
        release = self.client.release(spec.repo, spec.version)
        asset = select_asset(release, spec, self.host)
        record = self.installed().get(spec.name)
        return release, asset, record if isinstance(record, dict) else None

    def sync(
        self,
        manifest: Manifest,
        *,
        prune: bool = False,
        force: bool = False,
        dry_run: bool = False,
    ) -> list[InstallResult | RemoveResult]:
        results: list[InstallResult | RemoveResult] = []
        for spec in manifest.packages.values():
            results.append(self.install(spec, force=force, dry_run=dry_run))
        if prune:
            for name in sorted(set(self.installed()) - set(manifest.packages)):
                results.append(self.remove(name, dry_run=dry_run))
        return results


def parse_package_ref(value: str) -> tuple[str, str | None]:
    value = _string(value, "package reference")
    if "@" not in value:
        return _package_name(value), None
    name, version = value.split("@", 1)
    return _package_name(name), _string(version, "package version")


MANIFEST_TEMPLATE = """# ghpm manifest
# See `ghpm --help` for the complete schema.

version = 1
bin_dir = "~/.local/bin"

# Example package:
#
# [packages."ripgrep"]
# repo = "BurntSushi/ripgrep"
# version = "latest"
# asset_pattern = '^ripgrep-{version}-{arch}.*(?:linux|darwin).*\\.tar\\.gz$'
#
# install_script = '''
# set -euo pipefail
# mkdir -p "$GHPM_OUTPUT_DIR"
# tar -xzf "$GHPM_ASSET" -C "$GHPM_WORK_DIR"
# install -m 0755 "$GHPM_WORK_DIR/rg" "$GHPM_OUTPUT_DIR/rg"
# '''
#
# uninstall_script = '''
# set -euo pipefail
# rm -f -- "$GHPM_OUTPUT_DIR/rg"
# '''
#
# [packages."ripgrep".checksum]
# asset_pattern = '^SHA256SUMS$'
# required = true
"""


MANIFEST_SCHEMA_HELP = r"""
Manifest TOML schema:

  version = 1                         required root integer
  bin_dir = "~/.local/bin"            optional root string

  [packages."NAME"]                  one table per package
  repo = "OWNER/REPOSITORY"           required GitHub repository
  version = "latest"                  optional; latest Release by default
  asset_pattern = 'REGEX'             required; must match exactly one asset
  install_script = '''...'''          required Bash script
  uninstall_script = '''...'''        required Bash script

  [packages."NAME".checksum]          optional SHA-256 checksum asset
  asset_pattern = 'REGEX'             checksum asset; at most one match
  required = true                     fail if the checksum asset/hash is missing

Package asset_pattern and checksum.asset_pattern support:
  {name}     package name
  {tag}      resolved Release tag
  {version}  resolved tag with or without a leading "v"
  {os}       current OS aliases (darwin or linux)
  {arch}     current architecture aliases (aarch64 or amd64)

The selected package asset is downloaded before install_script runs. The
scripts run with bash -e -u -o pipefail in a temporary working directory:
  GHPM_ASSET       downloaded package asset; empty during uninstall
  GHPM_OUTPUT_DIR  configured install directory
  GHPM_WORK_DIR    temporary working directory and current directory
  GHPM_VERSION     resolved Release tag
  GHPM_OS          darwin or linux
  GHPM_ARCH        aarch64 or amd64
  GHPM_PACKAGE     package name
  GHPM_REPO        GitHub repository

Checksum assets should contain a SHA-256 entry for the selected package asset,
such as "HASH  asset-name" or "SHA256 (asset-name) = HASH". A fixed digest is
not part of the manifest schema.
"""


def _default_manifest() -> Path:
    configured = os.environ.get("GHPM_MANIFEST")
    if configured:
        return _path(configured, Path.cwd() / "ghpm.toml")
    local = Path.cwd() / "ghpm.toml"
    if local.exists():
        return local.absolute()
    root = os.environ.get("XDG_CONFIG_HOME")
    return _path(
        None,
        Path(root) / "ghpm" / "manifest.toml"
        if root
        else Path.home() / ".config" / "ghpm" / "manifest.toml",
    )


def _default_init_manifest() -> Path:
    configured = os.environ.get("GHPM_MANIFEST")
    return _path(configured, Path.cwd() / "ghpm.toml")


def initialize_manifest(path: str | os.PathLike[str], *, force: bool = False) -> Path:
    target = _path(path, Path.cwd() / "ghpm.toml")
    if target.exists() and not force:
        raise GhpmError(
            f"manifest already exists: {target}; use --force to overwrite it"
        )
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(prefix=".ghpm-manifest-", dir=target.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(MANIFEST_TEMPLATE)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, target)
    except OSError as exc:
        temporary.unlink(missing_ok=True)
        raise GhpmError(f"could not create manifest {target}: {exc}") from exc
    return target


def _load_manifest(path: Path | None, required: bool = True) -> Manifest | None:
    path = path or _default_manifest()
    if not path.exists():
        if required:
            raise GhpmError(
                f"manifest not found: {path}; pass --manifest or create ghpm.toml"
            )
        return None
    return Manifest.load(path)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ghpm",
        description="Install and maintain binaries distributed through GitHub Releases.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=MANIFEST_SCHEMA_HELP,
    )
    parser.add_argument("--version", action="version", version="ghpm 1.0")
    parser.add_argument("--manifest", type=Path, help="manifest TOML path")
    parser.add_argument(
        "--bin-dir", type=Path, help="installation directory (default: ~/.local/bin)"
    )
    parser.add_argument("--state-file", type=Path, help="state JSON path")
    parser.add_argument(
        "--api-url", default="https://api.github.com", help=argparse.SUPPRESS
    )
    parser.add_argument(
        "--token", help="GitHub token; GHPM_TOKEN/GITHUB_TOKEN are also supported"
    )
    parser.add_argument("--timeout", type=float, default=30.0, help=argparse.SUPPRESS)
    parser.add_argument(
        "--force",
        action="store_true",
        help="force install scripts to run; overwrite an existing manifest with init",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="resolve changes without writing files"
    )
    commands = parser.add_subparsers(dest="command", required=True)
    init = commands.add_parser(
        "init",
        help="create a commented manifest template",
        description="Create a new manifest template.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    init.add_argument(
        "manifest_path",
        nargs="?",
        type=Path,
        metavar="PATH",
        help="manifest path (default: ./ghpm.toml)",
    )
    install = commands.add_parser(
        "install", help="install packages declared in the manifest"
    )
    install.add_argument("packages", nargs="+", metavar="PACKAGE[@VERSION]")
    update = commands.add_parser(
        "update", help="update selected or all installed packages"
    )
    update.add_argument("packages", nargs="*", metavar="PACKAGE[@VERSION]")
    remove = commands.add_parser(
        "remove", aliases=["uninstall"], help="remove installed packages"
    )
    remove.add_argument("packages", nargs="+", metavar="PACKAGE")
    commands.add_parser("list", aliases=["ls"], help="list installed packages")
    info = commands.add_parser(
        "info", help="show release and local package information"
    )
    info.add_argument("package", metavar="PACKAGE[@VERSION]")
    sync = commands.add_parser("sync", help="apply a declarative manifest")
    sync.add_argument(
        "manifest_path",
        nargs="?",
        type=Path,
        metavar="PATH",
        help="manifest path override",
    )
    sync.add_argument(
        "--prune",
        action="store_true",
        help="remove installed packages absent from manifest",
    )
    return parser


def _manager(
    args: argparse.Namespace, manifest: Manifest | None = None
) -> PackageManager:
    bin_dir = (
        args.bin_dir
        if args.bin_dir is not None
        else (manifest.bin_dir if manifest else None)
    )
    return PackageManager(
        bin_dir=bin_dir,
        state_file=args.state_file,
        client=GitHubClient(args.api_url, args.token, args.timeout),
    )


def _spec_for(
    manager: PackageManager,
    manifest: Manifest | None,
    reference: str,
    installed: bool = True,
) -> PackageSpec:
    name, version = parse_package_ref(reference)
    spec = manifest.get(name) if manifest else None
    if spec is None and installed:
        spec = manager.installed_spec(name)
    if spec is None:
        raise GhpmError(
            f"package {name!r} is not declared in the manifest and is not installed"
        )
    return spec.with_version(version) if version else spec


def _print_result(result: InstallResult) -> None:
    state = "already current" if not result.changed else "installed"
    print(f"{result.name}: {state} {result.version} ({result.asset})")


def _run(args: argparse.Namespace) -> int:
    if args.command == "init":
        if args.dry_run:
            raise GhpmError("--dry-run cannot be used with init")
        if args.manifest is not None and args.manifest_path is not None:
            raise GhpmError(
                "specify the manifest path either as init's argument or with --manifest"
            )
        target = args.manifest_path or args.manifest or _default_init_manifest()
        created = initialize_manifest(target, force=args.force)
        print(f"created manifest: {created}")
        return 0
    if args.command == "sync":
        manifest = _load_manifest(args.manifest_path or args.manifest)
        assert manifest is not None
        manager = _manager(args, manifest)
        for result in manager.sync(
            manifest, prune=args.prune, force=args.force, dry_run=args.dry_run
        ):
            if isinstance(result, InstallResult):
                _print_result(result)
            else:
                verb = "would remove" if args.dry_run else "removed"
                print(f"{verb}: {result.name}")
        return 0

    needs_manifest = args.command == "install" or (
        args.command == "update" and bool(args.packages)
    )
    manifest = _load_manifest(args.manifest, needs_manifest)
    manager = _manager(args, manifest)
    if args.command == "install":
        for reference in args.packages:
            _print_result(
                manager.install(
                    _spec_for(manager, manifest, reference, False),
                    force=args.force,
                    dry_run=args.dry_run,
                )
            )
        return 0
    if args.command == "update":
        specs = (
            [_spec_for(manager, manifest, reference) for reference in args.packages]
            if args.packages
            else None
        )
        for result in manager.update(specs, force=args.force, dry_run=args.dry_run):
            _print_result(result)
        return 0
    if args.command in {"remove", "uninstall"}:
        for name in args.packages:
            result = manager.remove(name, dry_run=args.dry_run)
            print(f"{'would remove' if args.dry_run else 'removed'} {result.name}")
        return 0
    if args.command in {"list", "ls"}:
        records = manager.installed()
        if not records:
            print("no packages installed")
        else:
            for name in sorted(records):
                record = records[name]
                print(
                    f"{name}\t{record.get('resolved_version', '?')}\t{record.get('repo', '?')}\t{record.get('asset', '?')}"
                )
        return 0
    if args.command == "info":
        spec = _spec_for(manager, manifest, args.package)
        release, asset, record = manager.inspect(spec)
        print(f"name: {spec.name}")
        print(f"repository: {spec.repo}")
        print(f"release: {release.tag}")
        print(f"asset: {asset.name}")
        print(
            f"installed: {record.get('resolved_version', '?')}"
            if record
            else "installed: no"
        )
        return 0
    raise GhpmError(f"unknown command: {args.command}")


def main(argv: list[str] | None = None) -> int:
    try:
        return _run(_parser().parse_args(argv))
    except GhpmError as exc:
        print(f"ghpm: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("ghpm: interrupted", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
