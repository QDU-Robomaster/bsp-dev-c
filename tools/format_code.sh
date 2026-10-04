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
  In a git checkout under Modules/ (such as Modules/<owner>/<Repo>/ checked out
  by xrobot setup), only the C/C++ files that are modified, staged or untracked
  are formatted, so a clean checkout stays clean. C/C++ files under Modules/
  outside any git checkout are all formatted. When there is nothing to format,
  the script prints nothing and exits with 0.
  Requires clang-format version 21.1.8 by default.

Options:
  --check   Run clang-format in dry-run mode with --Werror on the same files.
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

is_source_file() {
  case "$1" in
    *.c|*.cc|*.cpp|*.cxx|*.h|*.hh|*.hpp|*.hxx)
      return 0
      ;;
  esac
  return 1
}

# A directory with .git is a checkout; elsewhere every C/C++ file is a target.
scan_modules_dir() {
  local dir="$1"
  local entry

  if [[ -e "${dir}/.git" ]]; then
    CHECKOUTS+=("${dir}")
    return 0
  fi

  for entry in "${dir}"/* "${dir}"/.[!.]* "${dir}"/..?*; do
    if [[ -L "${entry}" || ! -e "${entry}" ]]; then
      continue
    elif [[ -d "${entry}" ]]; then
      scan_modules_dir "${entry}"
    elif [[ -f "${entry}" ]] && is_source_file "${entry}"; then
      TARGET_FILES+=("${entry}")
    fi
  done
}

# Adds the C/C++ files that are modified, staged or untracked in a checkout. A nested
# repository that git reports as changed is queued as a checkout of its own.
collect_checkout_changes() {
  local checkout="$1"
  local entry status path

  if [[ -z "${STATUS_FILE}" ]]; then
    STATUS_FILE="$(mktemp)"
  fi

  if ! git --no-optional-locks -C "${checkout}" status --porcelain -z --untracked-files=all >"${STATUS_FILE}"; then
    echo "Failed to read the git status of ${checkout}." >&2
    exit 1
  fi

  while IFS= read -r -d '' entry; do
    status="${entry:0:2}"
    path="${checkout}/${entry:3}"
    path="${path%/}"

    case "${status}" in
      *R*|*C*)
        # A rename or copy is followed by its original path.
        IFS= read -r -d '' _ || true
        ;;
      "D ")
        # Removed from the index only; a file still on disk is also reported as untracked.
        continue
        ;;
    esac

    if [[ -L "${path}" ]]; then
      continue
    elif [[ -d "${path}" && -e "${path}/.git" ]]; then
      CHECKOUTS+=("${path}")
    elif [[ -f "${path}" ]] && is_source_file "${path}"; then
      TARGET_FILES+=("${path}")
    fi
  done <"${STATUS_FILE}"
}

collect_target_files() {
  local index=0

  if [[ ! -d "Modules" ]]; then
    return 0
  fi

  scan_modules_dir "Modules"

  while (( index < ${#CHECKOUTS[@]} )); do
    collect_checkout_changes "${CHECKOUTS[index]}"
    index=$((index + 1))
  done
}

cleanup() {
  if [[ -n "${STATUS_FILE}" ]]; then
    rm -f "${STATUS_FILE}"
  fi
}

CHECKOUTS=()
TARGET_FILES=()
STATUS_FILE=""
trap cleanup EXIT

collect_target_files

if [[ "${#TARGET_FILES[@]}" -eq 0 ]]; then
  exit 0
fi

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

# Runs clang-format in batches that keep each command line short; every batch runs and
# the last failure status is returned.
run_clang_format() {
  local batch_size=100
  local start=0
  local result=0

  while (( start < ${#TARGET_FILES[@]} )); do
    if [[ "${MODE}" == "check" ]]; then
      "${CLANG_FORMAT_BIN}" --dry-run --Werror --style=file "${TARGET_FILES[@]:start:batch_size}" || result=$?
    else
      "${CLANG_FORMAT_BIN}" -i --style=file "${TARGET_FILES[@]:start:batch_size}" || result=$?
    fi
    start=$((start + batch_size))
  done

  return "${result}"
}

run_clang_format

FILE_COUNT="${#TARGET_FILES[@]} C/C++ file"
if [[ "${#TARGET_FILES[@]}" -ne 1 ]]; then
  FILE_COUNT+="s"
fi

if [[ "${MODE}" == "check" ]]; then
  echo "clang-format check passed for ${FILE_COUNT} under Modules/."
else
  echo "Formatted ${FILE_COUNT} under Modules/."
fi
