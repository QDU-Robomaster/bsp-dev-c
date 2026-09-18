# bsp-dev-c

BSP Package for development board C.

## Build in Terminal

### Windows

```bash
git clone https://github.com/QDU-Robomaster/bsp-dev-c
cd bsp-dev-c
git submodule update --init --recursive
pip install libxr xrobot
xr_cubemx_cfg -d ./ -c --xrobot
xrobot_src_man create-sources
xrobot_init_mod --config https://raw.githubusercontent.com/QDU-Robomaster/dev-c-robots/refs/heads/main/test.yaml --dir .\Modules\
xrobot_setup
$env:GCC_TOOLCHAIN_ROOT = "C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\gnu-tools-for-stm32\${版本号}\bin"
$env:CLANG_GCC_CMSIS_COMPILER = "C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\st-arm-clang\${版本号}"
cmake . -DCMAKE_TOOLCHAIN_FILE:STRING=cmake/starm-clang.cmake -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE -Bbuild -G Ninja
cmake --build build
ls build/
```

### Linux

```bash
git clone https://github.com/QDU-Robomaster/bsp-dev-c
cd bsp-dev-c
git submodule update --init --recursive
pip install libxr xrobot
xr_cubemx_cfg -d ./ -c --xrobot
xrobot_src_man create-sources
xrobot_init_mod --config https://raw.githubusercontent.com/QDU-Robomaster/dev-c-robots/refs/heads/main/test.yaml --dir ./Modules
xrobot_setup
export GCC_TOOLCHAIN_ROOT=/opt/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin
export CLANG_GCC_CMSIS_COMPILER=/opt/st-arm-clang
cmake . -DCMAKE_TOOLCHAIN_FILE:STRING=cmake/starm-clang.cmake -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE -Bbuild -G Ninja
cmake --build build
ls build/
```

## FreeRTOS heap placement

`ucHeap` is raw allocator storage in the dedicated `.ccm_heap` section. The tracked
`STM32F407XX_FLASH.ld` marks this section `NOLOAD`, reserving 64 KiB of CCM RAM
without a redundant Flash initialization image. Generic `.ccmram` remains loadable
for explicitly initialized data. The allocator metadata is initialized separately;
heap capacity and task stack settings are unchanged.

Keep the `.ccm_heap` linker block when replacing or regenerating the linker script.
The heap declaration stays inside the CubeMX user-preserved Variables block. A
regenerated linker script must be checked together with the declaration; treating
this as an orphan section would invalidate the measured memory layout.
