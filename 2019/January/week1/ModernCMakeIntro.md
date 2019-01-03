# 现代 CMake 简介

本文由以下资料汇总而成:

- [Effective CMake](https://www.youtube.com/watch?v=bsXLMQ6WgIk)
- [It's Time To Do CMake Right](https://pabloariasal.github.io/2018/02/19/its-time-to-do-cmake-right/)
- [Using Modern CMake Patterns to Enforce a Good Modular Design](https://www.youtube.com/watch?v=eC9-iRN2b04)
- [An Introduction to Modern CMake](https://cliutils.gitlab.io/modern-cmake/)

## 为什么有 CMake

C++虽然有标准,但是现实世界是复杂的,在使用 C++开发应用时面临一些问题:

- 应用可能跑在多平台上:Windows,Unix,Linux,Apple,......
- 使用的编译器不一样:Visual C++,gcc,clang,......

换句话说,C++的构建系统比较复杂,CMake 的目的就是为了在这些构建系统之上做通用的构建流程描述,来根据不同的平台及编译器来生成对应的构建配置,来辅助完成应用构建这一动作.

## 为什么有现代 CMake

C++是一门非常复杂的多范式语言,随着语言的发展,有了现代 C++一说,以此来为开发者提供更好的实践指导;而 C++目前的应用构建依然是比较混乱,即使 CMake 已经广泛应用,却一直没有很好的实践指导,于是慢慢有人开始做这件事,希望能够使得 C++应用构建更为容易,方便维护.于是有了现代 CMake 的说法.

## 构建系统

针对 C++这门语言,构建系统所完成的工作是什么?

编译 C++源代码,链接成静态库、动态库抑或可执行程序.

其中涉及到构建目标、头文件、源文件、依赖库、编译器选项、链接器选项等等.

我们具体到特定的构建目标来看,需要为其指定以下内容:

- 构建结果类型:静态库、动态库、可执行程序
- 源文件列表
- 头文件路径
- 库文件路径
- 库依赖
- 编译选项
- 链接选项
- 输出选项
- ......

也就是说,可以将其抽象为两种内容:目标和属性.

## 目标和属性

现代 CMake 就围绕目标和属性两个概念进行实践.概念并不复杂.应用的组件定义为目标,可执行程序是目标,库也是目标.应用程序由一系列互相依赖和使用的目标构成.

目标有很多属性,属性可以是源文件列表,也可以是其所需要的编译器选项,抑或是其链接的库.在现代 CMake 中,你定义一系列的目标,然后为这些目标定义必要的属性.

### 构建需要和使用需要

在开始后续介绍之前先明确一些概念,目标的属性分为两种作用域: 接口(INTERFACE) 和 私有(PRIVATE).私有属性是指内部使用,来构建目标的;而接口属性是供目标的使用者在外部使用的.换句话说,接口属性用来描述使用需要,私有属性用来描述构建需要.

属性也可以指定为公共(PUBLIC),公共属性存在于接口和私有两种作用域.

## 示例

假设你写了个 json 的操作库:`libjsonutils`,通过给定的 URL 定位到文档并将其解析为 JSON 文档.工程结构如下:

```BASH
libjsonutils
├── CMakeLists.txt
├── include
│   └── jsonutils
│       └── json_utils.h
├── src
│   ├── file_utils.h
│   └── json_utils.cpp
└── test
    ├── CMakeLists.txt
    └── src
        └── test_main.cpp
```

在`json_utils.h`这个公共头文件中定义了如下函数:

```C++
boost::optional<rapidjson::Document> loadJson(const std::string& url);
```

CMake 配置整体以工程为形式(类似于 Visual Studio 中的解决方案):

```CMAKE
cmake_minimum_required(VERSION 3.5)
project(libjsonutils VERSION 1.0.0 LANGUAGES CXX)
```

指定目标:

```CMAKE
add_library(JSONUtils src/json_utils.cpp)
```

然后定义目标的头文件路径属性:

```CMAKE
target_include_directories(JSONUtils
    PUBLIC
        $<INSTALL_INTERFACE:include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)
```

这个头文件路径属性相对复杂一点,首先`src`目录下的是构建需要的私有路径,`include`目录下的是构建需要的公共路径,如果`JSONUtils`库安装完成,别的目标需要使用`JSONUtil`,则需要去不同的目录找头文件路径.为了解决这个问题,这里使用了`generator expressions`,详情参见[generator expressions](https://cmake.org/cmake/help/v3.5/manual/cmake-generator-expressions.7.html).

之后我们想要让构建过程中发生的警告视为错误,而且由于内部使用了`auto`和`constexpr`,需要编译器支持 C++11 标准,这里就需要定义编译器选项和编译器特性:

```CMAKE
target_compile_options(JSONUtils PRIVATE -Werror)
```

```CMAKE
target_compile_features(JSONUtils PRIVATE cxx_std_11)
```

### 库依赖

这里我们需要 Boost::regex 来解析 URL,也需要 RapidJSON,只不过这里的区别是 RapidJSON 和 Boost::Option 存在于接口中,需要作为公共属性.

```CMAKE
find_package(Boost 1.55 REQUIRED COMPONENTS regex)
find_package(RapidJSON 1.0 REQUIRED MODULE)

target_link_libraries(JSONUtils
    PUBLIC
        Boost::boost RapidJSON::RapidJSON
    PRIVATE
        Boost::regex
)
```

这时后续使用`JSONUtils`的目标都会自动依赖`RapidJSON`和`Boost`,无需再进行配置.

## 总结

现代 CMake 将内容聚焦于目标和属性,其中目标以`add_library`等形式,属性以`target_xxx`形式进行配置.不再滥用变量等等操作.使得配置更为简单易懂容易维护.
