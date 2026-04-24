#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

usage() {
  cat <<'EOF'
Usage:
  tools/format_code.sh [--check]

Description:
  Format C/C++ files under Modules/ using clang-format.
  Requires clang-format version 21.1.8 by default.

Options:
  --check   Run clang-format in dry-run mode with --Werror.
  -h, --help
EOF
}

MODE="format"
REQUIRED_VERSION="${CLANG_FORMAT_REQUIRED_VERSION:-21.1.8}"
case "${1:-}" in
  "")
    ;;
  --check)
    MODE="check"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown option: ${1}" >&2
    usage >&2
    exit 2
    ;;
esac

detect_host_platform() {
  case "$(uname -s)" in
    Linux)
      printf '%s\n' "linux"
      ;;
    Darwin)
      printf '%s\n' "darwin"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      printf '%s\n' "win32"
      ;;
    *)
      printf '%s\n' "unknown"
      ;;
  esac
}

detect_host_arch() {
  case "$(uname -m)" in
    x86_64|amd64)
      printf '%s\n' "x86_64"
      ;;
    arm64|aarch64)
      printf '%s\n' "arm64"
      ;;
    *)
      printf '%s\n' "$(uname -m)"
      ;;
  esac
}

HOST_PLATFORM="$(detect_host_platform)"
HOST_ARCH="$(detect_host_arch)"
CLANG_FORMAT_CACHE_DIR="${REPO_ROOT}/.cache/clang-format"
CLANG_FORMAT_TOOL_ROOT="${CLANG_FORMAT_CACHE_DIR}/llvm-${REQUIRED_VERSION}-${HOST_PLATFORM}-${HOST_ARCH}"

find_existing_clang_format() {
  local candidate

  for candidate in \
    "${CLANG_FORMAT_TOOL_ROOT}/bin/clang-format" \
    "${CLANG_FORMAT_TOOL_ROOT}/bin/clang-format.exe" \
    "${REPO_ROOT}/.venv-clang-format/bin/clang-format" \
    "${REPO_ROOT}/.venv-clang-format/Scripts/clang-format.exe" \
    "${REPO_ROOT}/../.venv-clang-format/bin/clang-format" \
    "${REPO_ROOT}/../.venv-clang-format/Scripts/clang-format.exe"; do
    if [[ -x "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  if command -v clang-format.exe >/dev/null 2>&1; then
    command -v clang-format.exe
    return 0
  fi

  if command -v clang-format >/dev/null 2>&1; then
    command -v clang-format
    return 0
  fi

  return 1
}

extract_clang_format_version() {
  local version_output

  version_output="$("$1" --version 2>/dev/null || true)"
  printf '%s\n' "${version_output}" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true
}

find_python_for_tools() {
  if [[ "${HOST_PLATFORM}" == "win32" ]] && command -v py >/dev/null 2>&1 && py -3 --version >/dev/null 2>&1; then
    PYTHON_FOR_TOOLS=(py -3)
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    PYTHON_FOR_TOOLS=(python3)
    return 0
  fi

  if command -v python >/dev/null 2>&1; then
    PYTHON_FOR_TOOLS=(python)
    return 0
  fi

  if [[ "${HOST_PLATFORM}" == "win32" ]] && command -v py >/dev/null 2>&1; then
    PYTHON_FOR_TOOLS=(py)
    return 0
  fi

  return 1
}

llvm_asset_pattern() {
  case "${HOST_PLATFORM}:${HOST_ARCH}" in
    win32:x86_64)
      printf '^clang\\+llvm-%s-x86_64-pc-windows-msvc\\.tar\\.xz$' "${REQUIRED_VERSION}"
      ;;
    win32:arm64)
      printf '^clang\\+llvm-%s-aarch64-pc-windows-msvc\\.tar\\.xz$' "${REQUIRED_VERSION}"
      ;;
    linux:x86_64)
      printf '^LLVM-%s-Linux-X64\\.tar\\.xz$' "${REQUIRED_VERSION}"
      ;;
    linux:arm64)
      printf '^LLVM-%s-Linux-ARM64\\.tar\\.xz$' "${REQUIRED_VERSION}"
      ;;
    darwin:arm64)
      printf '^LLVM-%s-macOS-ARM64\\.tar\\.xz$' "${REQUIRED_VERSION}"
      ;;
    darwin:x86_64)
      printf '^LLVM-%s-macOS-X64\\.tar\\.xz$|^clang\\+llvm-%s-x86_64-apple-darwin.*\\.tar\\.xz$' "${REQUIRED_VERSION}" "${REQUIRED_VERSION}"
      ;;
    *)
      return 1
      ;;
  esac
}

install_official_clang_format() {
  local asset_pattern archive_path
  local archive_entry
  local archive_entries=()

  if ! find_python_for_tools; then
    echo "Python not found. Install Python 3 or set CLANG_FORMAT_BIN manually." >&2
    exit 1
  fi

  asset_pattern="$(llvm_asset_pattern)" || {
    echo "No official LLVM clang-format package mapping for ${HOST_PLATFORM}/${HOST_ARCH}." >&2
    exit 1
  }

  archive_path="${CLANG_FORMAT_CACHE_DIR}/clang-format-${REQUIRED_VERSION}-${HOST_PLATFORM}-${HOST_ARCH}.tar.xz"
  mkdir -p "${CLANG_FORMAT_CACHE_DIR}"

  if [[ ! -f "${archive_path}" ]]; then
    echo "Downloading official LLVM clang-format ${REQUIRED_VERSION} for ${HOST_PLATFORM}/${HOST_ARCH}..."
    "${PYTHON_FOR_TOOLS[@]}" - "${REQUIRED_VERSION}" "${asset_pattern}" "${archive_path}" <<'PY'
import json
import re
import sys
import urllib.request

version, pattern, archive_path = sys.argv[1:4]
api_url = f"https://api.github.com/repos/llvm/llvm-project/releases/tags/llvmorg-{version}"

with urllib.request.urlopen(api_url) as response:
    release = json.load(response)

asset = next(
    (candidate for candidate in release.get("assets", []) if re.fullmatch(pattern, candidate["name"])),
    None,
)

if asset is None:
    raise SystemExit(f"No LLVM clang-format archive matches pattern: {pattern}")

urllib.request.urlretrieve(asset["browser_download_url"], archive_path)
print(f"Downloaded {asset['name']}")
PY
  fi

  rm -rf "${CLANG_FORMAT_TOOL_ROOT}"
  mkdir -p "${CLANG_FORMAT_TOOL_ROOT}"

  if [[ "${HOST_PLATFORM}" == "win32" ]]; then
    while IFS= read -r archive_entry; do
      archive_entries+=("${archive_entry}")
    done < <(tar -tf "${archive_path}" | grep -E '(^|/)bin/(clang-format\.exe|.*\.dll)$')
  elif [[ "${HOST_PLATFORM}" == "darwin" ]]; then
    while IFS= read -r archive_entry; do
      archive_entries+=("${archive_entry}")
    done < <(tar -tf "${archive_path}" | grep -E '(^|/)bin/clang-format$|(^|/)(bin|lib)/.*\.dylib$')
  else
    while IFS= read -r archive_entry; do
      archive_entries+=("${archive_entry}")
    done < <(tar -tf "${archive_path}" | grep -E '(^|/)bin/clang-format$|(^|/)(bin|lib)/.*\.so(\..*)?$')
  fi

  if [[ "${#archive_entries[@]}" -eq 0 ]]; then
    echo "Failed to locate clang-format files inside ${archive_path}." >&2
    exit 1
  fi

  tar -xf "${archive_path}" -C "${CLANG_FORMAT_TOOL_ROOT}" --strip-components=1 "${archive_entries[@]}"
  rm -f "${archive_path}"

  if [[ "${HOST_PLATFORM}" == "win32" ]]; then
    CLANG_FORMAT_BIN="${CLANG_FORMAT_TOOL_ROOT}/bin/clang-format.exe"
  else
    CLANG_FORMAT_BIN="${CLANG_FORMAT_TOOL_ROOT}/bin/clang-format"
  fi
}

install_local_clang_format_venv() {
  local venv_python

  if ! find_python_for_tools; then
    echo "Python not found. Install Python 3 or set CLANG_FORMAT_BIN manually." >&2
    exit 1
  fi

  echo "Preparing local clang-format ${REQUIRED_VERSION} in ${REPO_ROOT}/.venv-clang-format..."

  if [[ ! -d "${REPO_ROOT}/.venv-clang-format" ]]; then
    "${PYTHON_FOR_TOOLS[@]}" -m venv "${REPO_ROOT}/.venv-clang-format"
  fi

  if [[ -x "${REPO_ROOT}/.venv-clang-format/bin/python" ]]; then
    venv_python="${REPO_ROOT}/.venv-clang-format/bin/python"
    CLANG_FORMAT_BIN="${REPO_ROOT}/.venv-clang-format/bin/clang-format"
  elif [[ -x "${REPO_ROOT}/.venv-clang-format/Scripts/python.exe" ]]; then
    venv_python="${REPO_ROOT}/.venv-clang-format/Scripts/python.exe"
    CLANG_FORMAT_BIN="${REPO_ROOT}/.venv-clang-format/Scripts/clang-format.exe"
  else
    echo "Failed to create Python venv at ${REPO_ROOT}/.venv-clang-format." >&2
    exit 1
  fi

  "${venv_python}" -m pip install --upgrade pip
  "${venv_python}" -m pip install "clang-format==${REQUIRED_VERSION}"
}

provision_clang_format() {
  local resolved_version

  if [[ "${HOST_PLATFORM}" != "win32" ]]; then
    install_local_clang_format_venv
    resolved_version="$(extract_clang_format_version "${CLANG_FORMAT_BIN}")"
    if [[ "${resolved_version}" == "${REQUIRED_VERSION}" ]]; then
      return 0
    fi
  fi

  install_official_clang_format
}

PYTHON_FOR_TOOLS=()
CLANG_FORMAT_BIN="${CLANG_FORMAT_BIN:-}"

if [[ -z "${CLANG_FORMAT_BIN}" ]]; then
  CLANG_FORMAT_BIN="$(find_existing_clang_format || true)"
fi

CF_VERSION=""
if [[ -n "${CLANG_FORMAT_BIN}" ]]; then
  CF_VERSION="$(extract_clang_format_version "${CLANG_FORMAT_BIN}")"
fi

if [[ -z "${CLANG_FORMAT_BIN}" || "${CF_VERSION}" != "${REQUIRED_VERSION}" ]]; then
  provision_clang_format
  CF_VERSION="$(extract_clang_format_version "${CLANG_FORMAT_BIN}")"
fi

if [[ -z "${CF_VERSION}" ]]; then
  echo "Failed to parse clang-format version from ${CLANG_FORMAT_BIN}." >&2
  exit 1
fi

if [[ "${CF_VERSION}" != "${REQUIRED_VERSION}" ]]; then
  echo "Failed to provision clang-format ${REQUIRED_VERSION}; found ${CF_VERSION} at ${CLANG_FORMAT_BIN}." >&2
  exit 1
fi

run_clang_format() {
  if [[ ! -d "Modules" ]]; then
    return 0
  fi

  if [[ "${MODE}" == "check" ]]; then
    find "Modules" -type f \( \
      -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.cxx' \
      -o -name '*.h' -o -name '*.hh' -o -name '*.hpp' -o -name '*.hxx' \
    \) -exec "${CLANG_FORMAT_BIN}" --dry-run --Werror --style=file {} +
  else
    find "Modules" -type f \( \
      -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.cxx' \
      -o -name '*.h' -o -name '*.hh' -o -name '*.hpp' -o -name '*.hxx' \
    \) -exec "${CLANG_FORMAT_BIN}" -i --style=file {} +
  fi
}

run_clang_format

if [[ "${MODE}" == "check" ]]; then
  echo "clang-format check passed for Modules/."
else
  echo "Formatted C/C++ files under Modules/."
fi
