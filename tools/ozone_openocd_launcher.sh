#!/usr/bin/env bash
set -euo pipefail

OPENOCD_BIN="${OPENOCD_BIN:-${OPENOCD_PATH:-openocd}}"
OZONE_BIN="${OZONE_BIN:-${OZONE_PATH:-ozone}}"

INTERFACE_CFG=""
TARGET_CFG=""
PROBE="daplink"
INTERFACE=""
INTERFACE_EXPLICIT="0"
TARGET="stm32f4x"
CHIP_EXPLICIT="0"
TRANSPORT="swd"
ADAPTER_SPEED="4000"
OPENOCD_GDB_PORT="3333"
OPENOCD_TELNET_PORT="4444"
OPENOCD_TCL_PORT="6666"
START_ORDER="openocd-first"
OPENOCD_WAIT_SEC="10"
OZONE_DELAY_SEC="1"
OPENOCD_LOG=""
OZONE_PROJECT=""
DRY_RUN="0"
NO_OZONE="0"

OPENOCD_SEARCH_DIRS=()
OPENOCD_EXTRA_CFGS=()
OPENOCD_EXTRA_CMDS=()
OZONE_ARGS=()

OPENOCD_PID=""
OZONE_PID=""

SUPPORTED_PROBES=("daplink" "jlink" "stlink")
SUPPORTED_TRANSPORTS=("swd" "jtag")
SUPPORTED_ST_CHIPS=(
  "stm32f0x" "stm32f1x" "stm32f2x" "stm32f3x" "stm32f4x" "stm32f7x"
  "stm32g0x" "stm32g4x" "stm32h7x" "stm32l0x" "stm32l1x" "stm32l4x"
  "stm32u5x" "stm32wbx"
)
SUPPORTED_HPM_CHIPS=("hpm5301" "hpm6200" "hpm6750")
SUPPORTED_ESP_CHIPS=("esp32" "esp32s2" "esp32s3" "esp32c2" "esp32c3" "esp32c6" "esp32h2")
SUPPORTED_CHIPS=("${SUPPORTED_ST_CHIPS[@]}" "${SUPPORTED_HPM_CHIPS[@]}" "${SUPPORTED_ESP_CHIPS[@]}")

usage() {
  cat <<'EOF'
Usage:
  ozone_openocd_launcher.sh [options] [-- OZONE_ARGS...]

Core options:
  -p, --project <file>          Ozone project or ELF file (optional)
  -b, --probe <name>            Probe preset: daplink|jlink|stlink (default: daplink)
  -i, --interface <name>        Raw OpenOCD interface name, overrides --probe
  -t, --chip <name>             Chip preset/raw OpenOCD target name (default: stm32f4x)
      --interface-cfg <file>    Use explicit interface cfg, overrides --probe/--interface
      --target-cfg <file>       Use explicit target cfg, overrides --chip
      --transport <mode>        Transport mode: swd/jtag (default: swd)
      --speed <kHz>             Adapter speed in kHz (default: 4000)
      --order <mode>            openocd-first|ozone-first (default: openocd-first)
      --wait <sec>              Wait timeout for OpenOCD port (default: 10)
      --ozone-delay <sec>       Delay before starting OpenOCD in ozone-first (default: 1)

OpenOCD advanced:
  -f, --cfg <file>              Extra OpenOCD cfg file (repeatable)
  -s, --search <dir>            OpenOCD search directory (repeatable)
      --ocd-cmd <cmd>           Extra OpenOCD command (repeatable)
      --gdb-port <port>         OpenOCD gdb port (default: 3333)
      --tcl-port <port>         OpenOCD tcl port (default: 6666)
      --telnet-port <port>      OpenOCD telnet port (default: 4444)
      --openocd-bin <path>      OpenOCD executable
      --openocd-path <path>     Alias of --openocd-bin
      --openocd-log <file>      Redirect OpenOCD output to file

Ozone advanced:
      --ozone-bin <path>        Ozone executable
      --ozone-path <path>       Alias of --ozone-bin
      --no-ozone                Start OpenOCD only
      --ozone-arg <arg>         Append one Ozone arg (repeatable)

Preset list (shown by -h/--help):
  Probes (--probe):
    daplink, jlink, stlink
  Burn methods (--transport):
    swd, jtag
  Chips (--chip):
    ST:  stm32f0x stm32f1x stm32f2x stm32f3x stm32f4x stm32f7x stm32g0x
         stm32g4x stm32h7x stm32l0x stm32l1x stm32l4x stm32u5x stm32wbx
    HPM: hpm5301 hpm6200 hpm6750
    ESP: esp32 esp32s2 esp32s3 esp32c2 esp32c3 esp32c6 esp32h2
  Notes:
    probe=daplink maps to interface/cmsis-dap.cfg
    unsupported chip preset can still be passed as raw target name, or use --target-cfg
    env path override: OZONE_PATH, OPENOCD_PATH (or OZONE_BIN, OPENOCD_BIN)
    for paths with spaces, wrap in quotes

Utility:
      --dry-run                 Print commands only
  -h, --help                    Show this help

Examples:
  # Linux: F4 + SWD + DAPLink + launch Ozone
  ozone_openocd_launcher.sh -b daplink -t stm32f4x --transport swd --order openocd-first
  ozone_openocd_launcher.sh -p build/app.elf -b daplink -t stm32h7x --transport swd
  ozone_openocd_launcher.sh --ozone-path /Applications/Ozone.app --openocd-path /opt/homebrew/bin/openocd
  ozone_openocd_launcher.sh --ozone-path 'C:\Program Files\SEGGER\Ozone\Ozone.exe' --openocd-path 'C:\Program Files\OpenOCD\bin\openocd.exe'
  ozone_openocd_launcher.sh --target-cfg target/stm32g4x.cfg --order ozone-first
  ozone_openocd_launcher.sh -p app.jdebug -- --fullscreen
EOF
}

err() {
  echo "[ERROR] $*" >&2
}

info() {
  echo "[INFO] $*"
}

is_in_list() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "${item}" == "${needle}" ]]; then
      return 0
    fi
  done
  return 1
}

probe_to_interface() {
  case "$1" in
    daplink) echo "cmsis-dap" ;;
    jlink) echo "jlink" ;;
    stlink) echo "stlink" ;;
    *) return 1 ;;
  esac
}

normalize_chip() {
  case "$1" in
    stm32f4) echo "stm32f4x" ;;
    stm32h7) echo "stm32h7x" ;;
    *) echo "$1" ;;
  esac
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

first_executable() {
  local p
  for p in "$@"; do
    if [[ -x "${p}" ]]; then
      echo "${p}"
      return 0
    fi
  done
  return 1
}

resolve_openocd_bin() {
  local p
  p="$(normalize_user_path "$1")"

  if [[ -d "${p}" ]]; then
    local found=""
    found="$(first_executable "${p}/openocd" "${p}/openocd.exe" "${p}/bin/openocd" "${p}/bin/openocd.exe" || true)"
    if [[ -n "${found}" ]]; then
      echo "${found}"
      return
    fi
  fi

  echo "${p}"
}

resolve_ozone_bin() {
  local p
  p="$(normalize_user_path "$1")"

  if [[ "${p}" == *.app ]]; then
    echo "${p}/Contents/MacOS/Ozone"
    return
  fi

  if [[ -d "${p}" ]]; then
    local found=""
    found="$(first_executable "${p}/Ozone" "${p}/ozone" "${p}/Ozone.exe" "${p}/Contents/MacOS/Ozone" || true)"
    if [[ -n "${found}" ]]; then
      echo "${found}"
      return
    fi
  fi

  echo "${p}"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

port_ready() {
  local host="$1"
  local port="$2"

  if has_cmd nc; then
    nc -z "$host" "$port" >/dev/null 2>&1
    return $?
  fi

  (echo >"/dev/tcp/${host}/${port}") >/dev/null 2>&1
}

wait_for_openocd() {
  local deadline
  deadline=$((SECONDS + OPENOCD_WAIT_SEC))

  while (( SECONDS < deadline )); do
    if port_ready "127.0.0.1" "$OPENOCD_GDB_PORT"; then
      info "OpenOCD gdb port ${OPENOCD_GDB_PORT} is ready."
      return 0
    fi
    sleep 0.2
  done

  return 1
}

cleanup() {
  local ec="$1"

  if [[ -n "${OZONE_PID}" ]] && kill -0 "${OZONE_PID}" >/dev/null 2>&1; then
    kill "${OZONE_PID}" >/dev/null 2>&1 || true
  fi

  if [[ -n "${OPENOCD_PID}" ]] && kill -0 "${OPENOCD_PID}" >/dev/null 2>&1; then
    kill "${OPENOCD_PID}" >/dev/null 2>&1 || true
  fi

  exit "${ec}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--project)
      OZONE_PROJECT="${2:-}"
      shift 2
      ;;
    -b|--probe)
      PROBE="${2:-}"
      shift 2
      ;;
    -i|--interface)
      INTERFACE="${2:-}"
      INTERFACE_EXPLICIT="1"
      shift 2
      ;;
    -t|--chip)
      TARGET="${2:-}"
      CHIP_EXPLICIT="1"
      shift 2
      ;;
    --interface-cfg)
      INTERFACE_CFG="${2:-}"
      shift 2
      ;;
    --target-cfg)
      TARGET_CFG="${2:-}"
      shift 2
      ;;
    --transport)
      TRANSPORT="${2:-}"
      shift 2
      ;;
    --speed)
      ADAPTER_SPEED="${2:-}"
      shift 2
      ;;
    --order)
      START_ORDER="${2:-}"
      shift 2
      ;;
    --wait)
      OPENOCD_WAIT_SEC="${2:-}"
      shift 2
      ;;
    --ozone-delay)
      OZONE_DELAY_SEC="${2:-}"
      shift 2
      ;;
    -f|--cfg)
      OPENOCD_EXTRA_CFGS+=("${2:-}")
      shift 2
      ;;
    -s|--search)
      OPENOCD_SEARCH_DIRS+=("${2:-}")
      shift 2
      ;;
    --ocd-cmd)
      OPENOCD_EXTRA_CMDS+=("${2:-}")
      shift 2
      ;;
    --gdb-port)
      OPENOCD_GDB_PORT="${2:-}"
      shift 2
      ;;
    --tcl-port)
      OPENOCD_TCL_PORT="${2:-}"
      shift 2
      ;;
    --telnet-port)
      OPENOCD_TELNET_PORT="${2:-}"
      shift 2
      ;;
    --openocd-bin|--openocd-path)
      OPENOCD_BIN="${2:-}"
      shift 2
      ;;
    --openocd-log)
      OPENOCD_LOG="${2:-}"
      shift 2
      ;;
    --ozone-bin|--ozone-path)
      OZONE_BIN="${2:-}"
      shift 2
      ;;
    --ozone-arg)
      OZONE_ARGS+=("${2:-}")
      shift 2
      ;;
    --no-ozone)
      NO_OZONE="1"
      shift
      ;;
    --dry-run)
      DRY_RUN="1"
      shift
      ;;
    -h|--h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      OZONE_ARGS+=("$@")
      break
      ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! [[ "${OPENOCD_WAIT_SEC}" =~ ^[0-9]+$ ]]; then
  err "--wait must be a non-negative integer"
  exit 1
fi

if ! [[ "${OPENOCD_GDB_PORT}" =~ ^[0-9]+$ && "${OPENOCD_TCL_PORT}" =~ ^[0-9]+$ && "${OPENOCD_TELNET_PORT}" =~ ^[0-9]+$ ]]; then
  err "port values must be integers"
  exit 1
fi

if [[ "${START_ORDER}" != "openocd-first" && "${START_ORDER}" != "ozone-first" ]]; then
  err "--order only supports: openocd-first | ozone-first"
  exit 1
fi

if ! is_in_list "${TRANSPORT}" "${SUPPORTED_TRANSPORTS[@]}"; then
  err "--transport must be one of: ${SUPPORTED_TRANSPORTS[*]}"
  exit 1
fi

if [[ -z "${INTERFACE_CFG}" ]]; then
  if [[ "${INTERFACE_EXPLICIT}" == "1" ]]; then
    if [[ -z "${INTERFACE}" ]]; then
      err "--interface cannot be empty"
      exit 1
    fi
  else
    if ! is_in_list "${PROBE}" "${SUPPORTED_PROBES[@]}"; then
      err "--probe must be one of: ${SUPPORTED_PROBES[*]}"
      exit 1
    fi
    INTERFACE="$(probe_to_interface "${PROBE}")"
  fi
fi

if [[ -z "${TARGET_CFG}" ]]; then
  TARGET="$(normalize_chip "${TARGET}")"
  if [[ "${CHIP_EXPLICIT}" == "1" ]] && ! is_in_list "${TARGET}" "${SUPPORTED_CHIPS[@]}"; then
    info "Chip '${TARGET}' is not in preset list; treat it as raw OpenOCD target name."
  fi
fi

OPENOCD_BIN="$(resolve_openocd_bin "${OPENOCD_BIN}")"
OZONE_BIN="$(resolve_ozone_bin "${OZONE_BIN}")"

if [[ "${DRY_RUN}" != "1" ]]; then
  has_cmd "${OPENOCD_BIN}" || { err "OpenOCD not found: ${OPENOCD_BIN}"; exit 1; }
  if [[ "${NO_OZONE}" != "1" ]]; then
    has_cmd "${OZONE_BIN}" || { err "Ozone not found: ${OZONE_BIN}"; exit 1; }
  fi
fi

OPENOCD_ARGS=()
for d in "${OPENOCD_SEARCH_DIRS[@]}"; do
  OPENOCD_ARGS+=(-s "$d")
done

if [[ -n "${INTERFACE_CFG}" ]]; then
  OPENOCD_ARGS+=(-f "${INTERFACE_CFG}")
else
  OPENOCD_ARGS+=(-f "interface/${INTERFACE}.cfg")
fi

# For probes like J-Link, transport must be selected before loading target cfg.
OPENOCD_ARGS+=(-c "transport select ${TRANSPORT}")

if [[ -n "${TARGET_CFG}" ]]; then
  OPENOCD_ARGS+=(-f "${TARGET_CFG}")
else
  OPENOCD_ARGS+=(-f "target/${TARGET}.cfg")
fi

for c in "${OPENOCD_EXTRA_CFGS[@]}"; do
  OPENOCD_ARGS+=(-f "$c")
done

OPENOCD_ARGS+=(
  -c "adapter speed ${ADAPTER_SPEED}"
  -c "gdb_port ${OPENOCD_GDB_PORT}"
  -c "tcl_port ${OPENOCD_TCL_PORT}"
  -c "telnet_port ${OPENOCD_TELNET_PORT}"
)

for c in "${OPENOCD_EXTRA_CMDS[@]}"; do
  OPENOCD_ARGS+=(-c "$c")
done

OZONE_CMD=("${OZONE_BIN}")
if [[ -n "${OZONE_PROJECT}" ]]; then
  OZONE_CMD+=("${OZONE_PROJECT}")
fi
if [[ "${#OZONE_ARGS[@]}" -gt 0 ]]; then
  OZONE_CMD+=("${OZONE_ARGS[@]}")
fi

OPENOCD_CMD=("${OPENOCD_BIN}" "${OPENOCD_ARGS[@]}")

start_openocd() {
  info "Start OpenOCD: ${OPENOCD_CMD[*]}"
  if [[ "${DRY_RUN}" == "1" ]]; then
    return 0
  fi

  if [[ -n "${OPENOCD_LOG}" ]]; then
    "${OPENOCD_CMD[@]}" >"${OPENOCD_LOG}" 2>&1 &
  else
    "${OPENOCD_CMD[@]}" &
  fi
  OPENOCD_PID="$!"
  info "OpenOCD PID: ${OPENOCD_PID}"
}

start_ozone() {
  info "Start Ozone: ${OZONE_CMD[*]}"
  if [[ "${DRY_RUN}" == "1" ]]; then
    return 0
  fi
  "${OZONE_CMD[@]}" &
  OZONE_PID="$!"
  info "Ozone PID: ${OZONE_PID}"
}

trap 'cleanup $?' INT TERM

if [[ "${START_ORDER}" == "openocd-first" ]]; then
  start_openocd

  if [[ "${DRY_RUN}" != "1" ]]; then
    if ! wait_for_openocd; then
      err "OpenOCD did not open gdb port ${OPENOCD_GDB_PORT} within ${OPENOCD_WAIT_SEC}s."
      cleanup 1
    fi
  fi

  if [[ "${NO_OZONE}" != "1" ]]; then
    start_ozone
    if [[ "${DRY_RUN}" != "1" ]]; then
      wait "${OZONE_PID}" || true
      cleanup 0
    fi
  else
    if [[ "${DRY_RUN}" != "1" ]]; then
      wait "${OPENOCD_PID}" || true
    fi
  fi
else
  if [[ "${NO_OZONE}" != "1" ]]; then
    start_ozone
  fi

  if [[ "${DRY_RUN}" != "1" && "${OZONE_DELAY_SEC}" != "0" ]]; then
    sleep "${OZONE_DELAY_SEC}"
  fi

  start_openocd

  if [[ "${DRY_RUN}" != "1" ]]; then
    if ! wait_for_openocd; then
      err "OpenOCD did not open gdb port ${OPENOCD_GDB_PORT} within ${OPENOCD_WAIT_SEC}s."
      cleanup 1
    fi
  fi

  if [[ "${NO_OZONE}" != "1" ]]; then
    if [[ "${DRY_RUN}" != "1" ]]; then
      wait "${OZONE_PID}" || true
      cleanup 0
    fi
  else
    if [[ "${DRY_RUN}" != "1" ]]; then
      wait "${OPENOCD_PID}" || true
    fi
  fi
fi
