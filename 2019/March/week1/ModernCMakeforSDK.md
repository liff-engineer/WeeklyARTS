# 使用 Modern CMake 构建 SDK

在常规的应用场景下,经常涉及到构建出 SDK 供公司内部或者其它外部人员进行开发与扩展.这时就面临一些问题,如何使对方使用,或者让对方能更便捷地使用?

## 要解决的问题

- 不同平台(Windows、Linux)
- 不同版本(Win32、x64)
- 不同配置(Debug、Release)

## 可参考的例子

Qt 作为跨平台的 C++库,不仅提供 SDK,还提供对应的开发环境,不过在 Windows 上还是用`Visual Studio`的多一点.Qt 的方式是安装包,安装出来结构如下:

- Qt
  - 5.5
    - msvc2010/msvc2010_x64
      - bin
      - include
      - lib
      - plugins

Qt 针对平台、版本是拆分开来安装的,不同的配置则以文件后缀来区分,譬如`Qt5Core.dll`为`Release`版本,`Qt5Cored.dll`为`Debug`版本.

## 常规模式

针对 Qt 的那种模式,如果采用之前文章介绍的`CMake`构建方式,是可以直接构建出结果的.但是我们所遇见的结构通常是这样的

- package_name
  - include
    - library_name_1
    - library_name_2
  - lib
    - Win32
      - Debug
        - library_name_1d.lib
      - Release
        - library_name_1.lib
    - x64
      - Debug
        - library_name_1d.lib
      - Release
        - library_name_1.lib
  - bin
    - Win32
      - Debug
        - library_name_1d.dll
      - Release
        - library_name_1.dll
    - x64
      - Debug
        - library_name_1d.dll
      - Release
        - library_name_1.dll

也就是说,直接发布的二进制 SDK 包含了 Win32/x64、Debug/Release 等内容.

那么如何构建出这样结构的 SDK 呢?

## 包配置的变化

为了支持用户使用类似`Qt5`的方式来使用整个 SDK,`Qt5`的使用方式如下:

```cmake
find_package(Qt5 COMPONENTS Core Widgets Xml CONFIG REQUIRED)

target_link_libraries(target PRIVATE Qt5::Core Qt5::Xml)
```

生成对应的`package-config.cmake`方式就需要发生变化.首先是`COMPONENTS`支持:

```cmake
macro(check_required_components _NAME)
  foreach(comp ${${_NAME}_FIND_COMPONENTS})
    if(NOT TARGET ${_NAME}::${comp})
      if(${_NAME}_FIND_REQUIRED_${comp})
        set(${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

check_required_components(package-name)
```

我们定义了`check_required_components`宏,通过遍历包中库的存在来确定`find_package`是否执行成功.

假设我们生成的包名称取自工程名,包使用必须要求用户有`Qt5`存在,同时支持`Win32`和`x64`,那么之前的`library-config.cmake.in`可以实现成`package-config.cmake.in`:

```cmake
macro(check_required_components _NAME)
  foreach(comp ${${_NAME}_FIND_COMPONENTS})
    if(NOT TARGET ${_NAME}::${comp})
      if(${_NAME}_FIND_REQUIRED_${comp})
        set(${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

##检查必须存在的库
include(CMakeFindDependencyMacro)

##注意目的并不是检查所有依赖项,如果依赖于另外一些包,要保证对应的package存在,这样才有继续使用的可能
find_dependency(Qt5 COMPONENTS Core REQUIRED)

##根据目标的不同加载不同的target
if(CMAKE_SIZEOF_VOID_P EQUAL 4)
    include("${CMAKE_CURRENT_LIST_DIR}/@PROJECT_NAME@-Win32-targets.cmake")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
    include("${CMAKE_CURRENT_LIST_DIR}/@PROJECT_NAME@-x64-targets.cmake")
endif()

check_required_components(@PROJECT_NAME@)
```

注意我们使用`CMAKE_SIZEOF_VOID_P`来判断`Win32`和`x64`并加载不同的`targets`文件.

## 导出目标处理

`Win32`和`x64`会生成不同的`targets`文件,这该如何实现?

```cmake
##为构建/安装指定路径
if(CMAKE_SIZEOF_VOID_P EQUAL 4)
    set(PROJECT_PLATFORM "Win32")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(PROJECT_PLATFORM "x64")
endif()

install(EXPORT ${PROJECT_NAME}
    NAMESPACE ${PROJECT_NAME}::
    FILE      ${PROJECT_NAME}-${PROJECT_PLATFORM}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)
```

之前导出的`targets`文件名为`${PROJECT_NAME}-targets.cmake`,现在根据平台的不同来生成不同的`targets`.同时这个`PROJECT_PLATFORM`变量还会用来调整安装路径.

## 安装路径处理

要将`lib`和`bin`路径进行修改,通常只有两种配置会发布:`Debug`、`Release`.但是`Release`可能会发布带`Debug`信息的版本,这里只将其区分成两种:

```cmake
install(TARGETS ${LIBRARY_TARGET_NAME}
    EXPORT ${PROJECT_NAME}
    RUNTIME DESTINATION bin/${PROJECT_PLATFORM}/$<IF:$<CONFIG:DEBUG>,Debug,Release>
    ARCHIVE DESTINATION lib/${PROJECT_PLATFORM}/$<IF:$<CONFIG:DEBUG>,Debug,Release>
    LIBRARY DESTINATION lib/${PROJECT_PLATFORM}/$<IF:$<CONFIG:DEBUG>,Debug,Release>
)
```

注意使用了之前的`PROJECT_PLATFORM`变量,然后利用`CMake`的生成表达式来生成对应的`Debug`和`Release`路径.

为什么不能直接使用`CONFIG`变量? 因为`CMake`作用于生成阶段,之后可能会根据生成器的不同产生`.sln`等特定工具的工程文件,这些工程文件可以随意修改当前配置,所以这时候使用`CONFIG`变量是没有用的,这个变量没有值.

另外,调试版本还希望将`pdb`调试文件提供给用户,则可以写成如下方式:

```cmake
install(FILES $<TARGET_PDB_FILE:${LIBRARY_TARGET_NAME}> DESTINATION bin/${PROJECT_PLATFORM}/$<IF:$<CONFIG:DEBUG>,Debug,Release> OPTIONAL)
```

## 构建方式

为了生成之前布局的 SDK,需要执行两次配置,共四次生成,命令如下:

```bat

REM 32位构建

RD /S /Q build32
mkdir build32
cd build32
cmake .. -G"Visual Studio 10 2010" -DCMAKE_INSTALL_PREFIX:PATH="相对build32的安装目录,或者绝对目录"
cmake --build . --target install
cmake --build . --config Release --target install

REM 64位构建

RD /S /Q build64
mkdir build64
cd build64
cmake .. -G"Visual Studio 10 2010" -A x64 -DCMAKE_INSTALL_PREFIX:PATH="相对build32的安装目录,或者绝对目录"
cmake --build . --target install
cmake --build . --config Release --target install

```

注意每次会使用`RD /S /Q`强制删除之前的构建结果.

通过以上操作就可以生成我们之前提到的 SDK 布局.

## 还有一些小问题

上述只是解决了 SDK 的构建问题,实际上 SDK 过程中也需要开发动作,之间有互相依赖,如果不输出到单个文件夹里,运行测试程序就会找不到所需的库.这里可以使用`CMAKE_RUNTIME_OUTPUT_DIRECTORY`将动态库指定到统一的输出目录:

```cmake
##将动态库输出路径定位到特定路径,供调试时使用(否则依赖的库分布在各个文件夹)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${PROJECT_PLATFORM}/$<CONFIG>")
```

即使做了上述处理,如果依赖于第三方库,动态库也不会自动同步到目标文件夹,依然面临无法启动的困境.这个涉及到如何`deploy`,后续将会为其提供相应的解决方案.
