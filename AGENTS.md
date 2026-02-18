# Repository Guidelines

## Project Structure & Module Organization
- `Core/` contains STM32CubeMX-generated startup and HAL integration code (`Inc/`, `Src/`).
- `Drivers/` and `Middlewares/` hold vendor code (STM32 HAL, CMSIS, FreeRTOS, LibXR dependencies); treat as external unless intentionally upgrading.
- `Modules/` contains functional robot modules (for example `Chassis`, `Gimbal`, `DR16`), mostly as submodule-backed components.
- `User/` is the application layer: `app_main.cpp`, `xrobot.yaml`, and robot presets in `User/RobotConfig/*.yaml`.
- `cmake/` stores toolchain and project CMake includes; `tools/` stores developer scripts. Build artifacts belong in `build/` and must stay uncommitted.

## Build, Test, and Development Commands
- Initialize dependencies: `git submodule update --init --recursive`
- Install tooling: `pip install libxr xrobot`
- Generate xrobot sources: `xr_cubemx_cfg -d ./ --xrobot && xrobot_setup`
- Configure/build (preset): `cmake --preset debug && cmake --build --preset debug`
- Configure/build (explicit): `cmake . -Bbuild -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/starm-clang.cmake && cmake --build build`
- Build a specific robot config: `xrobot_gen_main --config User/RobotConfig/omni_infantry.yaml && cmake --build build`
- Format check/apply: `tools/format_code.sh --check` / `tools/format_code.sh`

## Coding Style & Naming Conventions
- C/C++ formatting follows `.clang-format` (`BasedOnStyle: Google`, `IncludeBlocks: Regroup`).
- Use `clang-format` `21.1.8` (enforced by `tools/format_code.sh`).
- Prefer 4-space indentation and include ordering produced by formatter; do not hand-tune formatting after running it.
- Module/class file names are PascalCase (for example `Modules/Chassis/Chassis.hpp`); robot YAML names are snake_case (for example `helm_infantry.yaml`).

## Testing Guidelines
- There is no standalone unit-test target in this repo; validation is build-based.
- Minimum check before PR: one clean debug build plus affected robot config builds via `xrobot_gen_main`.
- CI (`.github/workflows/xrobot_stm32.yml`) compiles multiple robot configs; local results should match CI steps.

## Commit & Pull Request Guidelines
- Follow existing history style: short, imperative commit subjects (Chinese or English), optionally with issue refs (for example `Fixes #14`).
- Keep commits focused to one logical change; avoid mixing generated files with functional edits.
- PRs should include scope, touched modules/configs, commands executed, and linked issues. Add logs/screenshots when behavior changes depend on hardware validation.
