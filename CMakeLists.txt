cmake_minimum_required(VERSION 2.8)
project(ORB_SLAM3)

function(printvar var)
  string(ASCII 27 Esc)
  set(cyan "${Esc}[36m")
  set(reset "${Esc}[m")
  message(STATUS "${cyan}${var}$${re} = ${${var}}${reset}")
endfunction()

IF(NOT DEFINED CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Release)
ENDIF()

printvar(CMAKE_BUILD_TYPE)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -O3")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -O3")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -march=native")
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

set(3TDPARTY_INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/install")
printvar(3TDPARTY_INSTALL_DIR)

# use the local install of OpenCV 4.2.0, to avoid conflict with the system OpenCV
# Which on Jetpack 5.1 is OpenCV 4.5.1
# see `./scripts/install_opencv_4.2.0.sh`

# https://forums.developer.nvidia.com/t/how-to-find-if-cmakelists-txt-is-residing-on-jetson-xavier/181725/4
if(EXISTS "/etc/nv_tegra_release")
	message(STATUS "NVIDIA Jetson platform")
	  set(OpenCV_DIR "/usr/local/lib/cmake/opencv4")
else()
endif()
find_package(OpenCV 4.2.0 REQUIRED)

find_package(Eigen3 3.1.0 REQUIRED)

# set(Pangolin_DIR "~/.local/lib/cmake/Pangolin")
set(Pangolin_DIR "${3TDPARTY_INSTALL_DIR}/lib/cmake/Pangolin")
find_package(Pangolin REQUIRED)

include_directories(
${PROJECT_SOURCE_DIR}
${PROJECT_SOURCE_DIR}/include
${PROJECT_SOURCE_DIR}/include/CameraModels
${PROJECT_SOURCE_DIR}/3rdparty/Sophus
${EIGEN3_INCLUDE_DIR}
${Pangolin_INCLUDE_DIRS}
LES CONFIGURE_DEPENDS
  ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h
)

add_library(${PROJECT_NAME} SHARED
  ${SRC_FILES}
  ${HEADER_FILES}
)

add_subdirectory(3rdparty/g2o)

target_link_libraries(${PROJECT_NAME}
${OpenCV_LIBS}
${EIGEN3_LIBS}
${Pangolin_LIBRARIES}
${PROJECT_SOURCE_DIR}/3rdparty/DBoW2/lib/libDBoW2.so
${PROJECT_SOURCE_DIR}/3rdparty/g2o/lib/libg2o.so
${PROJECT_SOURCE_DIR}/3rdparty/install/lib/libpango_windowing.so
${PROJECT_SOURCE_DIR}/3rdparty/install/lib/libpango_image.so
-lboost_serialization
-lcrypto
)


# install public headers
install(DIRECTORY include/
  DESTINATION include
  # FILES_MATCHING PATTERN "*.h"
)
