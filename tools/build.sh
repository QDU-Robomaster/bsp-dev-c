#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

usage() {
  cat <<'EOF'
Usage:
  tools/format_gen_build.sh [options]

Description:
  1) Run clang-format for C/C++ files under Modules/
  2) Generate xrobot header from YAML via xrobot_gen_main
  3) Build firmware with cube-cmake

Options:
  -c, --config <path>     YAML config path (default: xrobot.yaml)
  -b, --build-dir <dir>   Build dir for cube-cmake (default: build/debug)
      --skip-format       Skip clang-format step
  -h, --help              Show this help message

Examples:
  tools/format_gen_build.sh
  tools/format_gen_build.sh -c User/RobotConfig/omni_infantry.yaml
  tools/format_gen_build.sh -c User/RobotConfig/radar.yaml
  tools/format_gen_build.sh -c User/RobotConfig/hero.yaml -b /home/leo/Documents/bsp-dev-c/build/debug
EOF
}

CONFIG_PATH=""
DEFAULT_CONFIG_PRIMARY="xrobot.yaml"
DEFAULT_CONFIG_FALLBACK="User/xrobot.yaml"
BUILD_DIR="build/debug"
SKIP_FORMAT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config)
      if [[ $# -lt 2 || -z "${2}" || "${2}" == -* ]]; then
        echo "Error: $1 requires a path value." >&2
        usage >&2
        exit 2
      fi
      CONFIG_PATH="${2:-}"
      shift 2
      ;;
    -b|--build-dir)
      if [[ $# -lt 2 || -z "${2}" || "${2}" == -* ]]; then
        echo "Error: $1 requires a directory value." >&2
        usage >&2
        exit 2
      fi
      BUILD_DIR="${2:-}"
      shift 2
      ;;
    --skip-format)
      SKIP_FORMAT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "${BUILD_DIR}" = /* ]]; then
  BUILD_PATH="${BUILD_DIR}"
else
  BUILD_PATH="${REPO_ROOT}/${BUILD_DIR}"
fi

if [[ -z "${CONFIG_PATH}" ]]; then
  if [[ -f "${DEFAULT_CONFIG_PRIMARY}" ]]; then
    CONFIG_PATH="${DEFAULT_CONFIG_PRIMARY}"
  elif [[ -f "${DEFAULT_CONFIG_FALLBACK}" ]]; then
    CONFIG_PATH="${DEFAULT_CONFIG_FALLBACK}"
  else
    CONFIG_PATH="${DEFAULT_CONFIG_PRIMARY}"
  fi
fi

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "Error: YAML config not found: ${CONFIG_PATH}" >&2
  exit 1
fi

if ! command -v xrobot_gen_main >/dev/null 2>&1; then
  echo "Error: xrobot_gen_main not found in PATH." >&2
  exit 1
fi

if ! command -v cube-cmake >/dev/null 2>&1; then
  echo "Error: cube-cmake not found in PATH." >&2
  exit 1
fi

if [[ "${SKIP_FORMAT}" -eq 0 ]]; then
  echo "[1/3] Running clang-format..."
  "${REPO_ROOT}/tools/format_code.sh"
else
  echo "[1/3] Skip clang-format."
fi

echo "[2/3] Generating xrobot header from ${CONFIG_PATH}..."
xrobot_gen_main --config "${CONFIG_PATH}"

echo "[3/3] Building with cube-cmake..."
cube-cmake --build "${BUILD_PATH}"

echo "Done."
