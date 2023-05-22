cmake_minimum_required(VERSION 3.16.3) # 3.16.3 is the version on Ubuntu 20.04

set(MAJOR_VERSION 0)
set(MINOR_VERSION 1)
set(PATCH_VERSION 0)

project(ORB_SLAM3
  VERSION ${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION}
  DESCRIPTION "ORB_SLAM3"
  HOMEPAGE_URL "https://github.com/Multi-Agent-Robotics/ORB-SLAM3-STEREO-FIXED"
  LANGUAGES CXX
)

include(cmake/disallow.cmake)
include(cmake/printers.cmake)


macro(use_ninja_if_available)
    if(NOT ${CMAKE_GENERATOR} STREQUAL Ninja)
        message(NOTICE "The default generator is not ninja. Consider using it for faster builds.")
        find_program(NINJA_EXECUTABLE ninja)
        if(NINJA_EXECUTABLE)
            message(NOTICE "Found ninja build system. Using it as the default generator.")
            set(CMAKE_GENERATOR Ninja CACHE INTERNAL "" FORCE)
        else()
            message(NOTICE "Ninja build system not found. Using the default generator ${CMAKE_GENERATOR}.")
        endif()
    endif()
endmacro()

# if os is macOS or Windows, panic!
if(APPLE)
  message(FATAL_ERROR "macOS is not supported")
elseif(WIN32)
  message(FATAL_ERROR "Windows is not supported")
endif()

disallow_in_source_builds()
disallow_system_install_prefix()
use_ninja_if_available()

# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -march=native")
# set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -march=native")
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -march=native")
# set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -march=native")

# create compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# install compile_commands.json to .vscode/c_cpp_properties.json
# check if folder exists
if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.vscode)
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.vscode)
endif()
install(FILES ${CMAKE_BINARY_DIR}/compile_commands.json DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/.vscode)

# # Check C++14 or C++0x support
# include(CheckCXXCompilerFlag)
# CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
# CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)
# if(COMPILER_SUPPORTS_CXX14)
#    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
#    add_definitions(-DCOMPILEDWITHC14)
#    message(STATUS "Using flag -std=c++14.")
# elseif(COMPILER_SUPPORTS_CXX0X)
#    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
#    add_definitions(-DCOMPILEDWITHC0X)
#    message(STATUS "Using flag -std=c++0x.")
# else()
#    message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
# endif()

set(CMAKE_CXX_STANDARD 17) # use std::optional
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF) # disable compiler extensions like gnu++17

set(3RDPARTY_INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/install")
printvar(3RDPARTY_INSTALL_DIR)


IF(NOT DEFINED CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel." FORCE)
ENDIF()

printvar(CMAKE_BUILD_TYPE)
printvar(CMAKE_CXX_COMPILER)
printvar(CMAKE_CXX_FLAGS)
printvar(CMAKE_CXX_FLAGS_RELEASE)
printvar(CMAKE_CXX_FLAGS_DEBUG)



# use the local install of OpenCV 4.2.0, to avoid conflict with the system OpenCV
# Which on Jetpack 5.1 is OpenCV 4.5.1
# see `./scripts/install_opencv_4.2.0.sh`
# https://forums.developer.nvidia.com/t/how-to-find-if-cmakelists-txt-is-residing-on-jetson-xavier/181725/4
if(EXISTS "/etc/nv_tegra_release")
	  message(STATUS "Host is NVIDIA Jetson")
	  set(OpenCV_DIR "/usr/local/lib/cmake/opencv4")
endif()

list(PREPEND CMAKE_MODULE_PATH ${3RDPARTY_INSTALL_DIR}/lib/cmake)
print_list_enumerated(CMAKE_MODULE_PATH)

find_package(OpenCV 4.2.0 REQUIRED)
find_package(Eigen3 3.1.0 REQUIRED)

# found in ./3rdparty/install/lib/cmake
find_package(DBoW2 REQUIRED)
find_package(g2o REQUIRED)
find_package(Sophus REQUIRED)
find_package(Pangolin REQUIRED)

# find the boost serialization library
find_package(Boost REQUIRED COMPONENTS serialization)


function(assert_target_exists target)
    if(NOT TARGET ${target})
        message(FATAL_ERROR "Target ${target} does not exist")
    endif()
endfunction()

assert_target_exists(DBoW2::DBoW2)
assert_target_exists(g2o::g2o)

# print_target_information(DBoW2::DBoW2)
# print_target_information(g2o::g2o)


file(GLOB_RECURSE SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc)
file(GLOB_RECURSE HEADER_FILES ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h)

set(LIBRARY_TYPE STATIC)

add_library(${PROJECT_NAME} ${LIBRARY_TYPE} "")
target_sources(${PROJECT_NAME} PRIVATE
  ${SRC_FILES}
  ${HEADER_FILES}
)

target_link_libraries(${PROJECT_NAME} PUBLIC
    ${OpenCV_LIBS}
    ${EIGEN3_LIBS}
    ${Pangolin_LIBRARIES}
    DBoW2::DBoW2
    g2o::g2o
    ${Sophus_LIBRARIES}
    # -lboost_serialization
    Boost::serialization
    -lcrypto
)

target_include_directories(${PROJECT_NAME}
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include> # use absolute path to build
    $<INSTALL_INTERFACE:include> # use relative path to install
  )


target_compile_options(${PROJECT_NAME} PRIVATE
    -Wall
    -Wextra
    -Wno-deprecated-declarations # suppress warnings from Eigen3
    -Wno-unused-parameter
    -Wno-unused-variable
    -Wno-sign-compare
    -Wno-maybe-uninitialized
    -Wno-deprecated-copy
    -Wno-deprecated
    -Wno-reorder
    -Wno-unused-but-set-variable

    $<$<CONFIG:Release>:-O3> # highest optimization level
    $<$<CONFIG:Release>:-march=native> # enable all CPU features available on the build machine
    $<$<CONFIG:Release>:-flto> # link time optimization
    $<$<CONFIG:Release>:-ffast-math>

    $<$<CONFIG:Debug>:-g>
    $<$<CONFIG:Debug>:-O0>
    $<$<CONFIG:Debug>:-fno-omit-frame-pointer>
)

target_link_options(${PROJECT_NAME} PRIVATE
    $<$<CONFIG:Debug>:--coverage> # enable coverage for debug builds
)

# see: https://cmake.org/cmake/help/latest/prop_gbl/CMAKE_CXX_KNOWN_FEATURES.html#prop_gbl:CMAKE_CXX_KNOWN_FEATURES
# for a list of features for each version of C++
target_compile_features(${PROJECT_NAME} PRIVATE
    cxx_std_17 # for std::optional
    cxx_constexpr
    cxx_auto_type
    cxx_nullptr
    cxx_lambdas
    cxx_range_for
    cxx_strong_enums
    cxx_variadic_templates
    cxx_static_assert
    cxx_decltype
    cxx_rvalue_references
    cxx_attribute_deprecated
)

find_program(CPPCHECK_EXECUTABLE NAMES cppcheck)
if (CPPCHECK_EXECUTABLE)
    add_custom_target(cppcheck
        COMMAND ${CPPCHECK_EXECUTABLE} --enable=warning,performance,portability,style --std=c++17 -I${CMAKE_SOURCE_DIR}/include ${CMAKE_SOURCE_DIR}/src
        COMMENT "Running CppCheck"
    )
else()
    message(WARNING "CppCheck not found! You won't be able to run cppcheck.")
endif()


print_target_information(${PROJECT_NAME})

include(GNUInstallDirs)
# using GnuInstallDirs after cmake 3.14 makes it so you
# do not have to specify the full path of RUNTIME DESTINATION etc.
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}Targets)


print_CMAKE_variables()

# print_all_variables_with_prefix("DBoW2")
# print_all_variables_with_prefix("g2o")
# print_all_variables_with_prefix("Sophus")
# print_all_variables_with_prefix("Pangolin")
