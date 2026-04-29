# Modules — Robot Functional Components

## OVERVIEW

YAML-driven robot modules managed by xrobot. Each folder is an independent component (often its own git repo) providing sensor, actuator, or control logic.

## STRUCTURE

```
Modules/
├── modules.yaml        # Module registry: org/name@branch for each module
├── sources.yaml        # Remote index URLs (xrobot-org, qdu-future)
├── CMakeLists.txt      # Auto-includes all */CMakeLists.txt
├── Chassis/            # Omni, Mecanum, Helm chassis types (templated)
├── Gimbal/             # 2-axis gimbal control (pitch/yaw)
├── Launcher/           # Infantry/Hero launcher variants
├── BMI088/             # IMU driver + temperature PID
├── DR16/               # DJI remote control receiver
├── CMD/                # Command routing (operator/auto mode switching)
├── RMMotor/            # DJI RoboMaster motor protocol (M3508, GM6020, M2006)
├── DMMotor/            # DM motor protocol
├── Motor/              # Generic motor base
├── MadgwickAHRS/       # Attitude estimation (quaternion/euler)
├── EventBinder/        # Declarative event wiring between modules
├── SharedTopic/        # Inter-device pub/sub over UART
├── SharedTopicClient/  # Client-side shared topic
├── HostData/           # Host computer data interface
├── PowerControl/       # Power management with supercapacitor
├── SuperPower/         # Supercapacitor CAN driver
├── BlinkLED/           # Status LED blinker
├── BuzzerAlarm/        # Buzzer notification
├── Matrix/             # Matrix math utilities
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add new module | Create `Modules/<Name>/` with `.hpp` + `CMakeLists.txt` | Register in `modules.yaml` |
| Download modules from registry | `xrobot_init_mod --config <url> --dir ./Modules` | Uses `sources.yaml` indexes |
| Understand module wiring | `User/RobotConfig/*.yaml` | `@&id` references link modules |
| Chassis type selection | `Chassis/Omni.hpp`, `Helm.hpp`, `Mecanum.hpp` | Selected via `template_args.ChassisType` in YAML |
| Launcher type selection | `Launcher/InfantryLauncher.hpp`, `HeroLauncher.hpp` | Selected via `template_args.LauncherType` |

## CONVENTIONS

- Each module is a **standalone git repo** cloned into `Modules/`; has its own `.git/`
- Header-only preferred (`.hpp`); some have `*Debug.inl` for debug terminal commands
- Module pattern: class inheriting from LibXR `ApplicationBase` or similar, with `MANIFEST` metadata
- `CMakeLists.txt` per module registers sources with the build system
- YAML constructor args map 1:1 to C++ constructor parameters
- `@&id` in YAML = pointer to previously constructed module instance
- `@id` = reference; `@nullptr` = null pointer

## ANTI-PATTERNS

- **DO NOT** modify modules without understanding they may be shared across repos
- **DO NOT** break the YAML-to-constructor-args contract (parameter names must match)
- **DO NOT** add files outside the module's own directory (keep modules self-contained)
- `clang-format` scope is **only** `Modules/` — this is the formatting boundary
- Upstream changes: push to the module's own repo, then update `modules.yaml` branch reference

## MODULE SOURCES

```yaml
# modules.yaml — two registries
sources:
  - xrobot-org (official): BlinkLED, MadgwickAHRS, BuzzerAlarm, SharedTopic*
  - qdu-future (team): BMI088, CMD, DR16, RMMotor, DMMotor, Chassis, Gimbal, Launcher, etc.
```
