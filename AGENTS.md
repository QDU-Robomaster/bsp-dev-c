# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-05
**Commit:** f8aa31b
**Branch:** dev

## OVERVIEW

STM32F407-based RoboMaster robot BSP using LibXR framework and xrobot YAML-driven module system.
Targets: sentry, hero, infantry (omni/helm), aerial, dart, radar, wheel-leg platforms.

## STRUCTURE

```
bsp-dev-c/
├── Core/           # CubeMX-generated HAL init (DO NOT edit outside USER CODE regions)
├── Drivers/        # Vendor: STM32 HAL + CMSIS (read-only)
├── Middlewares/     # Vendor: FreeRTOS, LibXR submodule (read-only, has own AGENTS.md)
├── Modules/        # Robot modules: Chassis, Gimbal, Motor, etc. (see Modules/AGENTS.md)
├── User/           # Application layer: hardware mapping + robot configs (see User/AGENTS.md)
├── cmake/          # Toolchain (starm-clang, gcc-arm) + CubeMX CMake integration
├── tools/          # build.sh, format_code.sh, ozone launcher
├── DevC.ioc        # CubeMX project (STM32F407IGHx)
└── STM32F407XX_FLASH.ld  # Linker script
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add/modify robot behavior | `User/RobotConfig/*.yaml` | YAML-driven module composition |
| Map new hardware peripheral | `User/app_main.cpp` | Register into `HardwareContainer` |
| Add new robot module | `Modules/<Name>/` | Must follow xrobot module pattern |
| Modify boot/peripheral init | `Core/Src/main.c` | Only inside `USER CODE BEGIN/END` blocks |
| Change build pipeline | `tools/build.sh` | format -> generate -> compile |
| Adjust cross-compilation | `cmake/starm-clang.cmake` | Toolchain flags |
| LibXR framework integration | `cmake/LibXR.CMake` | Sets C++17, FreeRTOS, `st` driver |
| Flash memory layout | `User/flash_map.hpp` | Auto-generated sector table |

## CONVENTIONS

### Naming (enforced by `.clangd` + Clang-Tidy)
- Variables / globals: `lower_case`
- Class/private/protected members: `lower_case_` (trailing underscore)
- Classes / structs / enums: `CamelCase`
- Class methods: `CamelCase`; free functions: `lower_case`
- **All `const`/`constexpr` constants: `UPPER_CASE`** (hard constraint, any scope)
- Enum constants / macros: `UPPER_CASE`
- File names: `PascalCase.hpp` for modules; `snake_case.yaml` for robot configs

### Formatting
- `.clang-format`: Google style, `IncludeBlocks: Regroup`
- **clang-format 21.1.8** required (enforced by `tools/format_code.sh`)
- Formatting scope: `Modules/` only (not Core/, Drivers/, Middlewares/)
- Install: `python3 -m venv .venv-clang-format && .venv-clang-format/bin/pip install "clang-format==21.1.8"`

### Build
- C11 + C++17, `-Werror` globally
- Debug: app code `-Og`, libraries `-O2`
- Target: Cortex-M4 FPv4-SP, `-fno-rtti -fno-exceptions`
- Do not force-link newlib `_printf_float`; LibXR formatting does not require it

### Agent Naming Enforcement
- For naming audits, identifier refactors, and style-conformance fixes in C/C++ or YAML, invoke `$bsp-dev-c-naming` by default.
- Mandatory unless user explicitly requests a compatibility-preserving exception.

## ANTI-PATTERNS (THIS PROJECT)

- **DO NOT** edit `Core/Src/*.c` outside `/* USER CODE BEGIN */` / `/* USER CODE END */` blocks
- **DO NOT** modify anything in `Drivers/` or `Middlewares/` (treat as read-only vendor code)
- **DO NOT** use Legacy HAL APIs from `Drivers/STM32F4xx_HAL_Driver/Inc/Legacy/`
- **DO NOT** override weak HAL callbacks in vendor files; implement overrides in `User/` or `Core/Src/stm32f4xx_hal_msp.c`
- **DO NOT** hand-tune include ordering after running clang-format
- **DO NOT** add `#pragma` diagnostic suppression in application code
- **DO NOT** commit `build/` artifacts
- **NEVER** mix generated-file edits with functional changes in a single commit

## COMMANDS

```bash
# Setup
git submodule update --init --recursive
pip install libxr xrobot

# Full pipeline (format + generate + build)
tools/build.sh -c User/xrobot.yaml -b build/debug

# Compile-only (skip formatting, faster)
tools/build.sh --skip-format -c User/xrobot.yaml -b build/debug

# Build specific robot config
tools/build.sh -c User/RobotConfig/sentry.yaml -b build/debug

# Format check (CI mode)
tools/format_code.sh --check

# Format apply
tools/format_code.sh

# Generate xrobot code only
xr_cubemx_cfg -d ./ --xrobot && xrobot_setup
```

## CI

- Workflow: `.github/workflows/xrobot_stm32.yml`
- Triggers: push/PR to `main`/`master`
- Container: `ghcr.io/xrobot-org/docker-image-stm32:main`
- Builds 6 robot configs: aerial, dart, helm_infantry, omni_infantry, radar, wheel_leg
- Gate: all configs must compile clean with `-Werror`

## EXECUTION FLOW

```
startup_stm32f407xx.s (Reset_Handler)
  -> Core/Src/main.c: HAL_Init() -> SystemClock_Config() -> MX_*_Init()
    -> osKernelStart() -> StartDefaultTask()
      -> User/app_main.cpp: app_main()
        -> Platform init, hardware objects, HardwareContainer
          -> User/xrobot_main.hpp: XRobotMain(peripherals)
            -> Module instantiation from YAML config
            -> appmgr.MonitorAll() loop
```

## NOTES

- `xrobot_gen_main` and `cube-cmake` must be in `PATH` for build
- `GCC_TOOLCHAIN_ROOT` and `CLANG_GCC_CMSIS_COMPILER` env vars needed for local builds
- LibXR memory model: allocate at init, never free (intentional)
- Only one git submodule: `Middlewares/Third_Party/LibXR`
- Modules are fetched via `xrobot_init_mod` from remote registries (see `Modules/sources.yaml`)
- Commit style: short imperative subjects (Chinese or English OK), one logical change per commit
