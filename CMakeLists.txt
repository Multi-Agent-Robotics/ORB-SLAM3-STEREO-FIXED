cmake_minimum_required(VERSION 2.8)
project(ORB_SLAM3)

string(ASCII 27 ESC)
set(RESET "${ESC}[0m")
set(RED "${ESC}[0;31m")
set(GREEN "${ESC}[0;32m")
SET(YELLOW "${ESC}[0;33m")
set(BLUE "${ESC}[0;34m")
set(MAGENTA "${ESC}[0;35m")
set(CYAN "${ESC}[0;36m")
set(WHITE "${ESC}[0;37m")
set(BOLDBLACK "${ESC}[1m${ESC}[30m")
set(BOLDRED "${ESC}[1m${ESC}[31m")
set(BOLDGREEN "${ESC}[1m${ESC}[32m")
set(BOLDYELLOW "${ESC}[1m${ESC}[33m")
set(BOLDBLUE "${ESC}[1m${ESC}[34m")
set(BOLDMAGENTA "${ESC}[1m${ESC}[35m")
set(BOLDCYAN "${ESC}[1m${ESC}[36m")
set(BOLDWHITE "${ESC}[1m${ESC}[37m")
set(BOLD "${ESC}[1m")
set(DIM "${ESC}[2m")
set(ITALIC "${ESC}[3m")
set(UNDERLINE "${ESC}[4m")
set(BLINK "${ESC}[5m")
set(REVERSE "${ESC}[7m")
set(HIDDEN "${ESC}[8m")

function(printvar var)
  # if var is a list of variables, print each one recursively
  
  # if var is empty or undefined, print in red
  if(NOT DEFINED ${var} OR "${${var}}" STREQUAL "")
    message(STATUS "${RED}${var}${RESET} = <empty>")
  else()
    message(STATUS "${GREEN}${var}${RESET} = ${${var}}")
  endif()
endfunction()

function(printlist var)
  message(STATUS "${GREEN}${var}${RESET} =")
  foreach(f ${${var}})
    message(STATUS "  ${f}")
  endforeach()
endfunction()

function(tree dir)
  message(STATUS "${GREEN}${dir}${RESET}")
  file(GLOB children RELATIVE ${dir} ${dir}/*)
  foreach(child ${children})
    if(IS_DIRECTORY ${dir}/${child})
      tree(${dir}/${child})
    else()
      message(STATUS "  ${dir}/${child}")
    endif()
  endforeach()
endfunction()

function(print_target_linked_libraries target)
  get_target_property(LINKED_LIBRARIES ${target} LINK_LIBRARIES)
  list(LENGTH LINKED_LIBRARIES LINKED_LIBRARIES_COUNT)
  message(STATUS "target ${GREEN}${target}${RESET} linked against ${CYAN}${LINKED_LIBRARIES_COUNT}${RESET} libraries:")
  foreach(link_lib ${LINKED_LIBRARIES})
    # if the library is a shared object file, check if it exists
    set(color ${BOLD})
    if(${link_lib} MATCHES "\\.so")
      if(NOT EXISTS ${link_lib})
        set(color ${RED})
      endif()  
    endif()
    message(STATUS " - ${color}${link_lib}${RESET}")
  endforeach()
  message(STATUS "")
endfunction()

function(print_target_included_directories target)
  get_target_property(INCLUDE_DIRECTORIES ${target} INCLUDE_DIRECTORIES)
  list(LENGTH INCLUDE_DIRECTORIES INCLUDE_DIRECTORIES_COUNT)
  message(STATUS "target ${green}${target}${RESET} include directories ${CYAN}${INCLUDE_DIRECTORIES_COUNT}${RESET}:")
  foreach(include_dir ${INCLUDE_DIRECTORIES})
    message(STATUS " - ${include_dir}")
  endforeach()
  message(STATUS "")
endfunction()

function(print_target_sources target)
  get_target_property(SOURCES ${target} SOURCES)
  list(LENGTH SOURCES SOURCES_COUNT)
  set(checkmark "✔")
  set(checkmark_color ${GREEN})
  set(cross "✘")
  set(cross_color ${RED})
  message(STATUS "target ${GREEN}${target}${RESET} sources ${CYAN}${SOURCES_COUNT}${RESET}: (${checkmark_color}${checkmark}${RESET} = exists, ${cross_color}${cross}${RESET} = does not exist)")
  foreach(source ${SOURCES})
    # if the source file does not exist, print in bold
    if (NOT EXISTS ${source})
      set(color ${RED})
      set(mark ${cross})
      set(mark_color ${cross_color})
    else()
      set(color ${BOLD})
      set(mark ${checkmark})
      set(mark_color ${checkmark_color})
    endif()
    message(STATUS " - [${mark_color}${mark}${RESET}] ${color}${source}${RESET}")
  endforeach()
  message(STATUS "")
endfunction()

function(print_target_compile_definitions target)
  get_target_property(COMPILE_DEFINITIONS ${target} COMPILE_DEFINITIONS)
  if (${COMPILE_DEFINITIONS} STREQUAL "COMPILE_DEFINITIONS-NOTFOUND")
    message(STATUS "compile definitions not found for target ${GREEN}${target}${RESET}")
    return()
  endif()
  list(LENGTH COMPILE_DEFINITIONS COMPILE_DEFINITIONS_COUNT)
  message(STATUS "target ${GREEN}${target}${RESET} compile definitions ${CYAN}${COMPILE_DEFINITIONS_COUNT}${RESET}:")
  foreach(compile_definition ${COMPILE_DEFINITIONS})
    message(STATUS " - ${compile_definition}")
  endforeach()
  message(STATUS "")
endfunction()

function(print_target_compile_features target)
  get_target_property(COMPILE_FEATURES ${target} COMPILE_FEATURES)
  if (${COMPILE_FEATURES} STREQUAL "COMPILE_FEATURES-NOTFOUND")
    message(STATUS "compile features not found for target ${GREEN}${target}${RESET}")
    return()
  endif()
  list(LENGTH COMPILE_FEATURES COMPILE_FEATURES_COUNT)
  message(STATUS "target ${GREEN}${target}${RESET} compile features ${CYAN}${COMPILE_FEATURES_COUNT}${RESET}:")
  foreach(compile_feature ${COMPILE_FEATURES})
    message(STATUS " - ${compile_feature}")
  endforeach()
  message(STATUS "")
endfunction()

function(print_target_compile_options target)
  get_target_property(COMPILE_OPTIONS ${target} COMPILE_OPTIONS)
  if (${COMPILE_OPTIONS} STREQUAL "COMPILE_OPTIONS-NOTFOUND")
    message(STATUS "compile options not found for target ${GREEN}${target}${RESET}")
    return()
  endif()
  list(LENGTH COMPILE_OPTIONS COMPILE_OPTIONS_COUNT)
  message(STATUS "target ${GREEN}${target}${RESET} compile options ${CYAN}${COMPILE_OPTIONS_COUNT}${RESET}:")
  foreach(compile_option ${COMPILE_OPTIONS})
    message(STATUS " - ${compile_option}")
  endforeach()
  message(STATUS "")
endfunction()

# target_link_directories()
function(print_target_link_directories target)
  get_target_property(LINK_DIRECTORIES ${target} LINK_DIRECTORIES)
  if (${LINK_DIRECTORIES} STREQUAL "LINK_DIRECTORIES-NOTFOUND")
    message(STATUS "link directories not found for target ${GREEN}${target}${RESET}")
    return()
  endif()
  list(LENGTH LINK_DIRECTORIES LINK_DIRECTORIES_COUNT)
  message(STATUS "target ${GREEN}${target}${RESET} link directories ${CYAN}${LINK_DIRECTORIES_COUNT}${RESET}:")
  foreach(link_directory ${LINK_DIRECTORIES})
    message(STATUS " - ${link_directory}")
  endforeach()
  message(STATUS "")
endfunction()


function(hr char n)
  set(line "")
  foreach(i RANGE ${n})
    set(line "${line}${char}")
  endforeach()
  message(STATUS "${line}")
endfunction()

function(print_target_information target)
  # determine if target is an executable or a library
  get_target_property(target_type ${target} TYPE)
  if(${target_type} STREQUAL "EXECUTABLE")
    set(target_type "executable")
  elseif(${target_type} STREQUAL "STATIC_LIBRARY")
    set(target_type "static library")
  elseif(${target_type} STREQUAL "SHARED_LIBRARY")
    set(target_type "shared library")
  else()
    set(target_type "unknown")
  endif()

  if(${target_type} STREQUAL "unknown")
    message(WARNING "target ${GREEN}${target}${RESET} is an unknown type")
    return()
  endif()
  
  set(n 100)
  set(delim "-")
  message(STATUS "target ${GREEN}${target}${RESET} is a ${CYAN}${target_type}${RESET}")
  hr(${delim} ${n})

  

  print_target_included_directories(${target})
  hr(${delim} ${n})
  print_target_linked_libraries(${target})
  hr(${delim} ${n})
  print_target_link_directories(${target})
  hr(${delim} ${n})
  print_target_sources(${target})
  hr(${delim} ${n})
  print_target_compile_definitions(${target})
  hr(${delim} ${n})
  print_target_compile_features(${target})
  hr(${delim} ${n})
  print_target_compile_options(${target})
  hr(${delim} ${n})
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

install(TARGETS ${PROJECT_NAME}
  DESTINATION lib
)