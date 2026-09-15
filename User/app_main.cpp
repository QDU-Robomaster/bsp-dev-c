#include "app_main.h"

#include "cdc_uart.hpp"
#include "libxr.hpp"
#include "main.h"
#include "stm32_adc.hpp"
#include "stm32_can.hpp"
#include "stm32_canfd.hpp"
#include "stm32_dac.hpp"
#include "stm32_flash.hpp"
#include "stm32_gpio.hpp"
#include "stm32_i2c.hpp"
#include "stm32_power.hpp"
#include "stm32_pwm.hpp"
#include "stm32_spi.hpp"
#include "stm32_timebase.hpp"
#include "stm32_uart.hpp"
#include "stm32_usb_dev.hpp"
#include "stm32_watchdog.hpp"
#include "flash_map.hpp"
#include "xrobot_main.hpp"

using namespace LibXR;

/* User Code Begin 1 */
/* User Code End 1 */
// NOLINTBEGIN
// clang-format off
/* External HAL Declarations */
extern ADC_HandleTypeDef hadc3;
extern CAN_HandleTypeDef hcan1;
extern CAN_HandleTypeDef hcan2;
extern I2C_HandleTypeDef hi2c1;
extern I2C_HandleTypeDef hi2c3;
extern PCD_HandleTypeDef hpcd_USB_OTG_FS;
extern PCD_HandleTypeDef hpcd_USB_OTG_HS;
extern SPI_HandleTypeDef hspi1;
extern TIM_HandleTypeDef htim10;
extern TIM_HandleTypeDef htim1;
extern TIM_HandleTypeDef htim2;
extern TIM_HandleTypeDef htim3;
extern TIM_HandleTypeDef htim4;
extern TIM_HandleTypeDef htim5;
extern TIM_HandleTypeDef htim7;
extern TIM_HandleTypeDef htim8;
extern UART_HandleTypeDef huart1;
extern UART_HandleTypeDef huart3;
extern UART_HandleTypeDef huart6;

/* DMA Resources */
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint16_t data[64];
} adc3_buf_storage;
static constexpr auto& adc3_buf = adc3_buf_storage.data;
#else
alignas(4) static uint16_t adc3_buf[64];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[32];
} spi1_tx_buf_storage;
static constexpr auto& spi1_tx_buf = spi1_tx_buf_storage.data;
#else
alignas(4) static uint8_t spi1_tx_buf[32];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[32];
} spi1_rx_buf_storage;
static constexpr auto& spi1_rx_buf = spi1_rx_buf_storage.data;
#else
alignas(4) static uint8_t spi1_rx_buf[32];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[128];
} usart1_tx_buf_storage;
static constexpr auto& usart1_tx_buf = usart1_tx_buf_storage.data;
#else
alignas(4) static uint8_t usart1_tx_buf[128];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[128];
} usart1_rx_buf_storage;
static constexpr auto& usart1_rx_buf = usart1_rx_buf_storage.data;
#else
alignas(4) static uint8_t usart1_rx_buf[128];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[128];
} usart3_rx_buf_storage;
static constexpr auto& usart3_rx_buf = usart3_rx_buf_storage.data;
#else
alignas(4) static uint8_t usart3_rx_buf[128];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[512];
} usart6_tx_buf_storage;
static constexpr auto& usart6_tx_buf = usart6_tx_buf_storage.data;
#else
alignas(4) static uint8_t usart6_tx_buf[512];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[512];
} usart6_rx_buf_storage;
static constexpr auto& usart6_rx_buf = usart6_rx_buf_storage.data;
#else
alignas(4) static uint8_t usart6_rx_buf[512];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[32];
} i2c1_buf_storage;
static constexpr auto& i2c1_buf = i2c1_buf_storage.data;
#else
alignas(4) static uint8_t i2c1_buf[32];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[32];
} i2c3_buf_storage;
static constexpr auto& i2c3_buf = i2c3_buf_storage.data;
#else
alignas(4) static uint8_t i2c3_buf[32];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[8];
} usb_otg_hs_ep0_in_buf_storage;
static constexpr auto& usb_otg_hs_ep0_in_buf = usb_otg_hs_ep0_in_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_hs_ep0_in_buf[8];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[8];
} usb_otg_hs_ep0_out_buf_storage;
static constexpr auto& usb_otg_hs_ep0_out_buf = usb_otg_hs_ep0_out_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_hs_ep0_out_buf[8];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[128];
} usb_otg_hs_ep1_in_buf_storage;
static constexpr auto& usb_otg_hs_ep1_in_buf = usb_otg_hs_ep1_in_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_hs_ep1_in_buf[128];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[128];
} usb_otg_hs_ep1_out_buf_storage;
static constexpr auto& usb_otg_hs_ep1_out_buf = usb_otg_hs_ep1_out_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_hs_ep1_out_buf[128];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[16];
} usb_otg_hs_ep2_in_buf_storage;
static constexpr auto& usb_otg_hs_ep2_in_buf = usb_otg_hs_ep2_in_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_hs_ep2_in_buf[16];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[128];
} usb_otg_hs_ep2_out_buf_storage;
static constexpr auto& usb_otg_hs_ep2_out_buf = usb_otg_hs_ep2_out_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_hs_ep2_out_buf[128];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[128];
} usb_otg_hs_ep3_in_buf_storage;
static constexpr auto& usb_otg_hs_ep3_in_buf = usb_otg_hs_ep3_in_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_hs_ep3_in_buf[128];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[16];
} usb_otg_hs_ep4_in_buf_storage;
static constexpr auto& usb_otg_hs_ep4_in_buf = usb_otg_hs_ep4_in_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_hs_ep4_in_buf[16];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[8];
} usb_otg_fs_ep0_in_buf_storage;
static constexpr auto& usb_otg_fs_ep0_in_buf = usb_otg_fs_ep0_in_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_fs_ep0_in_buf[8];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[8];
} usb_otg_fs_ep0_out_buf_storage;
static constexpr auto& usb_otg_fs_ep0_out_buf = usb_otg_fs_ep0_out_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_fs_ep0_out_buf[8];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[128];
} usb_otg_fs_ep1_in_buf_storage;
static constexpr auto& usb_otg_fs_ep1_in_buf = usb_otg_fs_ep1_in_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_fs_ep1_in_buf[128];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[128];
} usb_otg_fs_ep1_out_buf_storage;
static constexpr auto& usb_otg_fs_ep1_out_buf = usb_otg_fs_ep1_out_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_fs_ep1_out_buf[128];
#endif
#if defined(__DCACHE_PRESENT) && (__DCACHE_PRESENT == 1U)
static struct alignas(__SCB_DCACHE_LINE_SIZE)
{
  uint8_t data[16];
} usb_otg_fs_ep2_in_buf_storage;
static constexpr auto& usb_otg_fs_ep2_in_buf = usb_otg_fs_ep2_in_buf_storage.data;
#else
alignas(4) static uint8_t usb_otg_fs_ep2_in_buf[16];
#endif

extern "C" void app_main(void) {
  // clang-format on
  // NOLINTEND
  /* User Code Begin 2 */
  /* User Code End 2 */
  // clang-format off
  // NOLINTBEGIN
  STM32TimerTimebase timebase(&htim2);
  PlatformInit(2, 2048);
  STM32PowerManager power_manager;

  /* GPIO Configuration */
  STM32GPIO USER_KEY(USER_KEY_GPIO_Port, USER_KEY_Pin, EXTI0_IRQn);
  STM32GPIO ACCL_CS(ACCL_CS_GPIO_Port, ACCL_CS_Pin);
  STM32GPIO GYRO_CS(GYRO_CS_GPIO_Port, GYRO_CS_Pin);
  STM32GPIO HW0(HW0_GPIO_Port, HW0_Pin);
  STM32GPIO HW1(HW1_GPIO_Port, HW1_Pin);
  STM32GPIO HW2(HW2_GPIO_Port, HW2_Pin);
  STM32GPIO ACCL_INT(ACCL_INT_GPIO_Port, ACCL_INT_Pin, EXTI4_IRQn);
  STM32GPIO GYRO_INT(GYRO_INT_GPIO_Port, GYRO_INT_Pin, EXTI9_5_IRQn);
  STM32GPIO CAMERA(CAMERA_GPIO_Port, CAMERA_Pin);
  STM32GPIO IMU_INT(IMU_INT_GPIO_Port, IMU_INT_Pin, EXTI1_IRQn);
  STM32GPIO CMPS_INT(CMPS_INT_GPIO_Port, CMPS_INT_Pin, EXTI3_IRQn);
  STM32GPIO CMPS_RST(CMPS_RST_GPIO_Port, CMPS_RST_Pin);
  STM32GPIO LED_B(LED_B_GPIO_Port, LED_B_Pin);
  STM32GPIO LED_G(LED_G_GPIO_Port, LED_G_Pin);
  STM32GPIO LED_R(LED_R_GPIO_Port, LED_R_Pin);

  STM32ADC adc3(&hadc3, adc3_buf, {ADC_CHANNEL_8}, 3.3);
  auto& adc3_adc_channel_8 = adc3.GetChannel(0);
  UNUSED(adc3_adc_channel_8);

  STM32PWM pwm_tim1_ch1(&htim1, TIM_CHANNEL_1, false);
  STM32PWM pwm_tim1_ch2(&htim1, TIM_CHANNEL_2, false);
  STM32PWM pwm_tim1_ch3(&htim1, TIM_CHANNEL_3, false);
  STM32PWM pwm_tim1_ch4(&htim1, TIM_CHANNEL_4, false);

  STM32PWM pwm_tim10_ch1(&htim10, TIM_CHANNEL_1, false);

  STM32PWM pwm_tim3_ch3(&htim3, TIM_CHANNEL_3, false);

  STM32PWM pwm_tim4_ch3(&htim4, TIM_CHANNEL_3, false);

  STM32PWM pwm_tim8_ch1(&htim8, TIM_CHANNEL_1, false);
  STM32PWM pwm_tim8_ch2(&htim8, TIM_CHANNEL_2, false);
  STM32PWM pwm_tim8_ch3(&htim8, TIM_CHANNEL_3, false);

  STM32SPI spi1(&hspi1, spi1_rx_buf, spi1_tx_buf, 3);

  STM32UART usart1(&huart1,
              usart1_rx_buf, usart1_tx_buf, 5);

  STM32UART usart3(&huart3,
              usart3_rx_buf, {nullptr, 0}, 5);

  STM32UART usart6(&huart6,
              usart6_rx_buf, usart6_tx_buf, 15);

  STM32I2C i2c1(&hi2c1, i2c1_buf, 3);

  STM32I2C i2c3(&hi2c3, i2c3_buf, 3);

  STM32CAN can1(&hcan1, 5);

  STM32CAN can2(&hcan2, 5);

  static constexpr auto USB_OTG_HS_LANG_PACK = LibXR::USB::DescriptorStrings::MakeLanguagePack(LibXR::USB::DescriptorStrings::Language::EN_US, "QDU-Future", "MainCtrl", "QDU-Future-MainCtrl-89ABCDEF0123456701234567");
  LibXR::USB::CDCUart usb_otg_hs_cdc(LibXR::USB::Endpoint::EPNumber::EP1, LibXR::USB::Endpoint::EPNumber::EP1, LibXR::USB::Endpoint::EPNumber::EP2, 128, 128, 3);
  LibXR::USB::CDCUart usb_otg_hs_cdc2(LibXR::USB::Endpoint::EPNumber::EP3, LibXR::USB::Endpoint::EPNumber::EP2, LibXR::USB::Endpoint::EPNumber::EP4, 128, 128, 3);

  STM32USBDeviceOtgHS usb_hs(
      &hpcd_USB_OTG_HS,
      256,
      {usb_otg_hs_ep0_out_buf, usb_otg_hs_ep1_out_buf, usb_otg_hs_ep2_out_buf},
      {{usb_otg_hs_ep0_in_buf, 8}, {usb_otg_hs_ep1_in_buf, 128}, {usb_otg_hs_ep2_in_buf, 16}, {usb_otg_hs_ep3_in_buf, 128}, {usb_otg_hs_ep4_in_buf, 16}},
      USB::DeviceDescriptor::PacketSize0::SIZE_8,
      0x16D0, 0x1492, 0xF407,
      {&USB_OTG_HS_LANG_PACK},
      {{&usb_otg_hs_cdc, &usb_otg_hs_cdc2}},
      {reinterpret_cast<void *>(UID_BASE), 12}
  );
  usb_hs.Init(false);
  usb_hs.Start(false);

  static constexpr auto USB_OTG_FS_LANG_PACK = LibXR::USB::DescriptorStrings::MakeLanguagePack(LibXR::USB::DescriptorStrings::Language::EN_US, "QDU-Future", "MainCtrl", "QDU-Future-MainCtrl-89ABCDEF0123456701234567");
  LibXR::USB::CDCUart usb_otg_fs_cdc(LibXR::USB::Endpoint::EPNumber::EP1, LibXR::USB::Endpoint::EPNumber::EP1, LibXR::USB::Endpoint::EPNumber::EP2, 128, 128, 3);

  STM32USBDeviceOtgFS usb_fs(
      &hpcd_USB_OTG_FS,
      256,
      {usb_otg_fs_ep0_out_buf, usb_otg_fs_ep1_out_buf},
      {{usb_otg_fs_ep0_in_buf, 8}, {usb_otg_fs_ep1_in_buf, 128}, {usb_otg_fs_ep2_in_buf, 16}},
      USB::DeviceDescriptor::PacketSize0::SIZE_8,
      0x16D0, 0x1492, 0xF407,
      {&USB_OTG_FS_LANG_PACK},
      {{&usb_otg_fs_cdc}},
      {reinterpret_cast<void *>(UID_BASE), 12}
  );
  usb_fs.Init(false);
  usb_fs.Start(false);

  /* Terminal Configuration */
  STDIO::read_ = usb_otg_fs_cdc.read_port_;
  STDIO::write_ = usb_otg_fs_cdc.write_port_;

  RamFS ramfs("XRobot");
  Terminal<32, 32, 5, 5> terminal(ramfs);
  LibXR::Thread term_thread;
  term_thread.Create(&terminal, terminal.ThreadFun, "terminal", 2048,
                     static_cast<LibXR::Thread::Priority>(3));

  XR_REGISTER(power_manager, LibXR::PowerManager);
  XR_REGISTER(USER_KEY, LibXR::GPIO);
  XR_REGISTER(ACCL_CS, LibXR::GPIO);
  XR_REGISTER(GYRO_CS, LibXR::GPIO);
  XR_REGISTER(HW0, LibXR::GPIO);
  XR_REGISTER(HW1, LibXR::GPIO);
  XR_REGISTER(HW2, LibXR::GPIO);
  XR_REGISTER(ACCL_INT, LibXR::GPIO);
  XR_REGISTER(GYRO_INT, LibXR::GPIO);
  XR_REGISTER(spi1, LibXR::SPI);
  XR_REGISTER(pwm_tim10_ch1, LibXR::PWM);
  XR_REGISTER(CMPS_INT, LibXR::GPIO);
  XR_REGISTER(CMPS_RST, LibXR::GPIO);
  XR_REGISTER(LED_B, LibXR::GPIO);
  XR_REGISTER(LED_G, LibXR::GPIO);
  XR_REGISTER(LED_R, LibXR::GPIO);
  XR_REGISTER(pwm_tim1_ch1, LibXR::PWM);
  XR_REGISTER(pwm_tim1_ch2, LibXR::PWM);
  XR_REGISTER(pwm_tim1_ch3, LibXR::PWM);
  XR_REGISTER(pwm_tim1_ch4, LibXR::PWM);
  XR_REGISTER(pwm_tim3_ch3, LibXR::PWM);
  XR_REGISTER(pwm_tim4_ch3, LibXR::PWM);
  XR_REGISTER(pwm_tim8_ch1, LibXR::PWM);
  XR_REGISTER(pwm_tim8_ch2, LibXR::PWM);
  XR_REGISTER(pwm_tim8_ch3, LibXR::PWM);
  XR_REGISTER(adc3_adc_channel_8, LibXR::ADC);
  XR_REGISTER(usart1, LibXR::UART);
  XR_REGISTER(usart3, LibXR::UART);
  XR_REGISTER(usart6, LibXR::UART);
  XR_REGISTER(i2c1, LibXR::I2C);
  XR_REGISTER(i2c3, LibXR::I2C);
  XR_REGISTER(can1, LibXR::CAN);
  XR_REGISTER(can2, LibXR::CAN);
  XR_REGISTER(ramfs, LibXR::RamFS);
  XR_REGISTER(terminal, LibXR::Terminal<32, 32, 5, 5>);
  XR_REGISTER(usb_otg_fs_cdc, LibXR::UART);
  XR_REGISTER(CAMERA, LibXR::GPIO);
  XR_REGISTER(IMU_INT, LibXR::GPIO);
  XR_REGISTER(usb_otg_hs_cdc, LibXR::UART);
  XR_REGISTER(usb_otg_hs_cdc2, LibXR::UART);

  // clang-format on
  // NOLINTEND
  /* User Code Begin 3 */
  STM32Flash flash(FLASH_SECTORS, FLASH_SECTOR_NUMBER);
  LibXR::DatabaseRaw<1> database(flash);

  XR_REGISTER(database, LibXR::Database);
  XROBOT_MAIN();
  /* User Code End 3 */
}