#pragma once
// xrobot-stamp: config=xrobot.yaml sha256=59c0739eaf51a5ee5dc3530850cc9130dccb6fc327432bf6a709734a0aa282d8
// xrobot-stamp: lock=../xrobot.lock sha256=45b737a1c93b150bad88d1f91672dd893108c458cea5e0faa3a4bc7cefb6b5c3
// xrobot-stamp: tool=xrobot 0.3.1

#include <memory>
#include <type_traits>
#include <utility>
#include "libxr.hpp"
#include "thread.hpp"
#include "BlinkLED.hpp"

namespace xrobot_generated {
template <typename...> struct TypeList {};
template <typename Source, typename... Views>
struct RegistrationMatches
    : std::bool_constant<(!std::is_reference<Views>::value && ...) &&
                         (std::is_convertible<Source*, Views*>::value && ...)> {};

}  // namespace xrobot_generated

// Force only this entry inline in optimized Clang builds.
#if defined(__clang__) && defined(__OPTIMIZE__) && !defined(LIBXR_DEBUG_BUILD) && \
    ((defined(XROBOT_OPTIMIZED_BUILD) && XROBOT_OPTIMIZED_BUILD) || \
     (!defined(XROBOT_OPTIMIZED_BUILD) && defined(NDEBUG)))
#define XR_XROBOT_MAIN_INLINE [[gnu::always_inline]] inline
#else
#define XR_XROBOT_MAIN_INLINE inline
#endif

[[noreturn]] XR_XROBOT_MAIN_INLINE void XRobotMain(
    LibXR::GPIO& LED_B) {
  // modules[0]: blink_led
  static BlinkLED blink_led(
      static_cast<LibXR::GPIO&>(LED_B)
      , 250
  );
  static_assert(std::is_void_v<decltype(blink_led.OnMonitor())>, "blink_led.OnMonitor() must return void");
  for (;;) {
    blink_led.OnMonitor();
    LibXR::Thread::Sleep(1000);
  }
}

#undef XR_XROBOT_MAIN_INLINE

/* User Code Begin XRobotMain */
/* User Code End XRobotMain */
// clang-format off
// NOLINTBEGIN
#define XR_REGISTER_DETAIL_power_manager(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::PowerManager>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(power_manager)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_USER_KEY(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(USER_KEY)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_ACCL_CS(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(ACCL_CS)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_GYRO_CS(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(GYRO_CS)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_HW0(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(HW0)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_HW1(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(HW1)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_HW2(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(HW2)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_ACCL_INT(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(ACCL_INT)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_GYRO_INT(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(GYRO_INT)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_CAMERA(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(CAMERA)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_IMU_INT(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(IMU_INT)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_CMPS_INT(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(CMPS_INT)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_CMPS_RST(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(CMPS_RST)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_LED_B(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(LED_B)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_LED_G(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(LED_G)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_LED_R(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::GPIO>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(LED_R)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_pwm_tim1_ch1(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::PWM>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(pwm_tim1_ch1)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_pwm_tim1_ch2(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::PWM>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(pwm_tim1_ch2)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_pwm_tim1_ch3(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::PWM>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(pwm_tim1_ch3)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_pwm_tim1_ch4(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::PWM>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(pwm_tim1_ch4)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_pwm_tim10_ch1(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::PWM>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(pwm_tim10_ch1)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_pwm_tim3_ch3(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::PWM>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(pwm_tim3_ch3)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_pwm_tim4_ch3(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::PWM>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(pwm_tim4_ch3)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_pwm_tim8_ch1(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::PWM>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(pwm_tim8_ch1)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_pwm_tim8_ch2(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::PWM>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(pwm_tim8_ch2)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_pwm_tim8_ch3(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::PWM>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(pwm_tim8_ch3)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_adc3_adc_channel_8(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::ADC>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(adc3_adc_channel_8)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_spi1(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::SPI>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(spi1)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_usart1(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::UART>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(usart1)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_usart3(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::UART>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(usart3)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_usart6(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::UART>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(usart6)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_i2c1(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::I2C>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(i2c1)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_i2c3(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::I2C>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(i2c3)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_can1(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::CAN>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(can1)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_can2(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::CAN>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(can2)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_usb_otg_fs_cdc(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::UART>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(usb_otg_fs_cdc)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_ramfs(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::RamFS>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(ramfs)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_terminal(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::Terminal<32, 32, 5, 5>>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(terminal)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_usb_otg_hs_cdc(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::UART>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(usb_otg_hs_cdc)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_usb_otg_hs_cdc2(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::UART>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(usb_otg_hs_cdc2)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER_DETAIL_database(...) \
  static_assert(std::is_same<::xrobot_generated::TypeList<__VA_ARGS__>, \
      ::xrobot_generated::TypeList<LibXR::Database>>::value && \
      ::xrobot_generated::RegistrationMatches< \
          std::remove_reference_t<decltype(database)>, __VA_ARGS__>::value, \
      "XR_REGISTER changed; regenerate xrobot_main.hpp")
#define XR_REGISTER(name, ...) XR_REGISTER_DETAIL_##name(__VA_ARGS__)

#define XROBOT_MAIN() ::XRobotMain(LED_B)

// NOLINTEND
// clang-format on
