cmake_minimum_required(VERSION 2.8)
project(ORB_SLAM3)

IF(NOT DEFINED CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Release)
ENDIF()

function(printvar var)
  message(STATUS "${var} = ${${var}}")
endfunction()

printvar(CMAKE_BUILD_TYPE)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}  -Wall   -O3")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall   -O3")
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

# LIST(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake_modules)

# TODO: include the local install of OpenCV 4.2.0
# list(APPEND CMAKE_MODULE_PATH "~/.local/lib/cmake/opencv4")

find_package(Eigen3 3.1.0 REQUIRED)

# set(Pangolin_DIR "~/.local/lib/cmake/Pangolin")
find_package(Pangolin REQUIRED)

# use the local install of OpenCV 4.2.0, to avoid conflict with the system OpenCV
# Which on Jetpack 5.1 is OpenCV 4.5.1
# see `./scripts/install_opencv_4.2.0.sh`

set(OpenCV_DIR "~/.local/lib/cmake/opencv4")
find_package(OpenCV 4.2.0 REQUIRED)
# find_package(realsense2) # We do not use realsense camera

include_directories(
${PROJECT_SOURCE_DIR}
${PROJECT_SOURCE_DIR}/include
${PROJECT_SOURCE_DIR}/include/CameraModels
${PROJECT_SOURCE_DIR}/3rdparty/Sophus
${EIGEN3_INCLUDE_DIR}
${Pangolin_INCLUDE_DIRS}
)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/lib)

file(GLOB_RECURSE SRC_FILES CONFIGURE_DEPENDS
  ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
)

file(GLOB_RECURSE HEADER_FILES CONFIGURE_DEPENDS
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
-lboost_serialization
-lcrypto
)

