cmake_minimum_required(VERSION 3.22)


#
# This file is generated only once,
# and is not re-generated if converter is called multiple times.
#
# User is free to modify the file as much as necessary
#

# Setup compiler settings
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

set(DEV_C_IMAGE "default" CACHE STRING "DevC image kind: default, bootloader, or app")
set_property(CACHE DEV_C_IMAGE PROPERTY STRINGS default bootloader app)

# Define the build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
endif()

# Set the project name
set(CMAKE_PROJECT_NAME DevC)


# Enable compile command to ease indexing with e.g. clangd
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

# Enable CMake support for ASM and C languages
enable_language(C ASM)

# Core project settings
project(${CMAKE_PROJECT_NAME})
message("Build type: " ${CMAKE_BUILD_TYPE})
message("DevC image: " ${DEV_C_IMAGE})

# Create an executable object type
add_executable(${CMAKE_PROJECT_NAME})

# Add -Werror
add_compile_options(-Werror)

# Add STM32CubeMX generated sources
add_subdirectory(cmake/stm32cubemx)

if(DEV_C_IMAGE STREQUAL "bootloader")
    get_target_property(DEV_C_GENERATED_SOURCES ${CMAKE_PROJECT_NAME} SOURCES)
    list(FILTER DEV_C_GENERATED_SOURCES EXCLUDE REGEX ".*/Core/Src/main\\.c$")
    list(FILTER DEV_C_GENERATED_SOURCES EXCLUDE REGEX ".*/Core/Src/freertos\\.c$")
    list(FILTER DEV_C_GENERATED_SOURCES EXCLUDE REGEX ".*/Core/Src/stm32f4xx_it\\.c$")
    list(FILTER DEV_C_GENERATED_SOURCES EXCLUDE REGEX ".*/Core/Src/stm32f4xx_hal_timebase_tim\\.c$")
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES SOURCES "${DEV_C_GENERATED_SOURCES}")

    target_sources(${CMAKE_PROJECT_NAME} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/User/boot_main.c
        ${CMAKE_CURRENT_SOURCE_DIR}/User/boot_it.c
    )

    get_target_property(DEV_C_LINK_LIBRARIES ${CMAKE_PROJECT_NAME} LINK_LIBRARIES)
    list(FILTER DEV_C_LINK_LIBRARIES EXCLUDE REGEX "^FreeRTOS$")
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES LINK_LIBRARIES "${DEV_C_LINK_LIBRARIES}")

    if(TARGET FreeRTOS)
        set_target_properties(FreeRTOS PROPERTIES EXCLUDE_FROM_ALL TRUE)
    endif()
endif()

# Link directories setup
target_link_directories(${CMAKE_PROJECT_NAME} PRIVATE
    # Add user defined library search paths
)

# Add sources to executable
target_sources(${CMAKE_PROJECT_NAME} PRIVATE
    # Add user sources here
)

# Add include paths
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
    # Add user defined include paths
)

# Add project symbols (macros)
target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
    # Add user defined symbols
)

string(TOUPPER "${DEV_C_IMAGE}" DEV_C_IMAGE_UPPER)
target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE DEV_C_IMAGE_${DEV_C_IMAGE_UPPER})

foreach(target_name IN ITEMS stm32cubemx STM32_Drivers FreeRTOS)
    if(TARGET ${target_name})
        target_compile_definitions(${target_name} INTERFACE DEV_C_IMAGE_${DEV_C_IMAGE_UPPER})
    endif()
endforeach()

if(DEV_C_IMAGE STREQUAL "app")
    target_compile_definitions(stm32cubemx INTERFACE
        USER_VECT_TAB_ADDRESS
        VECT_TAB_OFFSET=0x00020000
    )
endif()

# Remove wrong libob.a library dependency when using cpp files
list(REMOVE_ITEM CMAKE_C_IMPLICIT_LINK_LIBRARIES ob)

# Add linked libraries
target_link_libraries(${CMAKE_PROJECT_NAME}
    stm32cubemx

    # Add user defined libraries
)

# Add LibXR
include(${CMAKE_CURRENT_LIST_DIR}/cmake/LibXR.CMake)

# Prints the section sizes
function(print_section_sizes TARGET)
  # Build Events command
  add_custom_command(
    TARGET ${TARGET}
    POST_BUILD
    COMMAND ${CMAKE_SIZE} ${TARGET}.elf)
endfunction()

# Creates output in hex format
function(create_hex_output TARGET)
  add_custom_target(
    ${TARGET}.hex ALL
    DEPENDS ${TARGET}
    COMMAND ${CMAKE_OBJCOPY} --output-target ihex ${TARGET}.elf ${TARGET}.hex)
endfunction()

# Creates output in binary format
function(create_bin_output TARGET)
  add_custom_target(
    ${TARGET}.bin ALL
    DEPENDS ${TARGET}
    COMMAND ${CMAKE_OBJCOPY} --output-target binary --strip-all ${TARGET}.elf
            ${TARGET}.bin)
endfunction()

create_hex_output(${PROJECT_NAME})
create_bin_output(${PROJECT_NAME})
print_section_sizes(${PROJECT_NAME})
