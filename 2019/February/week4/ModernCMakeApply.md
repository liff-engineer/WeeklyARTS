# 应用 Modern CMake

"Modern CMake" 虽然和 "Modern C++" 一样看起来美好,但是,真正用起来却比较艰难,关键是没有良好的实践指南. 这里我将通过自身实践展示一下如何在项目中应用"Modern CMake".

## 推荐的"Project Layout"

建议采用如下的"Project Layout",具体含义可参见[cxx-pflR1 The Pitchfork Layout (PFL)](https://api.csswg.org/bikeshed/?force=1&url=https://raw.githubusercontent.com/vector-of-bool/pitchfork/develop/data/spec.bs):

- include
  - library_name
- src
  - CMakeLists.txt
- doc
- examples
- test
- cmake
- CMakeLists.txt

其中`cmake`将会存储要使用到的`CMake`脚本.

如果项目中包含多个库及 Application,则可采用如下布局:

- cmake
- library1
  - include
  - src
  - test
  - CMakeLists.txt
- library2
  - include
  - src
  - test
  - CMakeLists.txt
- libraryN
  - ......
- ......
- CMakeLists.txt

## 最外层的工程级`CMakeLists.txt`

最外层的`CMakeLists.txt`通常包含项目的全局配置信息,然后通过`add_subdirectory`导入子项目的`CMakeLists.txt`.

基础配置如下:

```CMAKE
##cmake版本要求
cmake_minimum_required(VERSION 3.12)

##工程基本信息
project(project_name
    LANGUAGES CXX
    VERSION  1.0.0
)

##Windows下符号自动导出
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

##Windows下调试文件后缀
if(MSVC)
    set(CMAKE_DEBUG_POSTFIX "d")
endif()

##禁止编译器的语言扩展来避免引入不可移植代码
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_EXTENSIONS OFF)

##将本目录下的cmake文件夹导入CMAKE_MODULE_PATH
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

option(BUILD_SHARED_LIBS "构建动态库而不是静态库" ON)

if(NOT CMAKE_CONFIGURATION_TYPES)
    if(NOT CMAKE_BUILD_TYPE)
        message(STATUS "如果没有设置构建类型,将其设置为'Release'.")
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY VALUE "Release")
    endif()
endif()

##导入"子项目"
add_subdirectory(src)
```

最外层的工程级`CMakeLists.txt`还需要处理库的导出动作.这部分将在后续讲解.

## 项目的`CMakeLists.txt`

项目的`CMakeLists.txt`如果"Project Layout"一致,则基本上一样:

```CMAKE
##查找依赖库
find_package(Qt5 COMPONENTS Core Widgets REQUIRED)

##设置库名称,后续全部使用该变量
set(LIBRARY_TARGET_NAME library_name)

##从include和src下抓取所有头文件和源文件
file(GLOB_RECURSE  ${LIBRARY_TARGET_NAME}_FILES
    LIST_DIRECTORIES False
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    "include/*.h*"
    "src/*.c*"
    "src/*.h*"
)

##添加库
add_library(${LIBRARY_TARGET_NAME}
  ${${LIBRARY_TARGET_NAME}_FILES}
)

##添加库别名供导出使用
add_library(${PROJECT_NAME}::${LIBRARY_TARGET_NAME} ALIAS ${LIBRARY_TARGET_NAME})

#设置库版本号
set_target_properties(
    ${LIBRARY_TARGET_NAME}
    PROPERTIES
    VERSION ${${PROJECT_NAME}_VERSION}
)

##设置预处理器定义等
if(MSVC)
    target_compile_definitions(${LIBRARY_TARGET_NAME} PRIVATE _SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS)
endif()

##设置构造时头文件路径和安装时头文件路径
target_include_directories(
    ${LIBRARY_TARGET_NAME}
    PUBLIC
      "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
      "$<INSTALL_INTERFACE:include>"
    PRIVATE
      "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>"
)

##配置库依赖
target_link_libraries(${LIBRARY_TARGET_NAME} PUBLIC Qt5::Core Qt5::Widgets)

##处理库安装动作
install(DIRECTORY include/ DESTINATION include)
install(TARGETS ${LIBRARY_TARGET_NAME}
    EXPORT ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)
```

其中抓取源文件列表的动作写起来比较复杂,而且具备通用性,则可以实现为"CMake"脚本-"grap_sources.cmake":

```CMAKE
##从标准目录下抓取源代码文件
##并为Visual Studio工程提供文件分组

function(prefab_grab_sources TARGET_SOURCES)
    ##从include和src两个目录抓取所有源代码
    file(GLOB_RECURSE  TARGET_FILES
        LIST_DIRECTORIES False
        RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
        "include/*.h*"
        "src/*.c*"
        "src/*.h*"
    )

    ##为Visual Studio建立文件分组
    foreach(FILE ${TARGET_FILES})
        get_filename_component(PARENT_DIR "${FILE}" PATH)

        string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}" "" GROUP "${PARENT_DIR}")
        string(REPLACE "/" "\\" GROUP "${PARENT_DIR}")

        if ("${FILE}" MATCHES ".*\\.cpp")
            set(GROUP "Source Files\\${GROUP}")
        elseif("${FILE}" MATCHES ".*\\.hpp")
            set(GROUP "Header Files\\${GROUP}")
        endif()

        source_group("${GROUP}" FILES "${FILE}")
    endforeach()

    set(${TARGET_SOURCES} ${TARGET_FILES}  PARENT_SCOPE)
endfunction()
```

然后在最外层`CMakeLists.txt`的`add_subdirectory`之前使用`include`导入:

```CMAKE
include(grap_sources)
```

然后工程的`CMakeLists.txt`可以以如下方式使用:

```CMAKE
grab_sources(
  ${LIBRARY_TARGET_NAME}_FILES
)
```

这时新增库可以以此为模板,通常只需要调整库名和库依赖即可.

## 库之间依赖的处理

在同一个工程里的各个项目之间如果互相依赖,则可以使用`target_link_libraries`来处理:

```CMAKE
target_link_libraries(${LIBRARY_TARGET_NAME}
    PUBLIC ${PROJECT_NAME}::library1  ##根据情况来确定PUBLIC还是PRIVATE
    PRIVATE ${PROJECT_NAME}::library2
    )
```

## 库安装及导出

通过上述方式,就可以正确的构建整个项目了,但是如果你的库想要让人以如下方式使用:

```CMAKE
find_package(library_name CONFIG REQUIRED)
target_link_libraries(${LIBRARY_TARGET_NAME} PRIVATE library_name::library1
```

则还需要导出动作,通常是三个文件:

- library-name-targets.cmake : 导出项目中定义的`target`
- library-name-config.cmake : 检查`library-name`依赖,导入`library-name-targets.cmake`
- library-name-config-version.cmake :版本控制

`library-name-targets.cmake`实现非常简单:

```CMAKE
install(EXPORT ${PROJECT_NAME}
    NAMESPACE ${PROJECT_NAME}::
    FILE      ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)
```

然后是`library-name-config.cmake`,`CMake`文档建议实现如下:

```CMAKE
include(CMakePackageConfigHelpers)
configure_package_config_file(
    cmake/${PROJECT_NAME}-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
    INSTALL_DESTINATION  lib/cmake/${PROJECT_NAME}
)
```

而`library-name-config.cmake.in`则通常位于`cmake`中,实现类似如下方式:

```CMAKE
@PACKAGE_INIT@

##查找库必须的依赖
include(CMakeFindDependencyMacro)
find_dependency(Boost REQUIRED COMPONENTS system)

include("${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}-targets.cmake")
check_required_components("${PROJECT_NAME}")
```

然后是`library-name-config-version.cmake`:

```CMAKE
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
    COMPATIBILITY AnyNewerVersion #兼容性版本设置
)
```

综合以上,最外层的`CMakeLists.txt`需要在最后追加如下内容完成导出动作:

```CMAKE
include(CMakePackageConfigHelpers)
configure_package_config_file(
    cmake/${PROJECT_NAME}-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
    INSTALL_DESTINATION  lib/cmake/${PROJECT_NAME}
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
    COMPATIBILITY AnyNewerVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)

install(EXPORT ${PROJECT_NAME}
    NAMESPACE ${PROJECT_NAME}::
    FILE      ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)

export(PACKAGE ${PROJECT_NAME})
```

## 如何使用

现在就可以在使用`CMake`构建时选择`install`目标,安装到指定目录:

```CMD
mkdir build
cd build
cmake ..  -DCMAKE_INSTALL_PREFIX:PATH=install_loc
cmake --build . --target install
```

然后针对其它项目,可以以如下方式使用:

- 将`install_loc`导入到`CMAKE_PREFIX_PATH`

  ```CMAKE
  list(APPEND CMAKE_PREFIX_PATH "${install_loc}")
  ```

- 使用`find_package`以及`target_link_libraries`

  ```CMAKE
  find_package(library_name CONFIG REQUIRED)
  target_link_libraries(${LIBRARY_TARGET_NAME} PRIVATE library_name::library1
  ```

## 如何使能测试

### 使用`Catch2`

```CMAKE

add_executable(${TestRunner})
#target_sources(${TestRunner} ......)
target_link_libraries(${TestRunner} Catch2::Catch2)

enable_testing()
include(CTest)
include(Catch)
catch_discover_tests(${TestRunner})
```

### 使用`gtest`

```CMAKE
find_package(GTest REQUIRED)

add_executable(${TestRunner})
#target_sources(${TestRunner} ......)
target_link_libraries(${TestRunner} PRIVATE GTest::GTest GTest::Main)

enable_testing()
gtest_discover_tests(${TestRunner})
```

## 使用 Qt

### 同时配置 Qt 的`32`位和`64`位版本

```CMAKE
##本地编辑时正确配置QT路径
if(CMAKE_SIZEOF_VOID_P EQUAL 4) #32位工具集
    list(APPEND CMAKE_PREFIX_PATH "C:/Qt/5.6.3/msvc2015")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)#64位工具集
    list(APPEND CMAKE_PREFIX_PATH "C:/Qt/5.6.3/msvc2015_64")
endif()
```

### 开启自动`moc`、`uic`等

```CMAKE
#开启自动moc
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set_target_properties(${LIBRARY_TARGET_NAME} PROPERTIES
    AUTOMOC ON
)

#开启自动uic
set_target_properties(${LIBRARY_TARGET_NAME} PROPERTIES
    AUTOUIC ON
)
```

## `MSVC`使用预编译头

```CMAKE
if(MSVC)
  list(REMOVE_ITEM ${LIBRARY_TARGET_NAME}_FILES "${CMAKE_CURRENT_SOURCE_DIR}/src/stdafx.cpp")

  #单独为stdafx.cpp指定预编译头
  set_source_files_properties(
      "${CMAKE_CURRENT_SOURCE_DIR}/src/stdafx.cpp"
      PROPERTIES COMPILE_FLAGS "/Ycstdafx.h"
  )

  #为每个文件指定预编译头
  foreach(SRC_FILE ${LIBRARY_TARGET_NAME}_FILES)
    set_source_files_properties(
        ${SRC_FILE}
        PROPERTIES COMPILE_FLAGS "/Yustdafx.h"
    )
  endforeach()

  list(APPEND ${LIBRARY_TARGET_NAME}_FILES "${CMAKE_CURRENT_SOURCE_DIR}/src/stdafx.cpp")
endif()
```

然后如果是使用了 Qt 的自动`moc`,则在有些场景下需要为其也配置预编译头,毕竟有些开发比较浪.

```CMAKE
##CMake Qt Moc 与预编译头
set_target_properties(${LIBRARY_TARGET_NAME} PROPERTIES
    AUTOMOC_MOC_OPTIONS "-bstdafx.h"
)
```

## 如果依赖的第三方库不支持`CMake`

通常是理想很丰满,现实很骨感,如果依赖的第三方库不支持`CMake`,有两个选择:

1. 有源代码的情况下,为第三方库提供上述`CMake`构建脚本,为自己所用
2. 有二进制文件的情况下,实现`library-targets.cmake`,在项目中按照常规库使用

这里说一下第二种情况,假设你有个二进制库形式如下:

- library
  - include
  - lib
    - Win32
      - Debug
        - libraryd.lib
      - Release
        - library.lib
    - x64
      - Debug
        - libraryd.lib
      - Release
        - library.lib
  - bin

那么`library-targets.cmake`可以实现成如下形式:

```CMAKE
if(NOT TARGET library)
    set(library_SOURCE_DIR "library二进制路径")

    set(library_INCLUDE_DIR "${library_SOURCE_DIR}/include")
    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
        set(library_LIBRARYS_DEBUG "${library_SOURCE_DIR}/lib/Win32/Debug/libraryd.lib")
        set(library_LIBRARYS_RELEASE "${library_SOURCE_DIR}/lib/Win32/Release/library.lib")
    elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(library_LIBRARYS_DEBUG "${library_SOURCE_DIR}/lib/x64/Debug/libraryd.lib")
        set(library_LIBRARYS_RELEASE "${library_SOURCE_DIR}/lib/x64/Release/library.lib")
    endif()

    add_library(library INTERFACE IMPORTED)
    #target_include_directories(library INTERFACE ${library_INCLUDE_DIR})
    target_link_libraries(library INTERFACE
        $<$<CONFIG:Debug>:${library_LIBRARYS_DEBUG}>
        $<$<CONFIG:Release>:${library_LIBRARYS_RELEASE}>
        $<$<CONFIG:MinSizeRel>:${library_LIBRARYS_RELEASE}>
        $<$<CONFIG:RelWithDebInfo>:${library_LIBRARYS_RELEASE}>
        )
endif()
```

将`library-targets.cmake`置于项目的`cmake`文件夹,然后在最外层`CMakeLists.txt`中使用`include(library-targets)`导入.之后以如下方式使用:

```CMAKE
target_link_libraries(${LIBRARY_TARGET_NAME} PRIVATE library)
```

注意`library_INCLUDE_DIR`等支持列表形式,如果有多个库也是可以设置的.

## 总结

`Modern CMake`确实变得不一样了,在使用的过程中也相对比较愉悦.随着各种 IDE 对`CMake`的支持越来越好,选择`Modern CMake`进行学习是不错的选择.
