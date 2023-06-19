cmake_minimum_required (VERSION 3.16.3 FATAL_ERROR) # 3.16.3 is the version on Ubuntu 20.04

set (ORBSLAM3_MAJOR_VERSION 0)
set (ORBSLAM3_MINOR_VERSION 1)
set (ORBSLAM3_PATCH_VERSION 0)
set (ORBSLAM3_VERSION "${ORBSLAM3_MAJOR_VERSION}.${ORBSLAM3_MINOR_VERSION}.${ORBSLAM3_PATCH_VERSION}")

project (orbslam3
    VERSION ${ORBSLAM3_VERSION}
    DESCRIPTION "ORB-SLAM3: An Accurate Open-Source Library for Visual, Visual-Inertial and Multi-Map SLAM"
    HOMEPAGE_URL "https://github.com/Multi-Agent-Robotics/ORB-SLAM3-STEREO-FIXED"
    LANGUAGES CXX
)

include (cmake/disallow.cmake)
include (cmake/printers.cmake)
include (cmake/ccache.cmake)
include (cmake/ninja.cmake)

# check if operating system is Linux
if (NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message (FATAL_ERROR "Only Linux is supported")
endif ()

disallow_in_source_builds ()

# disallow_system_install_prefix()
suggest_ninja_if_available ()
use_ccache_if_available ()

# create compile_commands.json
set (CMAKE_EXPORT_COMPILE_COMMANDS ON)

# install compile_commands.json to .vscode/c_cpp_properties.json
# check if folder exists
if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.vscode)
    message (STATUS "Creating .vscode folder")
    file (MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.vscode)
endif ()

install (FILES ${CMAKE_BINARY_DIR}/compile_commands.json DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/.vscode)

set (CMAKE_CXX_STANDARD 17) # use std::optional
set (CMAKE_CXX_STANDARD_REQUIRED ON)
set (CMAKE_CXX_EXTENSIONS OFF) # disable compiler extensions like gnu++17, so clang can be used

# set(3RDPARTY_INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/install")
# printvar(3RDPARTY_INSTALL_DIR)
if (NOT DEFINED CMAKE_BUILD_TYPE)
    set (CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif ()

printvar (CMAKE_BUILD_TYPE)
printvar (CMAKE_CXX_COMPILER)
printvar (CMAKE_CXX_COMPILER_VERSION)
printvar (CMAKE_CXX_FLAGS)

# use the local install of OpenCV 4.2.0, to avoid conflict with the system OpenCV
# Which on Jetpack 5.1 is OpenCV 4.5.1
# see `./scripts/install_opencv_4.2.0.sh`
# https://forums.developer.nvidia.com/t/how-to-find-if-cmakelists-txt-is-residing-on-jetson-xavier/181725/4
if (EXISTS "/etc/nv_tegra_release")
    message (STATUS "Host is NVIDIA Jetson")
    set (OpenCV_DIR "/usr/local/lib/cmake/opencv4")
endif ()

# list(PREPEND CMAKE_MODULE_PATH ${3RDPARTY_INSTALL_DIR}/lib/cmake)
# print_list_enumerated(CMAKE_MODULE_PATH)
find_package (OpenCV 4.2.0 REQUIRED)
find_package (Eigen3 3.1.0 REQUIRED)

# Due to how Pangolin define targets, it is easier to use find_package() instead of add_subdirectory()
find_package (Pangolin REQUIRED)
find_package (Boost REQUIRED COMPONENTS serialization)

add_subdirectory (3rdparty/DBoW2)
add_subdirectory (3rdparty/g2o)
add_subdirectory (3rdparty/Sophus)

file (GLOB_RECURSE SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
file (GLOB_RECURSE HEADER_FILES ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp)

set (LIBRARY_TYPE SHARED)
add_library (orbslam3 ${LIBRARY_TYPE} ${SRC_FILES} ${HEADER_FILES})

target_link_libraries (orbslam3
    DBoW2
    g2o
    sophus
    ${OpenCV_LIBS}
    ${EIGEN3_LIBS}
    ${Pangolin_LIBRARIES}
    Boost::serialization
    -lcrypto
)

target_include_directories (orbslam3
    PRIVATE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include> # use absolute path to build
    $<INSTALL_INTERFACE:include> # use relative path to install
)

# set_target_properties(orbslam3 PROPERTIES PUBLIC_HEADER "${HEADER_FILES}")
target_compile_options (orbslam3 PRIVATE
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

    # if the compiler is clang
    $<$<STREQUAL:${CMAKE_CXX_COMPILER_ID},Clang>:-fcolor-diagnostics>

    # if the compiler is gcc
    $<$<STREQUAL:${CMAKE_CXX_COMPILER_ID},GNU>:-fdiagnostics-color=always>

    # $<$<CONFIG:Release>:-O3> # highest optimization level
    # $<$<CONFIG:Release>:-march=native> # enable all CPU features available on the build machine
    # $<$<CONFIG:Release>:-flto> # link time optimization

    # $<$<CONFIG:Release>:-ffast-math>
    # $<$<CONFIG:Debug>:-g>
    # $<$<CONFIG:Debug>:-O0>
    # $<$<CONFIG:Debug>:-fno-omit-frame-pointer>
)

# target_link_options(orbslam3 PRIVATE
# $<$<CONFIG:Debug>:--coverage> # enable coverage for debug builds
# )

# see: https://cmake.org/cmake/help/latest/prop_gbl/CMAKE_CXX_KNOWN_FEATURES.html#prop_gbl:CMAKE_CXX_KNOWN_FEATURES
# for a list of features for each version of C++
# target_compile_features(orbslam3 PRIVATE
# cxx_std_17 # for std::optional
# cxx_constexpr
# cxx_auto_type
# cxx_nullptr
# cxx_lambdas
# cxx_range_for
# cxx_strong_enums
# cxx_variadic_templates
# cxx_static_assert
# cxx_decltype
# cxx_rvalue_references
# cxx_attribute_deprecated
# )

# target_compile_definitions(orbslam3
# PRIVATE
# $<$<CONFIG:Debug>:DEBUG>
# )

# print_target_information(${PROJECT_NAME})

# make the library importable from downstream projects with find_package()
include (CMakePackageConfigHelpers)
include (GNUInstallDirs)

# make export set
# export(TARGETS ${PACKAGE_NAME} g2o DBoW2 sophus NAMESPACE orbslam3:: FILE ${PROJECT_NAME}Targets.cmake)

# using GnuInstallDirs after cmake 3.14 makes it so you
# do not have to specify the full path of RUNTIME DESTINATION etc.
# set(TARGETS_FILE ${PROJECT_NAME}Targets.cmake)
# print_all_variables_with_prefix(orbslam3)
# print_all_variables_with_prefix(PROJECT)

# Make project usable from build tree.
export (TARGETS orbslam3 g2o DBoW2 sophus FILE orbslam3-targets.cmake)
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}-config.cmake.in
    ${PROJECT_NAME}-config.cmake @ONLY)

configure_file (${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}-config-version.cmake.in
    ${${PROJECT_NAME}_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake @ONLY)

install (TARGETS orbslam3 g2o DBoW2 sophus
    EXPORT ${PROJECT_NAME}-targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# get_target_property(ORBSLAM3_INCLUDE_DIRS orbslam3 INTERFACE_INCLUDE_DIRECTORIES)
# print_list_enumerated(ORBSLAM3_INCLUDE_DIRS)
# get_test_property(DBoW2_INCLUDE_DIRS DBoW2 INCLUDE_DIRECTORIES)
# print_list_enumerated(DBoW2_INCLUDE_DIRS)
# get_test_property(g2o_INCLUDE_DIRS g2o INCLUDE_DIRECTORIES)
# print_list_enumerated(g2o_INCLUDE_DIRS)
# get_test_property(sophus_INCLUDE_DIRS sophus INCLUDE_DIRECTORIES)
# print_list_enumerated(sophus_INCLUDE_DIRS)

# set(TARGETS ${PROJECT_NAME} g2o DBoW2 sophus)
# install(TARGETS ${TARGETS} EXPORT ${PROJECT_NAME}Targets)

# # Export the export set for downstream projects
# install(EXPORT ${PROJECT_NAME}Targets
# DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
# NAMESPACE ${PROJECT_NAME}::
# )

# configure_package_config_file(
# ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in # the template file
# ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake # destination
# PATH_VARS CMAKE_INSTALL_INCLUDEDIR
# INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
# )

# install(FILES
# ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
# DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
# )

# # create and install a version file. when find_package() is called, this ensures
# # that the version found is compatible with the version required.
# # ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${PROJECT_NAME}ConfigVersion.cmake
# write_basic_package_version_file(
# ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
# VERSION ${PROJECT_VERSION}
# COMPATIBILITY SameMajorVersion
# )

# install(FILES
# ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
# DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
# )

# Install header files
# install(
# DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/${PROJECT_NAME}
# DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
# )

# make the library available in the users local cmake registry at ~/.cmake/packages/${PROJECT_NAME}
set (CMAKE_EXPORT_PACKAGE_REGISTRY ON)
export (PACKAGE ${PROJECT_NAME})
message (STATUS "Exported package ${PROJECT_NAME}")
message (STATUS "Find it with find_package(${PROJECT_NAME}).")
message (STATUS "A link to it will be at ~/.cmake/packages/${PROJECT_NAME}")
