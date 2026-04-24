#!/usr/bin/env bash
set -euo pipefail

OPENOCD_BIN="${OPENOCD_BIN:-${OPENOCD_PATH:-openocd}}"
OPENOCD_LOG=""
DRY_RUN="0"

INTERFACE_CFG="interface/cmsis-dap.cfg"
TARGET_CFG="target/stm32f4x.cfg"
TRANSPORT="swd"
ADAPTER_SPEED="4000"
GDB_PORT="3333"
TCL_PORT="6666"
TELNET_PORT="4444"

usage() {
  cat <<'EOF'
Usage:
  ozone_openocd_launcher.sh [--openocd-path <path>] [--log <file>] [--dry-run]

Fixed config:
  Probe:     DAPLink / CMSIS-DAP
  Chip:      STM32F407IG
  Target cfg:target/stm32f4x.cfg
  Transport: SWD
  GDB port:  3333

Examples:
  ./tools/ozone_openocd_launcher.sh
  ./tools/ozone_openocd_launcher.sh --openocd-path /e/application/xpack-openocd-0.12.0-7
  ./tools/ozone_openocd_launcher.sh --log openocd.log
EOF
}

err() {
  echo "[ERROR] $*" >&2
}

info() {
  echo "[INFO] $*"
}

normalize_user_path() {
  local p="$1"

  if [[ -z "${p}" ]]; then
    echo "${p}"
    return
  fi

  if [[ "${p}" == "~/"* ]]; then
    p="${HOME}/${p#~/}"
  fi

  if [[ "${p}" =~ ^([A-Za-z]):[\\/](.*)$ ]]; then
    local drive="${BASH_REMATCH[1],,}"
    local rest="${BASH_REMATCH[2]}"
    rest="${rest//\\//}"
    p="/${drive}/${rest}"
  fi

  echo "${p}"
}

resolve_openocd_bin() {
  local p
  p="$(normalize_user_path "$1")"

  if [[ -d "${p}" ]]; then
    if [[ -x "${p}/bin/openocd.exe" ]]; then
      echo "${p}/bin/openocd.exe"
      return
    fi
    if [[ -x "${p}/bin/openocd" ]]; then
      echo "${p}/bin/openocd"
      return
    fi
    if [[ -x "${p}/openocd.exe" ]]; then
      echo "${p}/openocd.exe"
      return
    fi
    if [[ -x "${p}/openocd" ]]; then
      echo "${p}/openocd"
      return
    fi
  fi

  echo "${p}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --openocd-path|--openocd-bin)
      OPENOCD_BIN="${2:-}"
      shift 2
      ;;
    --log)
      OPENOCD_LOG="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

OPENOCD_BIN="$(resolve_openocd_bin "${OPENOCD_BIN}")"

command -v "${OPENOCD_BIN}" >/dev/null 2>&1 || {
  err "OpenOCD not found: ${OPENOCD_BIN}"
  exit 1
}

OPENOCD_CMD=(
  "${OPENOCD_BIN}"
  -f "${INTERFACE_CFG}"
  -c "transport select ${TRANSPORT}"
  -f "${TARGET_CFG}"
  -c "adapter speed ${ADAPTER_SPEED}"
  -c "gdb_port ${GDB_PORT}"
  -c "tcl_port ${TCL_PORT}"
  -c "telnet_port ${TELNET_PORT}"
)

info "Probe: DAPLink / CMSIS-DAP"
info "Chip: STM32F407IG"
info "OpenOCD target: ${TARGET_CFG}"
info "GDB server: 127.0.0.1:${GDB_PORT}"
info "Start OpenOCD: ${OPENOCD_CMD[*]}"

if [[ "${DRY_RUN}" == "1" ]]; then
  exit 0
fi

if [[ -n "${OPENOCD_LOG}" ]]; then
  exec "${OPENOCD_CMD[@]}" >"${OPENOCD_LOG}" 2>&1
else
  exec "${OPENOCD_CMD[@]}"
fi
