# cmake 部署小提示

## 如何使得`cmake install`搭配`vc++`运行时?

当使用`cmake install`构建安装包时,可能要附带上`vc++`运行时,可以使用如下脚本:

```cmake
include(InstallRequiredSystemLibraries)
```

具体参见文档[InstallRequiredSystemLibraries](https://cmake.org/cmake/help/latest/module/InstallRequiredSystemLibraries.html)

## 如何将应用程序依赖的动态库输出到应用程序路径?

这有两种情况,第一种是动态库和应用程序属于同一个工程;另一种是依赖的第三方动态库.

### 同工程的动态库

`cmake`提供的`CMAKE_LIBRARY_OUTPUT_DIRECTORY`变量决定了库文件输出路径,`CMAKE_RUNTIME_OUTPUT_DIRECTORY`变量决定了动态库和应用程序输出路径,可以将其修改到同一个路径,例如:

```cmake
##将动态库输出路径定位到特定路径,供调试时使用(否则依赖的库分布在各个文件夹)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIG>")
```

### 第三方动态库

这里假设都已经以`Modern CMake`方式提供了`imported target`,针对特定`target`提供生成后动作如下:
```cmake
add_custom_command(TARGET ${_target} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy 
    $<TARGET_FILE:${_dep}> 
    $<TARGET_FILE_DIR:${_target}>/$<TARGET_FILE_NAME:${_dep}>
    
    COMMENT "Copying required dynamic library for dependency ${_dep}"
    VERBATIM
)
```
其中`_target`为要生成的应用程序或者库,`_dep`为依赖的库`imported target`名称.以函数方式实现如下:

```cmake
##用来在生成时复制导入的库
function(copy_imported_targets _target)
    foreach(_dep ${ARGN})
        add_custom_command(TARGET ${_target} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy 
            $<TARGET_FILE:${_dep}> 
            $<TARGET_FILE_DIR:${_target}>/$<TARGET_FILE_NAME:${_dep}>
            
            COMMENT "Copying required dynamic library for dependency ${_dep}"
            VERBATIM
        )
    endforeach()
endfunction()
```

在`install`时的处理更为简单:

```cmake
install(FILES $<TARGET_FILE:${_dep}> DESTINATION  <dir> )
```

## 如何复制运行时资源到应用程序路径

使用`cmake`的`add_custom_command`和命令模式:

```cmake
add_custom_command(TARGET ${_target} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${PROJECT_SOURCE_DIR}/data"
        $<TARGET_FILE_DIR:${_target}>)
```

或者是复制特定文件:

```cmake
add_custom_command(TARGET ${_target} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${PROJECT_SOURCE_DIR}/file.ext"
        $<TARGET_FILE_DIR:${_target}>)
```

## 如何使自定义`target`默认执行

通过`add_custom_target`添加的`target`构建时不会自动执行,可以采用如下操作:

```cmake
add_custom_target(target_name ALL)
```

也可以将`add_custom_target`要执行的命令直接写成如下形式:

```cmake
add_custom_target(target_name ALL
    COMMAND "echo custom target"
)
```

## 如何获取目标依赖的动态库列表

参见下列链接:

- [GetPrerequisites](https://cmake.org/cmake/help/latest/module/GetPrerequisites.html)
- [how to use the cmake functions get_prerequisites and get_filename_component for target dependency installation?](https://stackoverflow.com/questions/24367033/how-to-use-the-cmake-functions-get-prerequisites-and-get-filename-component-for)
- [Recursive list of LINK_LIBRARIES in CMake](https://stackoverflow.com/questions/32756195/recursive-list-of-link-libraries-in-cmake)

这部分内容感觉还是相对比较混乱的,`vcpkg`使用的解决方案是利用原生`dumpbin`输出然后用`powershell`脚本完成这个内容.