# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

STM32F407-based RoboMaster robot Board Support Package (BSP) using the LibXR framework and xrobot YAML-driven module system. Targets multiple robot platforms: sentry, hero, infantry (omni/helm), aerial, dart, radar, and wheel-leg configurations.

## Build Commands

### Initial Setup
```bash
# Clone with submodules
git submodule update --init --recursive

# Install Python dependencies
pip install libxr xrobot

# Initialize modules from registry
xrobot_init_mod --config https://raw.githubusercontent.com/QDU-Robomaster/dev-c-robots/refs/heads/main/test.yaml --dir ./Modules

# Generate xrobot code
xr_cubemx_cfg -d ./ --xrobot
xrobot_setup
```

### Building

**Full build pipeline** (format + generate + build):
```bash
tools/build.sh -c User/xrobot.yaml -b build/debug
```

**Compile-only** (skip formatting, faster iteration):
```bash
tools/build.sh --skip-format -c User/xrobot.yaml -b build/debug
```

**Build specific robot configuration**:
```bash
tools/build.sh -c User/RobotConfig/sentry.yaml -b build/debug
tools/build.sh -c User/RobotConfig/hero.yaml -b build/debug
tools/build.sh -c User/RobotConfig/omni_infantry_3.yaml -b build/debug
```

### Code Formatting

**Format all code in Modules/**:
```bash
tools/format_code.sh
```

**Format check (CI mode)**:
```bash
tools/format_code.sh --check
```

**Install clang-format 21.1.8** (required version):
```bash
python3 -m venv .venv-clang-format
.venv-clang-format/bin/pip install "clang-format==21.1.8"
```

### Generate Code Only
```bash
xr_cubemx_cfg -d ./ --xrobot && xrobot_setup
```

## Architecture

### Execution Flow
```
Reset_Handler (startup_stm32f407xx.s)
  → Core/Src/main.c: HAL_Init() → SystemClock_Config() → MX_*_Init()
    → osKernelStart() → StartDefaultTask()
      → User/app_main.cpp: app_main()
        → Platform init, hardware objects, HardwareContainer
          → User/xrobot_main.hpp: XRobotMain(peripherals)
            → Module instantiation from YAML config
            → appmgr.MonitorAll() loop
```

### Directory Structure

- **Core/**: STM32CubeMX-generated HAL initialization code
  - Only edit inside `/* USER CODE BEGIN */` / `/* USER CODE END */` blocks
- **Drivers/**: STM32 HAL + CMSIS vendor libraries (read-only)
- **Middlewares/**: FreeRTOS and LibXR submodule (read-only, has own AGENTS.md)
- **Modules/**: Robot functional modules (Chassis, Gimbal, Motor drivers, sensors, etc.)
  - Each module is often an independent git repository
  - This is the **only directory** that gets formatted with clang-format
- **User/**: Application layer
  - `app_main.cpp`: Hardware mapping and peripheral instantiation
  - `xrobot_main.hpp`: Auto-generated from YAML, DO NOT edit manually
  - `RobotConfig/*.yaml`: Robot-specific configurations
- **cmake/**: Toolchain files (starm-clang, gcc-arm) and CubeMX integration
- **tools/**: Build scripts, formatting, debugging helpers

### Hardware Abstraction

Hardware peripherals are registered in `User/app_main.cpp` via `HardwareContainer` with string-based logical names (e.g., `"can1"`, `"uart_dr16"`, `"spi_bmi088"`). Robot modules reference these names in their YAML configurations via fields like `can_bus_name`, `uart_name`, etc.

To add a new peripheral:
1. Instantiate the LibXR wrapper (e.g., `STM32CAN`, `STM32UART`) in `app_main.cpp`
2. Register it with `LibXR::Entry` using a logical name
3. Reference the logical name in module YAML configs

### YAML-Based Module System

Robot behavior is configured via YAML files that instantiate modules:

```yaml
modules:
- id: motor_yaw                    # Instance ID (referenced as @&motor_yaw)
  name: RMMotor                    # Module class name
  constructor_args:                # Maps to C++ constructor params
    param:
      model: RMMotor::Model::MOTOR_GM6020
      feedback_id: 522
      can_bus_name: can1           # Matches HardwareContainer string name
  template_args:                   # Optional C++ template parameters
    ChassisType: Helm
```

- `@&id`: Pointer to previously constructed module instance
- `@id`: Reference to instance
- `@nullptr`: Null pointer

## Naming Conventions

**Enforced by `.clangd` + Clang-Tidy:**

- Variables / globals: `lower_case`
- Class private/protected members: `lower_case_` (trailing underscore)
- Classes / structs / enums: `CamelCase`
- Class methods: `CamelCase`
- Free functions: `lower_case`
- **Constants (any scope)**: `UPPER_CASE` (const/constexpr, hard constraint)
- Enum constants / macros: `UPPER_CASE`
- File names: `PascalCase.hpp` for modules; `snake_case.yaml` for configs

## Build Settings

- **Standards**: C11, C++20
- **Compiler flags**: `-Werror` globally
- **Optimization**: Debug builds use `-Og` for app code, `-O2` for libraries
- **Target**: Cortex-M4 with FPv4-SP
- **C++ features**: No RTTI (`-fno-rtti`), no exceptions (`-fno-exceptions`)
- **Linker**: Enables `_printf_float` for floating-point printf support

## Critical Rules

### DO NOT:
- Edit `Core/Src/*.c` files outside `/* USER CODE BEGIN */` / `/* USER CODE END */` blocks
- Modify anything in `Drivers/` or `Middlewares/Third_Party/` (vendor code)
- Edit `User/xrobot_main.hpp` manually (auto-generated)
- Edit `User/flash_map.hpp` manually (auto-generated)
- Use Legacy HAL APIs from `Drivers/STM32F4xx_HAL_Driver/Inc/Legacy/`
- Add `#pragma` diagnostic suppressions in application code
- Commit `build/` artifacts
- Mix generated-file edits with functional changes in one commit
- Format code outside `Modules/` directory

### Memory Model
LibXR uses "allocate at init, never free" pattern. This is intentional for embedded real-time systems.

## CI Pipeline

- **Workflow**: `.github/workflows/xrobot_stm32.yml`
- **Container**: `ghcr.io/xrobot-org/docker-image-stm32:main`
- **Builds**: 6 robot configs (aerial, dart, helm_infantry, omni_infantry, radar, wheel_leg)
- **Gate**: All configs must compile cleanly with `-Werror`

## Module Development

When adding a new robot module:
1. Create `Modules/<Name>/` directory
2. Add module header (`.hpp`) and optionally debug commands (`*Debug.inl`)
3. Create `CMakeLists.txt` to register with build system
4. Register in `Modules/modules.yaml` with org/name@branch
5. Module class should inherit from LibXR `ApplicationBase` or similar
6. Add MANIFEST metadata for xrobot discovery

Modules are often standalone git repositories. Changes should be pushed to the module's own repo, then update the branch reference in `modules.yaml`.

## Environment Variables

For local builds, set toolchain paths:

**Linux/macOS**:
```bash
export GCC_TOOLCHAIN_ROOT=/opt/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin
export CLANG_GCC_CMSIS_COMPILER=/opt/st-arm-clang
```

**Windows**:
```powershell
$env:GCC_TOOLCHAIN_ROOT = "C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\gnu-tools-for-stm32\${version}\bin"
$env:CLANG_GCC_CMSIS_COMPILER = "C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\st-arm-clang\${version}"
```

## Dependencies

Required in PATH:
- `xrobot_gen_main`
- `cube-cmake`
- `clang-format` (version 21.1.8 specifically)

Required Python packages:
- `libxr`
- `xrobot`
