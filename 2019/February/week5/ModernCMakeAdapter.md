# 为现有二进制库提供 `Modern CMake` 适配

上一周的文章讲述了如何使用`Modern CMake`.不过现在新问题来了,在项目中使用`Modern CMake`最大的障碍就是所依赖的数量**庞大**的二进制库.一个大型项目从小型项目开始慢慢膨胀,配置也在不断增加,贸然更换构建系统,是不是要付出非常大的代价?

是,但也不是.

在[Effective Modern CMake: a great summary of most good practices - by Manuel Binna](https://www.reddit.com/r/cpp/comments/8q8268/effective_modern_cmake_a_great_summary_of_most/)中,作者提到:

> Report it as a bug to third-party library authors if a library does not support clients to use CMake. CMake dominates the industry. It’s a problem if a library author does not support CMake.

看法自然有些"偏激",之前我也这样认为,但是自从我看完 Kate Gregory [Oh The Humanity!](https://www.youtube.com/watch?v=SzoquBerhUc)的演讲之后.我觉得,如果一个 C++库的作者不试图提供 CMake 支持,这确实是他的问题. 排除开源库只是为了自己开心的场景,谁不是希望自己的开源库能够被广泛使用? 那么是不是应当考虑使用者的"用户体验"? CMake 在 C++开发者中应用广泛,也能够很方便地使用,为什么不提供这种支持?

所以,我目前的看法是,如果你依赖的二进制库能够找到源代码或者公司内部的开发/维护团队,让他们提供 CMake 支持! 或者你自己为其写 CMake 构建脚本.提供`target export`.

毕竟现实比较残酷,下面咱们还是先来说一下在只有二进制的`SDK`场景下,如何为其提供`Modern CMake`适配.

## 回顾一下`C++`的构建

C++的构建分为编译和链接两步:

- 编译

  编译是从源文件生成`.obj`文件,过程中不可避免要使用到头文件,如果不是引用相同目录的头文件,则需要指定头文件路径.而且由于预处理器的存在,有时候还需要指定预处理器定义.当然还有一些编译选项之类的.

- 链接

  链接是指将`.obj`整合成动态库或者应用程序.如果使用到的类/函数实现等等不在要链接的`.obj`文件中,则需要指定其符号在哪里,这时候在 MSVC 中就需要导出库/静态库`.lib`的依赖配置.如果找不到使用的符号,则会查询依赖的`.lib`.

也就是说,如果要使用一个第三方库,正常情况下需要配置三项内容:

1. 头文件路径
2. 预处理器定义
3. 导出库/静态库

## `Modern CMake`导出`target`的实现

那么`Modern CMake`是如何导出`target`来支持如此`easy`的使用呢?

`Modern CMake`将库抽象为`target`,并将使用所需的所有信息都存放在`target`的属性之上,在用户以`target_link_libraries`使用时,从依赖的`target`中取出这些构建用信息.

针对第三方库使用所需要的内容,`target`中分别有属性一一对应:

1. 头文件路径:`INTERFACE_INCLUDE_DIRECTORIES`
2. 预处理器定义:`INTERFACE_COMPILE_DEFINITIONS`
3. 导出库/静态库: `IMPORTED_IMPLIB`
4. 动态库: `IMPORTED_LOCATION`

那么一个导出`target`该如何实现:

```CMAKE

set(library_include_dirs "") ##头文件路径
set(library_compile_definitions "") ##预处理器定义
set(library_implib "") ##导入库位置
set(library_location "") ##动态库位置

add_library(library_name SHARED IMPORTED)
set_target_properties(library_name PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${library_include_dirs}"
    INTERFACE_COMPILE_DEFINITIONS  "${library_compile_definitions}"
    IMPORTED_IMPLIB "${library_implib}"
    IMPORTED_LOCATION "${library_location}"
)
```

假设我们有个示例库`example`,在文件系统中布局如下:

- example
  - include
  - bin
    - win32
      - Debug
        - exampled.dll
      - Release
        - example.dll
    - x64
      - Debug
        - exampled.dll
      - Release
        - example.dll
  - lib
    - win32
      - Debug
        - exampled.lib
      - Release
        - example.lib
    - x64
      - Debug
        - exampled.lib
      - Release
        - example.lib

那么该如何支持`Modern CMake`呢?

在`lib`文件夹下创建`lib/cmake/example/example-config.cmake`文件:

```CMAKE

##定位到example路径
get_filename_component(_example_install_prefix "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)

if(NOT TARGET example)
    ##添加导入target
    add_library(example SHARED IMPORTED)

    #设置头文件路径
    set_target_properties(library_name PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_example_install_prefix}/include"
    )

    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
        #32位
        set_target_properties(library_name PROPERTIES
            IMPORTED_IMPLIB "${_example_install_prefix}/lib/Win32/Release/example.lib"
            IMPORTED_LOCATION "${_example_install_prefix}/bin/Win32/Release/example.dll"
        )
        ##调试配置
        set_target_properties(library_name PROPERTIES
            IMPORTED_IMPLIB_DEBUG "${_example_install_prefix}/lib/Win32/Release/exampled.lib"
            IMPORTED_LOCATION_DEBUG "${_example_install_prefix}/bin/Win32/Release/exampled.dll"
        )
    elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
        #64位
        set_target_properties(library_name PROPERTIES
            IMPORTED_IMPLIB "${_example_install_prefix}/lib/x64/Release/example.lib"
            IMPORTED_LOCATION "${_example_install_prefix}/bin/x64/Release/example.dll"
        )
        ##调试配置
        set_target_properties(library_name PROPERTIES
            IMPORTED_IMPLIB_DEBUG "${_example_install_prefix}/lib/x64/Release/exampled.lib"
            IMPORTED_LOCATION_DEBUG "${_example_install_prefix}/bin/x64/Release/exampled.dll"
        )
    endif()
endif()
```

这时采用如下方式就可以使用`example`了:

```CMAKE
list(APPEND CMAKE_PREFIX_PATH "指向example的绝对或者相对路径")

find_package(example CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE example)
```

## 如果你有一系列库

以上演示的是单个库的做法,如果你有一系列库,类似 Qt 那种,该如何去做呢?

`Qt`的`find_package`是支持两种方式的:

```CMAKE
find_package(Qt5 COMPONENTS Core Widget CONFIG REQUIRED)
##或者
find_package(Qt5::Core CONFIG REQUIRED)
```

针对一系列库,通常采用第一种方式`COMPONENTS`,对于库的合集,通常`find_package`的第一个参数是包名.实现类似与下面的形式:

- lib
  - cmake
    - package_name
      - package_name-config.cmake
    - package_namelibrary_name
      - package_namelibrary_name-config.cmake
    - ......

`package_name-config.cmake`的功能就是根据`COMPONENTS`去`find_package`:

```CMAKE

##定位模块位置
get_filename_component(_example_install_prefix "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)


##加载请求的组件
foreach(module ${example_FIND_COMPONENTS})
    find_package(${module}
        PATHS "${_example_install_prefix}" NO_DEFAULT_PATH
    )
endforeach()
```

而具体的`package_namelibrary_name-config.cmake`则与上述的基本类似.

## 如何处理包中各个库的依赖

包中各个库也是有互相依赖的,`Modern CMake`的关键特征之一就是`target`的依赖有传播性.那么该如何实现?

`Modern CMake`为`target`提供了`INTERFACE_LINK_LIBRARIES`属性,譬如`example::library2`依赖于`example::common`和`example::library1`,则可以以如下方式配置:

```CMAKE
set_target_properties(example::library2 PROPERTIES
    INTERFACE_LINK_LIBRARIES "example::common;example::library1"
)
```

但是在配置之前需要先确保对应的包存在并被加载上来:

```CMAKE
set(__DEPENDENCIES "examplecommon;examplelibrary1")
foreach(_module_dep ${__DEPENDENCIES})
    find_package(${_module_dep}
        PATHS "${_example_install_prefix}"
    )
endforeach()
```

## 用`CMake`生成适配

`CMake`提供了`configure_file`允许进行文本替换,这样我们就可以书写模板来帮助我们简化适配的实现:

结构类似如下:

- cmake
  - package-config.cmake.in
  - library-config.cmake.in
  - generator.cmake
- CMakeLists.txt

在`CMakeLists.txt`中调用`generator.cmake`中提供的`generate_package`和`generate_library`来创建适配.

完整的示例见当前目录下.

## 总结

`CMakeLists.txt`也是代码,采用合适的方式,更好的实践,可以使得我们不会在"偶然复杂度"上浪费太多时间.
当然,如果你感受到了`Modern CMake`的便利,可以尝试推广它,让环境变得更好.
