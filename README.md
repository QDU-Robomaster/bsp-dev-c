# bsp-dev-c

RoboMaster 开发板 C 型（STM32F407IGHx）的 LibXR / XRobot BSP，基于 FreeRTOS。同一个固件工程通过不同的应用配置构建各兵种。

## 目录

```text
DevC.ioc                  CubeMX 工程
Core/ Drivers/            CubeMX 生成的初始化代码与 ST HAL / CMSIS
Middlewares/              FreeRTOS、ST USB Device 库、LibXR submodule
Modules/modules.yaml      需要的模块（`xrobot:` 固定 XRobot 版本）
Modules/sources.yaml      模块源
xrobot.lock               模块的精确 commit
User/app_main.cpp         入口：由代码生成器生成，注册硬件并调用 XROBOT_MAIN()
User/libxr_config.yaml    LibXR 外设参数（`generator:` 固定代码生成器版本）
User/xrobot.yaml          默认产品配置（只有 BlinkLED）
User/RobotConfig/*.yaml   各兵种的产品配置
tools/                    格式化与调试脚本
```

`Modules/<owner>/<Repo>/`、`Modules/CMakeLists.txt` 和 `User/xrobot_main.hpp` 由 `xrobot` 生成，不提交。

## 准备

```bash
git clone --recursive https://github.com/QDU-Robomaster/bsp-dev-c.git
cd bsp-dev-c
pip install xrobot==1.0.0 libxr==6.0.0   # 与 xrobot: 和 generator: 一致
xrobot setup                             # 拉取模块、检查所有配置、生成入口头文件
```

已克隆的仓库先运行 `git submodule update --init --recursive`。

构建需要 CMake、Ninja 和 ST 的 `starm-clang` 工具链（STM32CubeCLT 或 VS Code STM32Cube 扩展提供），`starm-clang` 须在 `PATH` 中。Preset 使用 `cmake/starm-clang.cmake`（picolibc 配置）；也可以用 `-DCMAKE_TOOLCHAIN_FILE=cmake/gcc-arm-none-eabi.cmake` 改用 `arm-none-eabi-gcc`。环境变量 `GCC_TOOLCHAIN_ROOT` 和 `CLANG_GCC_CMSIS_COMPILER` 只在把 `STARM_TOOLCHAIN_CONFIG` 改为 `STARM_HYBRID` 时使用。

## 选择产品并构建

```bash
xrobot gen -c User/RobotConfig/hero.yaml   # 切换产品；默认是 User/xrobot.yaml
cmake --preset debug
cmake --build --preset debug
```

Preset 有 `debug`、`relWithDebInfo`、`release`、`minSizeRel`，输出在 `build/<preset>/DevC.elf`。构建前 LibXR 检查配置、锁文件、模块头文件和入口源文件中的注册在生成 `User/xrobot_main.hpp` 之后是否有改动，有改动时构建失败并提示对应的 `xrobot gen -c <配置>`。

产品配置：`User/xrobot.yaml`，以及 `User/RobotConfig/` 下的 `aerial`、`dart`、`helm_infantry`、`hero`、`omni_infantry_3`、`omni_infantry_4`、`radar`、`sentry`、`wheel_leg`。配置里的硬件名是 `User/app_main.cpp` 中 `XR_REGISTER` 注册的对象名（如 `can1`、`usart3`、`spi1`、`LED_B`）。

## 修改 CubeMX 配置后

在 CubeMX 中生成代码后，重新生成 BSP 对象：

```bash
libxr stm32 setup
```

`libxr stm32 setup` 沿用 `User/app_main.cpp` 中的 XRobot 选择和现有的 LibXR 检出，`User Code` 区域的内容保留，`cmake/LibXR.CMake` 随之更新。提交 `User/app_main.cpp`、`User/app_main.h`、`User/flash_map.hpp` 和 `User/libxr_config.yaml`；CI 用 `libxr parse` 和 `libxr gen` 重新生成并检查它们与提交一致。

## CI

`.github/workflows/xrobot_stm32.yml` 在 `ghcr.io/xrobot-org/docker-image-stm32:main` 中：安装固定版本的工具，重新生成并检查 BSP 对象，运行 `xrobot format --check` 和 `xrobot setup --frozen --context-ref <被构建的分支> --release-ref <目标分支>`，然后为每个产品配置构建一次固件。发布 Release 或推送 `v*` 标签时上传各产品的固件。

分支：`dev` 接收修改；`master` 只通过从 `dev` 发起的 PR 更新。目标为 `dev` 时锁定的模块提交必须在模块的 `dev` 上，目标为 `master` 或标签时必须在模块的 `master` 上。

## FreeRTOS 堆位置

`ucHeap` 是放在专用 `.ccm_heap` 段中的分配器原始存储。仓库中的 `STM32F407xx_FLASH.ld` 把该段标为 `NOLOAD`，在 CCM RAM 中保留 64 KiB，而不在 Flash 中生成多余的初始化镜像。普通的 `.ccmram` 仍然可加载，用于显式初始化的数据。分配器元数据单独初始化；堆容量和任务栈设置不变。

替换或重新生成链接脚本时保留 `.ccm_heap` 段。堆的声明位于 CubeMX 保留的用户 Variables 区域中；重新生成的链接脚本必须和该声明一起检查，把它当作孤立段处理会破坏测得的内存布局。

## 许可

本仓库以 Apache-2.0 发布，见 [LICENSE](LICENSE)。随仓库分发的第三方代码保留各自的许可，见 [NOTICE](NOTICE)。
