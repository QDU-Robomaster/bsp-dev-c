#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

usage() {
  cat <<'EOF'
Usage:
  tools/build.sh [options]

Description:
  1) Run clang-format for C/C++ files under Modules/
  2) Generate xrobot header from YAML via xrobot_gen_main
  3) Configure firmware with cube-cmake
  4) Build firmware with cube-cmake

Options:
  -c, --config <path>     YAML config path (default: xrobot.yaml)
  -p, --preset <name>     CMake preset name (default: $CMAKE_BUILD_PRESET or debug)
  -b, --build-dir <dir>   Build dir for cube-cmake (overrides --preset)
      --skip-format       Skip clang-format step
  -h, --help              Show this help message

Examples:
  tools/build.sh
  tools/build.sh -p release
  tools/build.sh -c User/RobotConfig/omni_infantry.yaml -p relWithDebInfo
  tools/build.sh -c User/RobotConfig/hero.yaml -b /home/leo/Documents/bsp-dev-c/build/custom
EOF
}

detect_cube_cmake_platform() {
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
      return 1
      ;;
  esac
}

prepend_path() {
  if [[ -z "${1:-}" || ! -d "${1}" ]]; then
    return 0
  fi

  case ":${PATH}:" in
    *":${1}:"*)
      ;;
    *)
      PATH="${1}:${PATH}"
      export PATH
      ;;
  esac
}

cube_cmake_arch_candidates() {
  case "$(uname -m)" in
    x86_64|amd64)
      printf '%s\n' "x86_64" "amd64"
      ;;
    arm64)
      printf '%s\n' "arm64" "aarch64" "x86_64"
      ;;
    aarch64)
      printf '%s\n' "aarch64" "arm64" "x86_64"
      ;;
    *)
      printf '%s\n' "$(uname -m)"
      ;;
  esac
}

editor_extension_roots() {
  local extension_roots=()
  local root

  if [[ -n "${VSCODE_EXTENSIONS:-}" ]]; then
    extension_roots+=("${VSCODE_EXTENSIONS}")
  fi

  extension_roots+=(
    "${HOME}/.vscode/extensions"
    "${HOME}/.vscode-insiders/extensions"
    "${HOME}/.vscode-oss/extensions"
    "${HOME}/.cursor/extensions"
    "${HOME}/.windsurf/extensions"
  )

  for root in "${extension_roots[@]}"; do
    [[ -d "${root}" ]] || continue
    printf '%s\n' "${root}"
  done
}

find_cube_cmake_in_extensions() {
  local platform root extension_dir arch candidate

  platform="$(detect_cube_cmake_platform)" || return 1
  while IFS= read -r root; do
    [[ -d "${root}" ]] || continue

    for extension_dir in "${root}"/stmicroelectronics.stm32cube-ide-build-cmake-*; do
      [[ -d "${extension_dir}" ]] || continue

      while IFS= read -r arch; do
        candidate="${extension_dir}/resources/cube-cmake/${platform}/${arch}/cube-cmake"

        if [[ "${platform}" == "win32" && -x "${candidate}.exe" ]]; then
          printf '%s\n' "${candidate}.exe"
          return 0
        fi

        if [[ -x "${candidate}" ]]; then
          printf '%s\n' "${candidate}"
          return 0
        fi
      done < <(cube_cmake_arch_candidates)
    done
  done < <(editor_extension_roots)

  return 1
}

find_cube_cli_in_extensions() {
  local platform root extension_dir arch candidate

  platform="$(detect_cube_cmake_platform)" || return 1
  while IFS= read -r root; do
    [[ -d "${root}" ]] || continue

    for extension_dir in "${root}"/stmicroelectronics.stm32cube-ide-core-*; do
      [[ -d "${extension_dir}" ]] || continue

      while IFS= read -r arch; do
        candidate="${extension_dir}/resources/binaries/${platform}/${arch}/cube"

        if [[ "${platform}" == "win32" && -x "${candidate}.exe" ]]; then
          printf '%s\n' "${candidate}.exe"
          return 0
        fi

        if [[ -x "${candidate}" ]]; then
          printf '%s\n' "${candidate}"
          return 0
        fi
      done < <(cube_cmake_arch_candidates)
    done
  done < <(editor_extension_roots)

  return 1
}

resolve_cube_cli() {
  local detected_cube

  if command -v cube >/dev/null 2>&1; then
    CUBE_BIN="$(command -v cube)"
    return 0
  fi

  if detected_cube="$(find_cube_cli_in_extensions)"; then
    prepend_path "$(dirname "${detected_cube}")"
    CUBE_BIN="${detected_cube}"
    echo "[preflight] cube not in PATH; using STM32 extension copy at ${CUBE_BIN}."
    return 0
  fi

  return 1
}

resolve_cube_cmake() {
  local detected_cube_cmake

  if command -v cube-cmake >/dev/null 2>&1; then
    CUBE_CMAKE_BIN="$(command -v cube-cmake)"
    return 0
  fi

  if detected_cube_cmake="$(find_cube_cmake_in_extensions)"; then
    prepend_path "$(dirname "${detected_cube_cmake}")"
    CUBE_CMAKE_BIN="${detected_cube_cmake}"
    echo "[preflight] cube-cmake not in PATH; using STM32 extension copy at ${CUBE_CMAKE_BIN}."
    return 0
  fi

  return 1
}

find_latest_subdir() {
  local parent_dir="$1"
  local candidate
  local latest=""

  [[ -d "${parent_dir}" ]] || return 1

  for candidate in "${parent_dir}"/*; do
    [[ -d "${candidate}" ]] || continue
    latest="${candidate}"
  done

  [[ -n "${latest}" ]] || return 1
  printf '%s\n' "${latest}"
}

find_stm32_bundle_roots() {
  local bundle_roots=()
  local root

  if [[ -n "${CUBE_BUNDLE_PATH:-}" ]]; then
    bundle_roots+=("${CUBE_BUNDLE_PATH}")
  fi

  bundle_roots+=(
    "${HOME}/AppData/Local/stm32cube/bundles"
    "${HOME}/.stm32cube/bundles"
    "${HOME}/.local/share/stm32cube/bundles"
    "${HOME}/.config/stm32cube/bundles"
    "${HOME}/Library/Application Support/stm32cube/bundles"
  )

  for root in "${bundle_roots[@]}"; do
    [[ -d "${root}" ]] || continue
    printf '%s\n' "${root}"
  done
}

resolve_stm32_toolchains() {
  local bundle_root
  local detected_gcc_root=""
  local detected_clang_root=""

  if [[ -n "${GCC_TOOLCHAIN_ROOT:-}" && ! -d "${GCC_TOOLCHAIN_ROOT}" ]]; then
    unset GCC_TOOLCHAIN_ROOT
  fi

  if [[ -n "${CLANG_GCC_CMSIS_COMPILER:-}" && ! -d "${CLANG_GCC_CMSIS_COMPILER}" ]]; then
    unset CLANG_GCC_CMSIS_COMPILER
  fi

  while IFS= read -r bundle_root; do
    if [[ -z "${GCC_TOOLCHAIN_ROOT:-}" && -z "${detected_gcc_root}" ]]; then
      detected_gcc_root="$(find_latest_subdir "${bundle_root}/gnu-tools-for-stm32" || true)"
      if [[ -n "${detected_gcc_root}" && -d "${detected_gcc_root}/bin" ]]; then
        detected_gcc_root="${detected_gcc_root}/bin"
      fi
    fi

    if [[ -z "${CLANG_GCC_CMSIS_COMPILER:-}" && -z "${detected_clang_root}" ]]; then
      detected_clang_root="$(find_latest_subdir "${bundle_root}/st-arm-clang" || true)"
    fi

    if [[ -n "${GCC_TOOLCHAIN_ROOT:-${detected_gcc_root}}" && -n "${CLANG_GCC_CMSIS_COMPILER:-${detected_clang_root}}" ]]; then
      break
    fi
  done < <(find_stm32_bundle_roots)

  if [[ -z "${GCC_TOOLCHAIN_ROOT:-}" && -n "${detected_gcc_root}" ]]; then
    export GCC_TOOLCHAIN_ROOT="${detected_gcc_root}"
    echo "[preflight] GCC_TOOLCHAIN_ROOT not set; using ${GCC_TOOLCHAIN_ROOT}."
  fi

  if [[ -z "${CLANG_GCC_CMSIS_COMPILER:-}" && -n "${detected_clang_root}" ]]; then
    export CLANG_GCC_CMSIS_COMPILER="${detected_clang_root}"
    echo "[preflight] CLANG_GCC_CMSIS_COMPILER not set; using ${CLANG_GCC_CMSIS_COMPILER}."
  fi

  prepend_path "${GCC_TOOLCHAIN_ROOT:-}"
  prepend_path "${CLANG_GCC_CMSIS_COMPILER:-}/bin"
}

preset_build_type() {
  case "$1" in
    debug)
      printf '%s\n' "Debug"
      ;;
    relWithDebInfo)
      printf '%s\n' "RelWithDebInfo"
      ;;
    release)
      printf '%s\n' "Release"
      ;;
    minSizeRel)
      printf '%s\n' "MinSizeRel"
      ;;
    *)
      printf '%s\n' "Debug"
      ;;
  esac
}

configure_build_tree() {
  if [[ -n "${BUILD_DIR}" ]]; then
    local build_type
    build_type="$(preset_build_type "${PRESET}")"

    "${CUBE_CMAKE_BIN}" \
      -S "${REPO_ROOT}" \
      -B "${BUILD_PATH}" \
      -G Ninja \
      --toolchain "${REPO_ROOT}/cmake/starm-clang.cmake" \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
      -DCMAKE_BUILD_TYPE="${build_type}"
  else
    "${CUBE_CMAKE_BIN}" --preset "${PRESET}"
  fi
}

CONFIG_PATH=""
DEFAULT_CONFIG_PRIMARY="xrobot.yaml"
DEFAULT_CONFIG_FALLBACK="User/xrobot.yaml"
DEFAULT_PRESET="debug"
PRESET="${CMAKE_BUILD_PRESET:-${CMAKE_PRESET:-}}"
BUILD_DIR=""
SKIP_FORMAT=0
CUBE_BIN=""
CUBE_CMAKE_BIN=""

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
    -p|--preset)
      if [[ $# -lt 2 || -z "${2}" || "${2}" == -* ]]; then
        echo "Error: $1 requires a preset name." >&2
        usage >&2
        exit 2
      fi
      PRESET="${2:-}"
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

if [[ -n "${BUILD_DIR}" ]]; then
  if [[ "${BUILD_DIR}" = /* ]]; then
    BUILD_PATH="${BUILD_DIR}"
  else
    BUILD_PATH="${REPO_ROOT}/${BUILD_DIR}"
  fi
  BUILD_TARGET_DESC="directory: ${BUILD_PATH}"
else
  if [[ -z "${PRESET}" ]]; then
    PRESET="${DEFAULT_PRESET}"
  fi
  BUILD_PATH="${REPO_ROOT}/build/${PRESET}"
  BUILD_TARGET_DESC="preset: ${PRESET} (dir: ${BUILD_PATH})"
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

if ! resolve_cube_cli; then
  echo "Error: cube not found in PATH or STM32 VS Code extension directories." >&2
  exit 1
fi

if ! resolve_cube_cmake; then
  echo "Error: cube-cmake not found in PATH or STM32 VS Code extension directories." >&2
  exit 1
fi

resolve_stm32_toolchains

if [[ -z "${GCC_TOOLCHAIN_ROOT:-}" || ! -d "${GCC_TOOLCHAIN_ROOT}" ]]; then
  echo "Error: GCC_TOOLCHAIN_ROOT is not configured and could not be auto-detected." >&2
  exit 1
fi

if [[ -z "${CLANG_GCC_CMSIS_COMPILER:-}" || ! -d "${CLANG_GCC_CMSIS_COMPILER}" ]]; then
  echo "Error: CLANG_GCC_CMSIS_COMPILER is not configured and could not be auto-detected." >&2
  exit 1
fi

if ! command -v starm-clang >/dev/null 2>&1; then
  echo "Error: starm-clang not found in PATH after toolchain detection." >&2
  exit 1
fi

if [[ "${SKIP_FORMAT}" -eq 0 ]]; then
  echo "[1/4] Running clang-format..."
  "${REPO_ROOT}/tools/format_code.sh"
else
  echo "[1/4] Skip clang-format."
fi

echo "[2/4] Generating xrobot header from ${CONFIG_PATH}..."
xrobot_gen_main --config "${CONFIG_PATH}"

echo "[3/4] Configuring with cube-cmake (${BUILD_TARGET_DESC})..."
configure_build_tree

echo "[4/4] Building with cube-cmake (${BUILD_TARGET_DESC})..."
"${CUBE_CMAKE_BIN}" --build "${BUILD_PATH}"

echo "Done."
