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
