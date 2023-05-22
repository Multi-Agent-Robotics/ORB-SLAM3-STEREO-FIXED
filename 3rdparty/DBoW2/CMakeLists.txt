cmake_minimum_required(VERSION 3.16.3) # default on Ubuntu 20.04
project(DBoW2 VERSION 0.1.0 LANGUAGES CXX)

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

macro(use_ninja_if_available)
    if(NOT ${CMAKE_GENERATOR} STREQUAL Ninja)
        message(NOTICE "The default generator is not ninja. Consider using it for faster builds.")
        find_program(NINJA_EXECUTABLE ninja)
        if(NINJA_EXECUTABLE)
            message(NOTICE "Found ninja build system. Using it as the default generator.")
            set(CMAKE_GENERATOR Ninja)
            else()
            message(NOTICE "Ninja build system not found. Using the default generator ${CMAKE_GENERATOR}.")
        endif()
    endif()      
endmacro()

disallow_in_source_builds()
disallow_system_install_prefix()
use_ninja_if_available()

include(GNUInstallDirs) # for standard installation locations

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -march=native")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -march=native")

file(GLOB_RECURSE SRCS_DBOW2 "DBoW2/*.cpp")
file(GLOB_RECURSE HDRS_DBOW2 "DBoW2/*.h")
file(GLOB_RECURSE SRCS_DUTILS "DUtils/*.cpp")
file(GLOB_RECURSE HDRS_DUTILS "DUtils/*.h")

set(DBOW2_HEADER_FILES
    ${HDRS_DBOW2}
    ${HDRS_DUTILS}
)

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

# create the library
add_library(${PROJECT_NAME} STATIC "")
target_sources(${PROJECT_NAME} PRIVATE ${SRCS_DBOW2} ${SRCS_DUTILS})
target_compile_options(${PROJECT_NAME} PRIVATE -Wall -O3 -march=native)
target_link_libraries(${PROJECT_NAME} ${OpenCV_LIBS})

# using GnuInstallDirs after cmake 3.14 makes it so you
# do not have to specify the full path of RUNTIME DESTINATION etc.
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}Targets)

target_include_directories(${PROJECT_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
        ${OpenCV_INCLUDE_DIRS}
)



# install public header files
# install(DIRECTORY DBoW2/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h")
# install(DIRECTORY DUtils/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h")

# Export the export set for downstream projects
install(EXPORT ${PROJECT_NAME}Targets
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}Targets
  NAMESPACE ${PROJECT_NAME}::
)

# make the library importable from downstream projects with find_package()
include(CMakePackageConfigHelpers)

configure_package_config_file(
    ${CMAKE_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in                      # the template file
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake   # destination
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
  FILES ${DBOW2_HEADER_FILES}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
)


install(FILES ${HDRS_DUTILS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}/DUtils)