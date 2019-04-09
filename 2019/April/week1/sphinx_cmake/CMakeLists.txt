cmake_minimum_required(VERSION 3.12)

project(example)

option(BUILD_DOCUMENT "Build document" ON)
if(BUILD_DOCUMENT)
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/sphinx_conf.py.in"
        "${CMAKE_BINARY_DIR}/conf.py"
        @ONLY 
    )

    set(SPHINX_CACHE_DIR "${CMAKE_BINARY_DIR}/sphinx_cache")
    set(SPHINX_OUTPUT_DIR "${CMAKE_BINARY_DIR}/doc")
    
    find_program(SPHINX NAMES sphinx-build)
    add_custom_target(DocGen ALL
        ${SPHINX}
        -b html 
        -d "${SPHINX_CACHE_DIR}"
        -c "${CMAKE_BINARY_DIR}"
        "${CMAKE_CURRENT_SOURCE_DIR}/docs"
        "${SPHINX_OUTPUT_DIR}"
        COMMENT "Building HTML documentation with Sphinx"
    )
endif()

