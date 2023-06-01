function(use_ccache_if_available)
    find_program(CCACHE_PROGRAM ccache)

    if(CCACHE_PROGRAM)
        set(BLUE)
        string(ASCII 27 ESC)
        set(RESET "${ESC}[0m")
        SET(BLUE "${ESC}[0;34m")

        set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
        set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")

        # CMake 3.9+
        # check if cmake supports CMAKE_CUDA_COMPILER_LAUNCHER
        if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.9)
            set(CMAKE_CUDA_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
            message(STATUS "${BLUE}Using ccache for CUDA compilation.${RESET}")
        endif()

        message(STATUS "${BLUE}Using ccache for compilation.${RESET}")
    endif()
endfunction()
