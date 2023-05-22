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

include(cmake/printers.cmake)

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

# if os is macOS or Windows, panic!
if(APPLE)
  message(FATAL_ERROR "macOS is not supported")
elseif(WIN32)
  message(FATAL_ERROR "Windows is not supported")
endif()

disallow_in_source_builds()
disallow_system_install_prefix()
use_ninja_if_available()

option(WALL "Enable all warnings" ON)
option(WERROR "Treat warnings as errors" OFF)
if(WALL)
    message(STATUS "Enabling -Wall")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
endif()
if(WERROR)
    message(STATUS "Enabling -Werror")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Werror")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -march=native")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -march=native")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -march=native")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -march=native")



# Check C++14 or C++0x support
include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)
if(COMPILER_SUPPORTS_CXX14)
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
   add_definitions(-DCOMPILEDWITHC14)
   message(STATUS "Using flag -std=c++14.")
elseif(COMPILER_SUPPORTS_CXX0X)
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
   add_definitions(-DCOMPILEDWITHC0X)
   message(STATUS "Using flag -std=c++0x.")
else()
   message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
endif()

set(3RDPARTY_INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/install")
printvar(3RDPARTY_INSTALL_DIR)


IF(NOT DEFINED CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Release)
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
printlist(CMAKE_MODULE_PATH)

# add_subdirectory(3rdparty/g2o)

find_package(OpenCV 4.2.0 REQUIRED)
find_package(Eigen3 3.1.0 REQUIRED)

# set(DBoW2_DIR ${3RDPARTY_INSTALL_DIR}/lib/cmake/DBoW2)
find_package(DBoW2 REQUIRED)
# set(G2O_DIR ${3RDPARTY_INSTALL_DIR}/lib/cmake/g2o)
find_package(g2o REQUIRED)
# print_what_find_package_found(DBoW2)
find_package(Sophus REQUIRED)
find_package(Pangolin REQUIRED)

# in 3rdparty/DBoW2
# in 3rdparty/Sophus
# print everything the find_package() found
# printlist(OpenCV_LIBS)
# printlist(EIGEN3_INCLUDE_DIR)
# printlist(EIGEN3_LIBS)
# printlist(DBoW2_LIBS)
# printlist(Sophus_LIBS)
# printlist(G2O_LIBS)

# in 3rdparty/g2o 
# in 3rdparty/Pangolin


# if we are on windows


# include_directories(
# ${PROJECT_SOURCE_DIR}
# ${PROJECT_SOURCE_DIR}/include
# ${PROJECT_SOURCE_DIR}/include/CameraModels
# ${PROJECT_SOURCE_DIR}/3rdparty/Sophus
# ${EIGEN3_INCLUDE_DIR}
# ${Pangolin_INCLUDE_DIRS}
# LES CONFIGURE_DEPENDS
#   ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h
# )


# # src/*.cc
# file(SRC_FILES GLOB_RECURSE ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc)
# file(HEADER_FILES GLOB_RECURSE ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h)

file(GLOB_RECURSE SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc)
file(GLOB_RECURSE HEADER_FILES ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h)

add_library(${PROJECT_NAME} STATIC "")
target_sources(${PROJECT_NAME} PRIVATE
  ${SRC_FILES}
  ${HEADER_FILES}
)

# add_library(${PROJECT_NAME} SHARED
#   ${SRC_FILES}
#   ${HEADER_FILES}
# )

# TODO: remove duplicate include_directories
target_include_directories(${PROJECT_NAME} PRIVATE
#   ${PROJECT_SOURCE_DIR}
include
#   ${PROJECT_SOURCE_DIR}/include
#   ${PROJECT_SOURCE_DIR}/include/CameraModels
  ${Sophus_INCLUDE_DIRS}
#   ${PROJECT_SOURCE_DIR}/3rdparty/Sophus
  ${OpenCV_INCLUDE_DIRS}
  ${EIGEN3_INCLUDE_DIR}
  ${Pangolin_INCLUDE_DIRS}
  ${DBoW2_INCLUDE_DIRS}
  ${g2o_INCLUDE_DIRS}
#   ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h
)


# printlist(Pangolin_LIBRARIES)

target_link_libraries(${PROJECT_NAME}
  ${OpenCV_LIBS}
  ${EIGEN3_LIBS}
  ${Pangolin_LIBRARIES}
#   ${DBoW2_LIBS}
#   ${g2o_LIBS}
    DBoW2::DBoW2
  g2o::g2o

  # ${PROJECT_SOURCE_DIR}/3rdparty/DBoW2/lib/libDBoW2.so
# ${PROJECT_SOURCE_DIR}/3rdparty/g2o/lib/libg2o.so
# ${PROJECT_SOURCE_DIR}/3rdparty/install/lib/libpango_windowing.so
# ${PROJECT_SOURCE_DIR}/3rdparty/install/lib/libpango_image.so
-lboost_serialization
-lcrypto
)

target_compile_options(${PROJECT_NAME} PRIVATE -Wno-deprecated-declarations) # suppress warnings from Eigen3


# print_target_information(${PROJECT_NAME})



# # install public headers
# install(DIRECTORY include/
#   DESTINATION include
# )

# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_PROJECT_SOURCE_DIR}/lib)
install(TARGETS ${PROJECT_NAME}
  DESTINATION lib
  PUBLIC_HEADER DESTINATION include
  ARCHIVE DESTINATION lib
)

get_target_property(OUT ${PROJECT_NAME} INTERFACE_INCLUDE_DIRECTORIES)
foreach(dir ${OUT})
  message(STATUS "dir='${dir}'")
endforeach()

get_target_property(OUT ${PROJECT_NAME} INCLUDE_DIRECTORIES)
foreach(dir ${OUT})
  message(STATUS "dir='${dir}'")
endforeach()
