#include <cstdint>

#include "dfu/dfu.hpp"
#include "flash_map.hpp"
#include "libxr.hpp"
#include "main.h"
#include "stm32_flash.hpp"
#include "stm32_usb_dev.hpp"

extern PCD_HandleTypeDef hpcd_USB_OTG_FS;

namespace
{

constexpr uint32_t RAM_BASE = 0x20000000u;
constexpr uint32_t RAM_END = 0x20020000u;
constexpr uint32_t APP_BASE = 0x08020000u;
constexpr uint32_t APP_SIZE = 0x000A0000u;
constexpr uint32_t APP_SEAL_OFFSET = APP_SIZE - 16u;
constexpr uint32_t APP_FLASH_END = APP_BASE + APP_SEAL_OFFSET;
constexpr size_t APP_START_SECTOR = 6u;

uint8_t ep0_in_buf[8];
uint8_t ep0_out_buf[8];

bool AppVectorIsValid()
{
  const auto stack = *reinterpret_cast<const uint32_t*>(APP_BASE);
  const auto reset = *reinterpret_cast<const uint32_t*>(APP_BASE + 4u);
  return stack >= RAM_BASE && stack <= RAM_END && (stack % 4u) == 0u &&
         reset >= APP_BASE && reset < APP_FLASH_END && (reset & 1u) == 1u;
}

[[noreturn]] void JumpToAppNow()
{
  HAL_PCD_Stop(&hpcd_USB_OTG_FS);
  HAL_PCD_DeInit(&hpcd_USB_OTG_FS);

  HAL_RCC_DeInit();
  HAL_DeInit();

  __disable_irq();
  SysTick->CTRL = 0u;
  SysTick->LOAD = 0u;
  SysTick->VAL = 0u;

  for (uint32_t i = 0u; i < 8u; ++i)
  {
    NVIC->ICER[i] = 0xFFFFFFFFu;
    NVIC->ICPR[i] = 0xFFFFFFFFu;
  }

  __DSB();
  __ISB();
  __set_CONTROL(0u);
  __set_BASEPRI(0u);
  __set_FAULTMASK(0u);
  __ISB();

  SCB->VTOR = APP_BASE;
  __DSB();
  __ISB();
  __enable_irq();

  asm volatile(
      "ldr r0, [%0, #0]    \n"
      "msr msp, r0         \n"
      "isb                 \n"
      "ldr r0, [%0, #4]    \n"
      "bx  r0              \n"
      :
      : "r"(APP_BASE)
      : "r0");

  while (true) {}
}

void JumpToAppThunk(void*)
{
  JumpToAppNow();
}

}  // namespace

extern "C" void app_main(void)
{
  LibXR::PlatformInit();

  LibXR::STM32Flash app_flash(FLASH_SECTORS, FLASH_SECTOR_NUMBER, APP_START_SECTOR);
  LibXR::USB::DfuBootloaderClassT<1024> dfu(
      app_flash, 0, APP_SIZE, APP_SEAL_OFFSET, JumpToAppThunk, nullptr, false,
      "DevC App DFU");

  static constexpr auto lang_pack = LibXR::USB::DescriptorStrings::MakeLanguagePack(
      LibXR::USB::DescriptorStrings::Language::EN_US, "QDU-Future",
      "DevC Bootloader", "QDU-Future-DevC-BL-");

  LibXR::STM32USBDeviceOtgFS usb_fs(
      &hpcd_USB_OTG_FS, 256, {ep0_out_buf}, {{ep0_in_buf, 8}},
      LibXR::USB::DeviceDescriptor::PacketSize0::SIZE_8, 0x16D0, 0x1493, 0xF407,
      {&lang_pack}, {{&dfu}}, {reinterpret_cast<void*>(UID_BASE), 12});

  usb_fs.Init(false);
  usb_fs.Start(false);

  while (true)
  {
    dfu.Process();
    if (dfu.TryConsumeAppLaunch(HAL_GetTick()) && AppVectorIsValid())
    {
      JumpToAppNow();
    }
    HAL_Delay(10);
  }
}
