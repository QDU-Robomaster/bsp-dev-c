---
name: cpp-coding-style
description: This skill should be used when writing, reviewing, editing, or refactoring C/C++ source code (.cpp, .hpp, .h, .c files). Applies naming conventions (CamelCase, lower_case, UPPER_CASE), clang-format configuration, and coding standards for embedded development projects.
version: 1.0.0
---

# C++ 编码规范

本项目统一的 C++ 代码风格指南。

## 命名规范

**严格执行（由 `.clangd` + Clang-Tidy 强制检查）：**

- **类型、类、结构体、枚举类型**：`CamelCase`
  - 例：`RMMotor`, `ChassisType`, `ApplicationBase`
- **类方法**：`CamelCase`
  - 例：`GetPosition()`, `SetVelocity()`, `MonitorAll()`
- **自由函数**：`lower_case`
  - 例：`app_main()`, `create_hex_output()`
- **变量、全局变量、函数参数**：`lower_case`
  - 例：`motor_yaw`, `can_bus_name`, `feedback_id`
- **类私有/保护成员**：`lower_case_`（尾部下划线）
  - 例：`velocity_`, `position_`, `last_update_time_`
- **所有常量（任何作用域）**：`UPPER_CASE`（硬性约束）
  - `const` / `constexpr` 常量必须全大写
  - 例：`MAX_VELOCITY`, `PI`, `BUFFER_SIZE`
- **枚举常量 / 宏**：`UPPER_CASE`
  - 例：`MOTOR_GM6020`, `GPIO_PIN_SET`
- **文件名**：
  - 模块头文件：`PascalCase.hpp`（例：`RMMotor.hpp`, `Chassis.hpp`）
  - 机器人配置：`snake_case.yaml`（例：`omni_infantry.yaml`, `sentry.yaml`）

## 文件组织

### 头文件保护
- 统一使用 `#pragma once`，不使用传统的 include guards

### Include 顺序
- `.cpp` 文件：
  1. 首先包含对应的头文件
  2. 然后是 LibXR 框架头文件
  3. 最后是 STM32 HAL 头文件
- 头文件中的 include 保持现有顺序，不做无关重排
- 遵循 `.clang-format` 的 `IncludeBlocks: Regroup` 配置

### 用户代码区域
- `Core/Src/*.c` 文件只能在以下区域编辑：
  ```c
  /* USER CODE BEGIN */
  // 你的代码
  /* USER CODE END */
  ```
- **绝对禁止**在这些标记之外修改 CubeMX 生成的代码

## 格式化

### clang-format 配置
- **版本要求**：`clang-format 21.1.8`（必须严格匹配）
- **基准风格**：Google style
- **列宽**：`ColumnLimit` 由 `.clang-format` 控制
- **格式化范围**：**仅** `Modules/` 目录
  - **不要**格式化 `Core/`, `Drivers/`, `Middlewares/` 下的代码

### 格式化命令
```bash
# 应用格式化
tools/format_code.sh

# 检查格式（CI 模式）
tools/format_code.sh --check
```

### 安装 clang-format
```bash
python3 -m venv .venv-clang-format
.venv-clang-format/bin/pip install "clang-format==21.1.8"
```

## 大括号与缩进

- **大括号风格**：遵循 `.clang-format` 配置（Google style）
- **访问说明符**：不额外缩进
- **类成员**：相对类体缩进
- **允许**为可读性保留现有空行和局部排版

## 注释

### Doxygen 风格
- 公共接口使用 Doxygen 注释
- 说明接口语义、参数、返回值、边界条件
- **不**记录试错过程，**不**写过程化说明

### 注释语言
- 项目中中英文注释都可接受
- 新增代码时，沿用所在文件的现有风格

### 简短注释
- 简单局部说明使用短行注释
- 避免口语化句子

## 声明与定义

### 函数定义
- 简短函数允许类内一行定义
- 较长函数保持正常展开

### 常量与静态成员
- `constexpr`、`static constexpr`、`static inline` 按现有习惯使用
- 所有常量必须使用 `UPPER_CASE` 命名

### 指针与引用
- 空格风格以局部文件现有写法为准
- 项目中同时存在 `const char*` 和 `const char *`
- **不要**为了统一这一点扩大改动范围

## 宏与特殊标记

### NOLINT 标记
- `NOLINT` 只压在具体位置
- **不要**整段铺开
- 仅在必要时使用（例如：硬件寄存器访问、DMA 缓冲区）

### 条件编译
- 保持直接展开，不额外包装
- `extern "C"` 保持现有直接写法

### 平台宏
- 保持 HAL 层宏的原始风格
- 不要添加 `#pragma` diagnostic 抑制在应用代码中

## 模块特定规则

### Modules/ 目录
- 每个模块是独立的功能组件（通常是独立 git 仓库）
- 头文件优先（`.hpp`），部分模块有 `*Debug.inl` 用于调试终端命令
- `CMakeLists.txt` 注册模块到构建系统
- 类应继承 LibXR 的 `ApplicationBase` 或类似基类
- 添加 `MANIFEST` 元数据供 xrobot 发现

### YAML 配置
- 文件名使用 `snake_case`
- 构造函数参数名必须与 C++ 构造函数参数完全匹配
- 使用 `@&id` 定义实例指针，`@id` 引用实例，`@nullptr` 表示空指针

### User/ 目录
- `app_main.cpp`：硬件外设实例化和 `HardwareContainer` 注册
  - 允许 `NOLINTBEGIN`/`NOLINTEND` 和 `clang-format off/on` 区域
- `xrobot_main.hpp`：**自动生成，禁止手动编辑**
- `flash_map.hpp`：**自动生成，禁止手动编辑**
- `RobotConfig/*.yaml`：机器人特定配置文件

## 禁止操作

**绝对不要：**
1. 在 `/* USER CODE BEGIN/END */` 之外编辑 `Core/Src/*.c` 文件
2. 修改 `Drivers/` 或 `Middlewares/Third_Party/` 下的任何内容（只读供应商代码）
3. 手动编辑 `User/xrobot_main.hpp`（xrobot 自动生成）
4. 手动编辑 `User/flash_map.hpp`（自动生成）
5. 使用 `Drivers/STM32F4xx_HAL_Driver/Inc/Legacy/` 下的遗留 HAL API
6. 在应用代码中添加 `#pragma` diagnostic 抑制
7. 提交 `build/` 目录下的构建产物
8. 在单次提交中混合生成文件修改和功能修改
9. 格式化 `Modules/` 之外的代码

## 构建与验证

### 编译设置
- **标准**：C11, C++20
- **全局标志**：`-Werror`（所有警告视为错误）
- **优化**：Debug 模式应用代码 `-Og`，库代码 `-O2`
- **目标**：Cortex-M4 with FPv4-SP
- **C++ 特性**：`-fno-rtti -fno-exceptions`

### 验证流程
1. 格式化检查：`tools/format_code.sh --check`
2. 生成代码：`xr_cubemx_cfg -d ./ --xrobot && xrobot_setup`
3. 编译：`tools/build.sh -c User/xrobot.yaml -b build/debug`
4. 所有配置必须无警告通过 `-Werror` 检查

## 内存模型

- LibXR 使用"初始化时分配，永不释放"模式
- 这是嵌入式实时系统的**有意设计**，不是内存泄漏
- 所有对象在启动时分配，运行期间不进行动态内存管理

## 提交规范

- 简短的祈使句主题（中文或英文均可）
- 每次提交一个逻辑修改
- 不要将格式化改动与功能改动混在一起
