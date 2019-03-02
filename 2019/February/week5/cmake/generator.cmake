set(_generator_path ${CMAKE_CURRENT_LIST_DIR})


##生成包配置
function(generate_package)
    cmake_parse_arguments(Gen "" "package_name;output_path" "" ${ARGN})

    if(NOT DEFINED Gen_package_name)
        message(FATAL_ERROR "generate_package should config package_name")
    endif()

    if(NOT DEFINED Gen_output_path)
        message(FATAL_ERROR "generate_package should config output_path")
    endif()    

    set(PACKAGE_NAME  ${Gen_package_name})
    set(OUTPUT_PATH   ${Gen_output_path})    

    configure_file(
        ${_generator_path}/package-config.cmake.in
        "${OUTPUT_PATH}/${PACKAGE_NAME}/${PACKAGE_NAME}-config.cmake"
        @ONLY
    )

    message(STATUS "generate ${OUTPUT_PATH}/${PACKAGE_NAME}/${PACKAGE_NAME}-config.cmake")    
endfunction()

##生成库配置
function(generate_library)
    cmake_parse_arguments(Gen  "" 
        "package_name;output_path;library_name;install_rpath;lib_x86_rpath;dll_x86_rpath;lib_x64_rpath;dll_x64_rpath;lib_x86_d_rpath;dll_x86_d_rpath;lib_x64_d_rpath;dll_x64_d_rpath;lib_x86;lib_x64;dll_x86;dll_x64;lib_x86_d;lib_x64_d;dll_x86_d;dll_x64_d;" 
        "dependencies;compile_definitions;include_dirs" 
        ${ARGN}
        )

    if(NOT DEFINED Gen_package_name)
        message(FATAL_ERROR "generate_library should config package_name")
    endif()
    if(NOT DEFINED Gen_output_path)
        message(FATAL_ERROR "generate_library should config output_path")
    endif()
    if(NOT DEFINED Gen_library_name)
        message(FATAL_ERROR "generate_library should config library_name")
    endif()
    if(NOT DEFINED Gen_install_rpath)
        message(FATAL_ERROR "generate_library should config install_rpath")
    endif()            

    set(PACKAGE_NAME ${Gen_package_name})
    set(OUTPUT_PATH  ${Gen_output_path})  
    set(LIBRARY_NAME ${Gen_library_name})  
    #message(STATUS "设置的相对路径为:${Gen_install_rpath}")
    set(LIBRARY_RELATIVE_PATH ${Gen_install_rpath})    
    
    if(NOT "${Gen_dependencies}" STREQUAL "")
        #message(STATUS "${Gen_dependencies}")
        set(LIBRARY_DEPENDENCIES "${Gen_dependencies}")
    else()
        set(LIBRARY_DEPENDENCIES "")
    endif()

    if(Gen_compile_definitions)
        set(LIBRARY_COMPILE_DEFINITIONS "${Gen_compile_definitions}")
    else()
        set(LIBRARY_COMPILE_DEFINITIONS "")
    endif()

    if(Gen_include_dirs)
        set(LIBRARY_INCLUDE_DIRS "${Gen_include_dirs}")
    else()
        set(LIBRARY_INCLUDE_DIRS "")
    endif() 

    if(Gen_lib_x86_d_rpath AND Gen_lib_x86_d)
        set(IMPORTED_IMPLIB_X86_DEBUG_RPATH "${Gen_lib_x86_d_rpath}/${Gen_lib_x86_d}")
    else()
        set(IMPORTED_IMPLIB_X86_DEBUG_RPATH "")
    endif()

    if(Gen_lib_x86_rpath AND Gen_lib_x86)
        set(IMPORTED_IMPLIB_X86_RELEASE_RPATH "${Gen_lib_x86_rpath}/${Gen_lib_x86}")
    else()
        set(IMPORTED_IMPLIB_X86_RELEASE_RPATH "")
    endif()
    
    if(Gen_lib_x64_d_rpath AND Gen_lib_x64_d)
        set(IMPORTED_IMPLIB_X64_DEBUG_RPATH "${Gen_lib_x64_d_rpath}/${Gen_lib_x64_d}")
    else()
        set(IMPORTED_IMPLIB_X64_DEBUG_RPATH "")
    endif()

    if(Gen_lib_x64_rpath AND Gen_lib_x64)
        set(IMPORTED_IMPLIB_X64_RELEASE_RPATH "${Gen_lib_x64_rpath}/${Gen_lib_x64}")
    else()
        set(IMPORTED_IMPLIB_X64_RELEASE_RPATH "")
    endif()
        
       
    if(Gen_dll_x86_d_rpath AND Gen_dll_x86_d)
        set(IMPORTED_LOCATION_X86_DEBUG_RPATH "${Gen_dll_x86_d_rpath}/${Gen_dll_x86_d}")
    else()
        set(IMPORTED_LOCATION_X86_DEBUG_RPATH "")
    endif()

    if(Gen_dll_x86_rpath AND Gen_dll_x86)
        set(IMPORTED_LOCATION_X86_RELEASE_RPATH "${Gen_dll_x86_rpath}/${Gen_dll_x86}")
    else()
        set(IMPORTED_LOCATION_X86_RELEASE_RPATH "")
    endif()
    
    if(Gen_dll_x64_d_rpath AND Gen_dll_x64_d)
        set(IMPORTED_LOCATION_X64_DEBUG_RPATH "${Gen_dll_x64_d_rpath}/${Gen_dll_x64_d}")
    else()
        set(IMPORTED_LOCATION_X64_DEBUG_RPATH "")
    endif()

    if(Gen_dll_x64_rpath AND Gen_dll_x64)
        set(IMPORTED_LOCATION_X64_RELEASE_RPATH "${Gen_dll_x64_rpath}/${Gen_dll_x64}")
    else()
        set(IMPORTED_LOCATION_X64_RELEASE_RPATH "")
    endif()    

    configure_file(
        ${_generator_path}/library-config.cmake.in
        "${OUTPUT_PATH}/${LIBRARY_NAME}/${LIBRARY_NAME}-config.cmake"
        @ONLY
    )
endfunction()