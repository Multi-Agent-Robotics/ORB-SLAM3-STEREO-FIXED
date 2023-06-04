cmake_minimum_required(VERSION 3.16.3 FATAL_ERROR) # default version on Ubuntu 20.04
project(g2o VERSION 0.1.0 LANGUAGES CXX C)

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

function(printlist var)
    list(LENGTH ${var} COUNT)
    message(STATUS "${GREEN}${var}${RESET} = (${CYAN}${COUNT}${RESET} elements)")
    set(i 0)

    foreach(f ${${var}})
        message(STATUS " ${i}. ${f}")
        math(EXPR i "${i} + 1")
    endforeach()
endfunction()

disallow_in_source_builds()

# disallow_system_install_prefix()
include(GNUInstallDirs) # for standard installation locations

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# set(CMAKE_LEGACY_CYGWIN_WIN32 0)
set(g2o_C_FLAGS)
set(g2o_CXX_FLAGS)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# There seems to be an issue with MSVC8
# see http://eigen.tuxfamily.org/bz/show_bug.cgi?id=83
# if(MSVC90)
# add_definitions(-DEIGEN_DONT_ALIGN_STATICALLY=1)
# message(STATUS "Disabling memory alignment for MSVC8")
# endif(MSVC90)

# Set the output directory for the build executables and libraries
# IF(WIN32)
# set(g2o_LIBRARY_OUTPUT_DIRECTORY ${g2o_SOURCE_DIR}/bin CACHE PATH "Target for the libraries")
# ELSE(WIN32)
# set(g2o_LIBRARY_OUTPUT_DIRECTORY ${g2o_SOURCE_DIR}/lib CACHE PATH "Target for the libraries")
# ENDIF(WIN32)
# set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${g2o_LIBRARY_OUTPUT_DIRECTORY})
# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${g2o_LIBRARY_OUTPUT_DIRECTORY})
# set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${g2o_RUNTIME_OUTPUT_DIRECTORY})

# Set search directory for looking for our custom CMake scripts to
# look for SuiteSparse, QGLViewer, and Eigen3.
# LIST(APPEND CMAKE_MODULE_PATH ${g2o_SOURCE_DIR}/cmake_modules)

# Detect OS and define macros appropriately
if(UNIX)
    add_definitions(-DUNIX)
    message(STATUS "Compiling on Unix")
endif()

# Eigen library parallelise itself, though, presumably due to performance issues
# OPENMP is experimental. We experienced some slowdown with it
find_package(OpenMP)
set(G2O_USE_OPENMP OFF CACHE BOOL "Build g2o with OpenMP support (EXPERIMENTAL)")

if(OPENMP_FOUND AND G2O_USE_OPENMP)
    set(G2O_OPENMP 1)
    set(g2o_C_FLAGS "${g2o_C_FLAGS} ${OpenMP_C_FLAGS}")
    set(g2o_CXX_FLAGS "${g2o_CXX_FLAGS} -DEIGEN_DONT_PARALLELIZE ${OpenMP_CXX_FLAGS}")
    message(STATUS "Compiling with OpenMP support")
endif(OPENMP_FOUND AND G2O_USE_OPENMP)

# Find Eigen3
# set(EIGEN3_INCLUDE_DIR ${G2O_EIGEN3_INCLUDE})
find_package(Eigen3 3.1.0 REQUIRED)

# if(EIGEN3_FOUND)
# set(G2O_EIGEN3_INCLUDE ${EIGEN3_INCLUDE_DIR} CACHE PATH "Directory of Eigen3")
# else()
# set(G2O_EIGEN3_INCLUDE "" CACHE PATH "Directory of Eigen3")
# endif()

# Compiler specific options for gcc
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -march=native")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3 -march=native")

# activate warnings !!!
set(g2o_C_FLAGS "${g2o_C_FLAGS} -Wall")
set(g2o_CXX_FLAGS "${g2o_CXX_FLAGS} -Wall")

# specifying compiler flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${g2o_CXX_FLAGS}")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${g2o_C_FLAGS}")

# Generate config.h
set(G2O_CXX_COMPILER "${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER}")
configure_file(g2o/config.h.in ${g2o_SOURCE_DIR}/g2o/config.h)

# create the library
add_library(${PROJECT_NAME} SHARED "")
target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)
target_include_directories(${PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/g2o>

    # $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/g2o>
    # $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/g2o/core>
    # $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/g2o/solvers>
    # $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/g2o/stuff>
    # $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/g2o/types>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/g2o>
    ${EIGEN3_INCLUDE_DIR}
)
target_compile_options(${PROJECT_NAME} PRIVATE
    -Wall

    # $<$<CONFIG:Release>:-O3 -march=native>
    # $<$<CONFIG:Debug>:-O0 -g>
)

file(GLOB_RECURSE G2O_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

# Include the subdirectories
# add_library(${PROJECT_NAME} SHARED
target_sources(${PROJECT_NAME} PRIVATE

    # types
    g2o/types/types_sba.h
    g2o/types/types_six_dof_expmap.h
    g2o/types/types_sba.cpp
    g2o/types/types_six_dof_expmap.cpp
    g2o/types/types_seven_dof_expmap.cpp
    g2o/types/types_seven_dof_expmap.h
    g2o/types/se3quat.h
    g2o/types/se3_ops.h
    g2o/types/se3_ops.hpp

    # core
    g2o/core/base_edge.h
    g2o/core/base_binary_edge.h
    g2o/core/hyper_graph_action.cpp
    g2o/core/base_binary_edge.hpp
    g2o/core/hyper_graph_action.h
    g2o/core/base_multi_edge.h
    g2o/core/hyper_graph.cpp
    g2o/core/base_multi_edge.hpp
    g2o/core/hyper_graph.h
    g2o/core/base_unary_edge.h
    g2o/core/linear_solver.h
    g2o/core/base_unary_edge.hpp
    g2o/core/marginal_covariance_cholesky.cpp
    g2o/core/base_vertex.h
    g2o/core/marginal_covariance_cholesky.h
    g2o/core/base_vertex.hpp
    g2o/core/matrix_structure.cpp
    g2o/core/batch_stats.cpp
    g2o/core/matrix_structure.h
    g2o/core/batch_stats.h
    g2o/core/openmp_mutex.h
    g2o/core/block_solver.h
    g2o/core/block_solver.hpp
    g2o/core/parameter.cpp
    g2o/core/parameter.h
    g2o/core/cache.cpp
    g2o/core/cache.h
    g2o/core/optimizable_graph.cpp
    g2o/core/optimizable_graph.h
    g2o/core/solver.cpp
    g2o/core/solver.h
    g2o/core/creators.h
    g2o/core/optimization_algorithm_factory.cpp
    g2o/core/estimate_propagator.cpp
    g2o/core/optimization_algorithm_factory.h
    g2o/core/estimate_propagator.h
    g2o/core/factory.cpp
    g2o/core/optimization_algorithm_property.h
    g2o/core/factory.h
    g2o/core/sparse_block_matrix.h
    g2o/core/sparse_optimizer.cpp
    g2o/core/sparse_block_matrix.hpp
    g2o/core/sparse_optimizer.h
    g2o/core/hyper_dijkstra.cpp
    g2o/core/hyper_dijkstra.h
    g2o/core/parameter_container.cpp
    g2o/core/parameter_container.h
    g2o/core/optimization_algorithm.cpp
    g2o/core/optimization_algorithm.h
    g2o/core/optimization_algorithm_with_hessian.cpp
    g2o/core/optimization_algorithm_with_hessian.h
    g2o/core/optimization_algorithm_levenberg.cpp
    g2o/core/optimization_algorithm_levenberg.h
    g2o/core/optimization_algorithm_gauss_newton.cpp
    g2o/core/optimization_algorithm_gauss_newton.h
    g2o/core/jacobian_workspace.cpp
    g2o/core/jacobian_workspace.h
    g2o/core/robust_kernel.cpp
    g2o/core/robust_kernel.h
    g2o/core/robust_kernel_factory.cpp
    g2o/core/robust_kernel_factory.h
    g2o/core/robust_kernel_impl.cpp
    g2o/core/robust_kernel_impl.h

    # stuff
    g2o/stuff/string_tools.h
    g2o/stuff/color_macros.h
    g2o/stuff/macros.h
    g2o/stuff/timeutil.cpp
    g2o/stuff/misc.h
    g2o/stuff/timeutil.h
    g2o/stuff/os_specific.c
    g2o/stuff/os_specific.h
    g2o/stuff/string_tools.cpp
    g2o/stuff/property.cpp
    g2o/stuff/property.h
)

# using GnuInstallDirs after cmake 3.14 makes it so you
# do not have to specify the full path of RUNTIME DESTINATION etc.
# install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}Targets)

# target_include_directories(${PROJECT_NAME}
# PUBLIC
# $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/g2o>
# $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/g2o/core>
# $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/g2o/stuff>
# $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/g2o/solvers>
# $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/g2o/types>

# $<INSTALL_INTERFACE:include/g2o>
# $<INSTALL_INTERFACE:include/g2o/core>
# $<INSTALL_INTERFACE:include/g2o/stuff>
# $<INSTALL_INTERFACE:include/g2o/solvers>
# $<INSTALL_INTERFACE:include/g2o/types>
# ${EIGEN3_INCLUDE_DIR}
# )
target_link_libraries(${PROJECT_NAME}
    PUBLIC
    ${EIGEN3_LIBS}
)

target_compile_options(${PROJECT_NAME} PRIVATE
    -Wno-deprecated-declarations # suppress warnings from Eigen3
)

export(TARGETS ${PROJECT_NAME} FILE ${PROJECT_NAME}Targets.cmake)
set(CMAKE_EXPORT_PACKAGE_REGISTRY ON)
export(PACKAGE ${PROJECT_NAME})

# # install headers
# # install(FILES ${G2O_HEADERS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME})

# # Export the export set for downstream projects
# install(EXPORT ${PROJECT_NAME}Targets
# DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}Targets
# NAMESPACE ${PROJECT_NAME}::
# )

# # make the library importable from downstream projects with find_package()
# include(CMakePackageConfigHelpers)

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
# write_basic_package_version_file(
# ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
# VERSION ${PROJECT_VERSION}
# COMPATIBILITY SameMajorVersion
# )

# install(FILES
# ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
# DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
# )

# # install(FILES config.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME})

# # Install header files
# foreach(extension in h hpp)
# install(DIRECTORY g2o
# DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
# FILES_MATCHING PATTERN "*.${extension}"
# )
# endforeach()

# # install(DIRECTORY g2o
# # DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
# # FILES_MATCHING PATTERN "*.h"
# # )

# # install(
# # FILES ${G2O_HEADERS}
# # DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
# # )
