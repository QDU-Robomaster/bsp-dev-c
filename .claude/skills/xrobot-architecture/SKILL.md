---
name: xrobot-architecture
description: This skill should be used when working on XRobot / LibXR related projects, especially when the repository contains directories like Middlewares, Modules, libxr, User, driver, system, USB, or files like xrobot.yaml, modules.yaml, sources.yaml, CMakeLists.txt, libxr_config.yaml. Covers project type classification (XRobot workspace, LibXR platform, driver/XRUSB, CodeGen), documentation entry points, build workflow, hardware abstraction, and problem-solving approaches for various platforms (STM32, CH32, ESP32, Linux, Webots, HPM, MSPM0).
version: 1.0.0
---

# XRobot / LibXR 架构指南

XRobot / LibXR 相关项目的架构和工作流程。

## 重要提示

你正在协助的是 XRobot / LibXR 相关仓库。这里的仓库不一定是 STM32 工程，也不一定是 XRobot workspace；它也可能是 CH32、ESP32、Linux、Webots、HPM、MSPM0 平台工程，或者驱动、XRUSB、调试、CodeGen、示例与测试仓库。

**开始分析前，先根据当前仓库的目录和关键文件判断它属于哪一类，再进入对应文档和代码入口。**

## 项目分类

- **LibXR**：运行时框架，负责核心语义、驱动抽象、中间件和 XRUSB
- **XRobot**：工程工作流工具，负责模块仓库、工作区组织和项目初始化
- **CodeGen**：代码生成工具，负责根据配置生成工程入口和相关代码

## 使用原则

- 这是 XRobot / LibXR 专用助手提示词，不是通用嵌入式模板
- 不要在看目录之前就默认它是 STM32、ESP32、Linux，或者默认它一定要先跑 XRobot 命令
- 先判断仓库角色，再决定看哪份文档、读哪部分代码、执行哪类命令

## 工程类型判断

### 第一步先看什么
- 先检查仓库根目录与关键配置文件，确认它更像工作区、平台工程、驱动仓库，还是工具仓库
- **XRobot workspace 常见痕迹**：`Modules/`、`User/`、`modules.yaml`、`sources.yaml`、`xrobot.yaml`
- **LibXR 平台工程常见痕迹**：`CMakeLists.txt`、`CMakePresets.json`、`libxr_config.yaml`、平台目录、芯片配置文件、板级实现目录
- **平台或 SDK 线索**：`.ioc`、CubeMX 工程、`idf.py`、`platformio.ini`、Linux / Webots 目录、厂商 SDK 目录
- **驱动/XRUSB/调试工程**：重点文件集中在 `driver`、`system`、`USB`、`DAP`、`Debug`、协议栈或设备枚举实现

### 分类规则
- 如果当前仓库有 `Modules/`、`User/`、`xrobot.yaml` 等文件，按 **XRobot workspace** 处理
- 如果当前仓库主要围绕 LibXR 集成、平台工程、芯片/板级配置、驱动实现展开，按 **LibXR 平台工程** 处理
- 如果当前仓库重点是设备接口、协议栈、调试链路、USB/CAN/UART 等实现，按 **驱动 / XRUSB 工程** 处理
- 如果当前仓库主要是代码生成、模板、示例、测试或基准，按 **工具 / 示例仓库** 处理
- 如果仓库里同时存在多类入口，先说明看到的证据，再决定主入口

## 文档入口

- **总入口**：https://xrobot-org.github.io/docs/intro
- **设计思想**：https://xrobot-org.github.io/docs/concept
- **环境配置**：https://xrobot-org.github.io/docs/env_setup
- **基础编程**：https://xrobot-org.github.io/docs/basic_coding
- **项目管理（XRobot）**：https://xrobot-org.github.io/docs/proj_man
- **XRUSB**：https://xrobot-org.github.io/docs/xrusb
- **调试**：https://xrobot-org.github.io/docs/debug
- **新手任务引导**：https://xrobot-org.github.io/XRobot-Onboarding/

## 入口选择规则

- 只有确认是 **XRobot workspace** 时，才优先看 `proj_man`、`xrobot_setup`、`Modules/`、`User/`
- 如果是 **LibXR 平台工程**，优先看 `env_setup`、`concept`、`basic_coding`，再按实际平台进入对应环境页
- 如果是驱动或设备接口问题，再转去 `xrusb`、`debug`、`basic_coding/driver`
- 如果是中间件、消息系统、调度、Topic 等运行时机制问题，优先看 `basic_coding` 下对应章节
- 如果当前仓库只是某个平台或某个芯片工程，不要把它强行解释成 XRobot workspace

---

## XRobot Workspace 架构（当项目是 XRobot workspace 时适用）

以下内容适用于确认为 XRobot workspace 的项目（例如 bsp-dev-c）。

## 项目定位

**当确认为 XRobot workspace 时，参考以下架构。**

以 STM32F407 RoboMaster BSP 为例：

**关键特征：**
- STM32F407IGHx MCU
- LibXR 运行时框架 + FreeRTOS
- xrobot YAML 驱动的模块化系统
- 支持多种 RoboMaster 机器人配置：哨兵、英雄、步兵（全向/舵轮）、空中、飞镖、雷达、轮腿

## 目录结构与职责

### Core/ - HAL 初始化层
- STM32CubeMX 自动生成
- **只读区域**：除了 `/* USER CODE BEGIN/END */` 标记之间的代码
- 包含：HAL_Init, 时钟配置, 外设初始化 (MX_*_Init)

### Drivers/ - 供应商库
- STM32 HAL + CMSIS
- **完全只读**，不要修改任何文件

### Middlewares/ - 中间件
- `Third_Party/LibXR/`：LibXR 框架子模块（有自己的 AGENTS.md）
- `ST/`：STMicroelectronics 官方中间件
- **完全只读**

### Modules/ - 机器人功能模块
- 每个目录是一个功能组件（通常是独立的 git 仓库）
- 包含：底盘、云台、发射机构、电机驱动、传感器等
- **这是唯一需要 clang-format 的目录**
- 模块通过 `xrobot_init_mod` 从远程注册表下载
- 关键文件：
  - `modules.yaml`：模块注册表（org/name@branch）
  - `sources.yaml`：远程索引 URL

**常见模块：**
- `Chassis/`：全向、麦轮、舵轮底盘（模板化）
- `Gimbal/`：二轴云台控制
- `RMMotor/`：大疆电机协议（M3508, GM6020, M2006）
- `DMMotor/`：DM 电机协议
- `BMI088/`：IMU 驱动 + 温度 PID
- `DR16/`：遥控器接收器
- `CMD/`：命令路由（手动/自动模式切换）
- `MadgwickAHRS/`：姿态估计
- `SharedTopic/`：设备间发布订阅

### User/ - 应用层
- `app_main.cpp`：C++ 入口点
  - 硬件外设实例化
  - `HardwareContainer` 字符串名称注册
  - 串口/USB 终端设置
  - Flash 数据库初始化
- `app_main.h`：C 链接头文件
- `xrobot_main.hpp`：**自动生成** - 从 YAML 实例化模块
- `xrobot.yaml`：默认机器人配置
- `libxr_config.yaml`：LibXR 框架设置
- `flash_map.hpp`：**自动生成** - Flash 扇区表
- `RobotConfig/`：机器人特定的 YAML 预设

### cmake/ - 构建配置
- `starm-clang.cmake`：ST ARM Clang 工具链
- `stm32cubemx/`：CubeMX CMake 集成
- `LibXR.CMake`：LibXR 集成脚本

### tools/ - 构建脚本
- `build.sh`：完整构建流水线（格式化 + 生成 + 编译）
- `format_code.sh`：clang-format 驱动
- `ozone_openocd_launcher.sh`：调试启动器

## 执行流程

```
启动序列：
  startup_stm32f407xx.s: Reset_Handler
    ↓
  Core/Src/main.c: main()
    - HAL_Init()
    - SystemClock_Config()
    - MX_GPIO_Init(), MX_CAN1_Init(), ...
    - osKernelStart()
      ↓
  StartDefaultTask()
    ↓
  User/app_main.cpp: app_main()
    - 平台初始化
    - 硬件对象创建（STM32CAN, STM32UART, ...）
    - HardwareContainer 注册（"can1", "uart_dr16", ...）
    - 终端设置（USB CDC）
    - 数据库设置（Flash 持久化）
      ↓
  User/xrobot_main.hpp: XRobotMain(peripherals)
    - 从 YAML 实例化模块
    - 模块间连接（@&id 引用）
    - appmgr.MonitorAll() 主循环
```

## 硬件抽象层

### HardwareContainer 模式
- 字符串名称 → 硬件对象映射
- 在 `app_main.cpp` 中注册：
  ```cpp
  LibXR::Entry(libxr, "can1", can1);
  LibXR::Entry(libxr, "uart_dr16", uart_dr16);
  LibXR::Entry(libxr, "spi_bmi088", spi_bmi088);
  ```

### YAML 中引用硬件
```yaml
constructor_args:
  param:
    can_bus_name: can1        # 引用 HardwareContainer 中的 "can1"
    uart_name: uart_dr16      # 引用 "uart_dr16"
```

### 添加新外设流程
1. 在 `app_main.cpp` 中实例化 LibXR 包装器（例：`STM32CAN`, `STM32UART`）
2. 用 `LibXR::Entry` 注册逻辑名称
3. 在模块 YAML 配置中通过字段引用（`can_bus_name`, `uart_name` 等）

## YAML 模块系统

### 基本语法
```yaml
modules:
- id: motor_yaw                    # 实例 ID
  name: RMMotor                    # 模块类名
  constructor_args:                # 构造函数参数（映射到 C++）
    param:
      model: RMMotor::Model::MOTOR_GM6020
      feedback_id: 522
      can_bus_name: can1
  template_args:                   # C++ 模板参数
    ChassisType: Helm

- id: chassis
  name: Chassis
  constructor_args:
    param:
      motors: [@&motor_fl, @&motor_fr, @&motor_bl, @&motor_br]  # 指针数组
```

### 引用语法
- `@&id`：指向前面定义的模块实例的指针
- `@id`：引用实例
- `@nullptr`：空指针

### 约束
- 构造函数参数名必须与 C++ 完全匹配
- 模板参数必须是有效的 C++ 类型名
- 硬件名称必须在 `HardwareContainer` 中存在

## 构建工作流

### 完整流水线
```bash
tools/build.sh -c User/RobotConfig/omni_infantry_3.yaml -b build/debug
```

**步骤：**
1. clang-format 格式化 `Modules/` 下的代码
2. `xrobot_gen_main` 从 YAML 生成 `xrobot_main.hpp`
3. `cube-cmake` 配置固件
4. `cube-cmake` 构建固件

### 快速迭代（跳过格式化）
```bash
tools/build.sh --skip-format -c User/xrobot.yaml -b build/debug
```

### 单独步骤

**格式化：**
```bash
tools/format_code.sh
```

**生成代码：**
```bash
xr_cubemx_cfg -d ./ --xrobot
xrobot_setup
```

**CMake 配置：**
```bash
cmake . -DCMAKE_TOOLCHAIN_FILE:STRING=cmake/starm-clang.cmake \
  -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE -Bbuild -G Ninja
```

**编译：**
```bash
cmake --build build
```

## 问题诊断流程

### 构建失败
1. **检查环境变量**：根据平台不同，可能需要 `GCC_TOOLCHAIN_ROOT`, `CLANG_GCC_CMSIS_COMPILER` 等
2. **检查 PATH**：确认需要的工具可访问（如 `xrobot_gen_main`, `cube-cmake`, `idf.py` 等）
3. **检查子模块**：`git submodule update --init --recursive`
4. **检查依赖包**：根据平台安装相应的 Python 包（如 `pip install libxr xrobot`）

### 链接错误
1. 检查 `modules.yaml` 中的模块是否已下载
2. 运行 `xrobot_init_mod` 获取缺失的模块（如果是 XRobot workspace）
3. 检查 `CMakeLists.txt` 是否包含模块

### YAML 配置错误（XRobot workspace）
1. 验证硬件名称在对应的硬件注册文件中存在
2. 检查构造函数参数名拼写
3. 确认 `@&id` 引用的实例已在前面定义
4. 检查模板参数是否为有效的 C++ 类型

### 运行时错误
1. 检查平台配置（如 CubeMX 的 `.ioc`、ESP-IDF 的 `sdkconfig`）
2. 验证时钟配置
3. 检查 DMA 缓冲区大小
4. 使用调试接口查看日志（UART、USB CDC、网络等）

## 遇到问题时的处理流程

1. **先确认问题属于哪一层**：环境、工程工作流、运行时语义、驱动/XRUSB
2. **先打开对应的文档链接**，不要脱离文档自行猜测接口或目录结构
3. **如果文档里没有**，再结合当前仓库代码和命令输出继续判断
4. **如果仍然解决不了**，整理最小问题描述、命令输出和环境信息后提问

### 需要进一步求助时

- 补充当前平台、目标芯片/系统、使用的命令、报错原文
- 如果是 **XRobot workspace 问题**，优先附上 `Modules/` 和 `User/` 下相关文件状态
- 如果是 **LibXR 平台工程问题**，优先附上 `CMakeLists.txt`、`CMakePresets.json`、平台配置文件、`libxr_config.yaml` 等文件状态
- 如果是 **驱动、XRUSB、调试或运行时问题**，优先附上相关源码位置、最小复现代码和日志

## 模块开发

### 创建新模块
1. 在 `Modules/<Name>/` 创建目录
2. 添加 `<Name>.hpp` 主头文件
3. 创建 `CMakeLists.txt` 注册源文件
4. （可选）添加 `<Name>Debug.inl` 用于终端命令
5. 在 `Modules/modules.yaml` 中注册

### 模块模式
```cpp
class MyModule : public LibXR::ApplicationBase {
 public:
  struct Param {
    // 构造函数参数（映射到 YAML）
  };

  MyModule(Param& param) { /* ... */ }
  
  void Update() { /* 周期性调用 */ }
};
```

### 模块注册
```yaml
# Modules/modules.yaml
sources:
  - name: xrobot-org
    url: https://...
  - name: qdu-future
    url: https://...

modules:
  - org: qdu-future
    name: MyModule
    branch: main
```

## CI/CD

### GitHub Actions
- **工作流**：`.github/workflows/xrobot_stm32.yml`
- **触发**：推送到 `main`/`master`，PR，发布
- **容器**：`ghcr.io/xrobot-org/docker-image-stm32:main`
- **构建目标**：6 个机器人配置
- **通过标准**：所有配置必须在 `-Werror` 下干净编译

## 文档资源

- LibXR 文档：https://xrobot-org.github.io/docs/intro
- 设计概念：https://xrobot-org.github.io/docs/concept
- 环境配置：https://xrobot-org.github.io/docs/env_setup
- 基础编程：https://xrobot-org.github.io/docs/basic_coding
- 项目管理：https://xrobot-org.github.io/docs/proj_man
- XRUSB：https://xrobot-org.github.io/docs/xrusb
- 调试：https://xrobot-org.github.io/docs/debug

## 关键原则

1. **先判断再行动**：了解当前仓库属于哪一类（XRobot workspace / LibXR 平台 / 驱动 / 工具）
2. **尊重边界**：不修改生成的代码、供应商代码、只读区域
3. **遵循约定**：命名、格式化、文件组织都有规则（参考项目的 CLAUDE.md 或 AGENTS.md）
4. **理解流程**：从硬件初始化到模块实例化到运行时循环（如果是 XRobot workspace）
5. **查阅文档**：遇到 LibXR/XRobot 概念时先看官方文档，不要凭空猜测
