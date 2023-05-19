cmake_minimum_required(VERSION 2.8)
project(ORB_SLAM3)

include(cmake/printers.cmake)

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

set(3RDPARTY_INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/install")
printvar(3RDPARTY_INSTALL_DIR)

printvar(CMAKE_CXX_FLAGS)
printvar(CMAKE_CXX_FLAGS_RELEASE)


# use the local install of OpenCV 4.2.0, to avoid conflict with the system OpenCV
# Which on Jetpack 5.1 is OpenCV 4.5.1
# see `./scripts/install_opencv_4.2.0.sh`
# https://forums.developer.nvidia.com/t/how-to-find-if-cmakelists-txt-is-residing-on-jetson-xavier/181725/4
if(EXISTS "/etc/nv_tegra_release")
	  message(STATUS "Host is NVIDIA Jetson")
	  set(OpenCV_DIR "/usr/local/lib/cmake/opencv4")
endif()
find_package(OpenCV 4.2.0 REQUIRED)

find_package(Eigen3 3.1.0 REQUIRED)

# set(Pangolin_DIR "~/.local/lib/cmake/Pangolin")
# set(Pangolin_DIR "${3RDPARTY_INSTALL_DIR}/lib/cmake/Pangolin")
find_package(Pangolin REQUIRED)

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
# printlist(SRC_FILES)
# tree(${CMAKE_CURRENT_SOURCE_DIR}/src)
file(GLOB_RECURSE HEADER_FILES ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h)
# printlist(HEADER_FILES)
# tree(${CMAKE_CURRENT_SOURCE_DIR}/include)

add_library(${PROJECT_NAME} SHARED
  ${SRC_FILES}
  ${HEADER_FILES}
)


target_include_directories(${PROJECT_NAME} PRIVATE
  ${PROJECT_SOURCE_DIR}
  ${PROJECT_SOURCE_DIR}/include
  ${PROJECT_SOURCE_DIR}/include/CameraModels
  ${PROJECT_SOURCE_DIR}/3rdparty/Sophus
  ${OpenCV_INCLUDE_DIRS}
  ${EIGEN3_INCLUDE_DIR}
  ${Pangolin_INCLUDE_DIRS}
  ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h
)

add_subdirectory(3rdparty/g2o)

printlist(Pangolin_LIBRARIES)

target_link_libraries(${PROJECT_NAME}
${OpenCV_LIBS}
${EIGEN3_LIBS}
${Pangolin_LIBRARIES}
${PROJECT_SOURCE_DIR}/3rdparty/DBoW2/lib/libDBoW2.so
${PROJECT_SOURCE_DIR}/3rdparty/g2o/lib/libg2o.so
# ${PROJECT_SOURCE_DIR}/3rdparty/install/lib/libpango_windowing.so
# ${PROJECT_SOURCE_DIR}/3rdparty/install/lib/libpango_image.so
-lboost_serialization
-lcrypto
)
# print_target_linked_libraries(${PROJECT_NAME})
# print_target_included_directories(${PROJECT_NAME})

print_target_information(${PROJECT_NAME})



# install public headers
install(DIRECTORY include/
  DESTINATION include
)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_PROJECT_SOURCE_DIR}/lib)
install(TARGETS ${PROJECT_NAME}
  DESTINATION lib
)
