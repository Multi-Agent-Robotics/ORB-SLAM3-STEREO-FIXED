cmake_minimum_required(VERSION 3.16.3) # 3.16.3 is the version on Ubuntu 20.04

set(MAJOR_VERSION 0)
set(MINOR_VERSION 1)
set(PATCH_VERSION 0)

project(orbslam3
  VERSION ${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION}
  DESCRIPTION "orbslam3"
  HOMEPAGE_URL "https://github.com/Multi-Agent-Robotics/ORB-SLAM3-STEREO-FIXED"
  LANGUAGES CXX
)

include(cmake/disallow.cmake)
include(cmake/printers.cmake)

macro(suggest_ninja_if_available)
    if(NOT ${CMAKE_GENERATOR} STREQUAL Ninja)
        message(NOTICE "The default generator is not ninja. Consider using it for faster builds.")
        find_program(NINJA_EXECUTABLE ninja)
        if(NINJA_EXECUTABLE)
            message(NOTICE "ninja build system found. To use it, run cmake with `-G Ninja`.")
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
suggest_ninja_if_available()

# create compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# install compile_commands.json to .vscode/c_cpp_properties.json
# check if folder exists
if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.vscode)
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.vscode)
endif()
install(FILES ${CMAKE_BINARY_DIR}/compile_commands.json DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/.vscode)

set(CMAKE_CXX_STANDARD 17) # use std::optional
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF) # disable compiler extensions like gnu++17, so clang can be used

set(3RDPARTY_INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/install")
printvar(3RDPARTY_INSTALL_DIR)

if(NOT DEFINED CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif()

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
# find_package(DBoW2 REQUIRED)
# find_package(g2o REQUIRED)
# find_package(Sophus REQUIRED)

add_subdirectory(3rdparty/DBoW2)
add_subdirectory(3rdparty/g2o)
add_subdirectory(3rdparty/Sophus)
add_subdirectory(submodules/Pangolin)
# find_package(Pangolin REQUIRED)

# print_target_sources(DBoW2)
print_target_included_directories(DBoW2)

# find the boost serialization library
find_package(Boost REQUIRED COMPONENTS serialization)

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
    DBoW2
    g2o
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
    # $<$<CONFIG:Release>:-ffast-math>

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


# print_target_information(${PROJECT_NAME})

# make the library importable from downstream projects with find_package()
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)
# using GnuInstallDirs after cmake 3.14 makes it so you
# do not have to specify the full path of RUNTIME DESTINATION etc.
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}Targets)

# Export the export set for downstream projects
install(EXPORT ${PROJECT_NAME}Targets
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}Targets
  NAMESPACE ${PROJECT_NAME}::
)

configure_package_config_file(
    ${CMAKE_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in # the template file
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake  # destination
    PATH_VARS CMAKE_INSTALL_INCLUDEDIR
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

# create and install a version file. when find_package() is called, this ensures
# that the version found is compatible with the version required.
#   ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${PROJECT_NAME}ConfigVersion.cmake
write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

# Install header files
install(
  DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/${PROJECT_NAME}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
)
