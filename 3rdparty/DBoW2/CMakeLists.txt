cmake_minimum_required(VERSION 3.16.3) # default on Ubuntu 20.04
project(DBoW2 VERSION 0.1.0 LANGUAGES CXX C)

function(disallow_in_source_builds)
    if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
        message(FATAL_ERROR "In-source builds are not allowed. Please, create a separate directory for build files.")
    endif()
endfunction()

function(disallow_system_install_prefix)
    # disallow installing in /usr/local
    if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        message(FATAL_ERROR "CMAKE_INSTALL_PREFIX is set to default value: ${CMAKE_INSTALL_PREFIX}. This is not recommended.")
    endif()
endfunction()

disallow_in_source_builds()
# disallow_system_install_prefix()

include(GNUInstallDirs) # for standard installation locations

if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 14)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

file(GLOB_RECURSE SRCS "src/*.cpp")
file(GLOB_RECURSE HDRS "include/DBoW2/*.h")
file(GLOB_RECURSE DUTILS "src/DUtils/*")

# file(GLOB_RECURSE SRCS_DBOW2 "DBoW2/*.cpp")
# file(GLOB_RECURSE HDRS_DBOW2 "DBoW2/*.h")
# file(GLOB_RECURSE SRCS_DUTILS "DBoW2/DUtils/*.cpp")
# file(GLOB_RECURSE HDRS_DUTILS "DBoW2/DUtils/*.h")

# set(DBOW2_HEADER_FILES
#     ${HDRS_DBOW2}
#     ${HDRS_DUTILS}
# )

# use the local install of OpenCV 4.2.0, to avoid conflict with the system OpenCV
# Which on Jetpack 5.1 is OpenCV 4.5.1
# see `./scripts/install_opencv_4.2.0.sh`
if(EXISTS "/etc/nv_tegra_release")
    message(STATUS "NVIDIA Jetson platform")
    set(OpenCV_DIR "/usr/local/lib/cmake/opencv4")
endif()

find_package(OpenCV 4.2.0 REQUIRED)

if(NOT OpenCV_FOUND)
    message(FATAL_ERROR "OpenCV >= 4.2.0 not found.")
endif()

# create the library -----------------------------------------------------------
add_library(${PROJECT_NAME} STATIC "")
# target_sources(${PROJECT_NAME} PRIVATE ${SRCS_DBOW2} ${SRCS_DUTILS})
target_sources(${PROJECT_NAME} PRIVATE ${SRCS} ${DUTILS})

target_include_directories(${PROJECT_NAME}
    PUBLIC
    # $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    ${OpenCV_INCLUDE_DIRS}
)

target_compile_options(${PROJECT_NAME} PRIVATE
    -Wall
    $<$<CONFIG:RELEASE>:-O3 -march=native>
    $<$<CONFIG:Release>:-flto> # link time optimization
    $<$<CONFIG:DEBUG>:-O0 -g>
)
target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)
target_link_libraries(${PROJECT_NAME} ${OpenCV_LIBS})


export(TARGETS ${PROJECT_NAME} FILE ${PROJECT_NAME}Targets.cmake)
set(CMAKE_EXPORT_PACKAGE_REGISTRY ON)
export(PACKAGE ${PROJECT_NAME})

# # install the library ----------------------------------------------------------

# # using GnuInstallDirs after cmake 3.14 makes it so you
# # do not have to specify the full path of RUNTIME DESTINATION etc.
# install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}Targets)

# # Export the export set for downstream projects
# install(EXPORT ${PROJECT_NAME}Targets
#     DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}Targets
#     NAMESPACE ${PROJECT_NAME}::
# )

# # make the library importable from downstream projects with find_package()
# include(CMakePackageConfigHelpers)

# configure_package_config_file(
#     ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in # the template file
#     ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake # destination
#     PATH_VARS CMAKE_INSTALL_INCLUDEDIR
#     INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
# )

# install(FILES
#     ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
#     DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
# )

# # create and install a version file. when find_package() is called, this ensures
# # that the version found is compatible with the version required.
# # ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${PROJECT_NAME}ConfigVersion.cmake
# write_basic_package_version_file(
#     ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
#     VERSION ${PROJECT_VERSION}
#     COMPATIBILITY SameMajorVersion
# )

# install(FILES
#     ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
#     DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
# )

# # Install header files
# install(
#     FILES ${HDRS}
#     DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
# )

# # install(FILES ${HDRS_DUTILS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}/DUtils)
