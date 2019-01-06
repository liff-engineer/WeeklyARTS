# 基于 Visual Studio 开发 Node.js C++ Addons 简介

如何开发 Node.js C++ Addons 已经有很多的资料可以参考,通常都使用[`node-gyp`](https://github.com/nodejs/node-gyp)进行编译打包等动作.但是存在一些问题,`node-gyp`与`Python 2.X`绑定,这点非常糟糕;如果需要将现存的 C++组件包装成`Node.js Addon`,则涉及到依赖、构建、调试等等问题. 那么有没有办法可以将其整合到现有开发流程中,抑或统一整个过程呢.

这里将展示在 Windows 平台下使用 Visual Studio 来开发 Node.js C++ Addons 的方式.

在这里将使用`vcpkg`来管理第三方依赖,使用`Modern CMake`来管理构建流程,使用`Visual Studio`来进行开发、构建、调试,并针对性地提供`npm`相关整合打包方案.

## [`CMake.js`](https://github.com/cmake-js/cmake-js)及其问题

`CMake.js`旨在作为`node-gyp`的替代品,以`CMake`来作为构建系统,但是其与 IDE 整合并不友好,与现有 C++开发方式不太融洽,更重要的是,通过`npm install cmake.js`安装的`node.lib`在 Windows 上编译一直报库损坏的问题,要解决这个问题还需要自行去网站上下载对应的`node.lib`,如果开发流程整合进 CI/CD 抑或使用`Docker`,将是一个大麻烦.

因而这里采用 C++的方式,将`Node.js C++`开发依赖作为库,提供`vcpkg`的`port`,直接整合到现有的 C++开发流程中.

## 为`vcpkg`的提供`node`的`port`适配

在开发`C++ Addon`时需要用到`Node.js`的头文件和库`node.lib`,安装版本的`Node.js`并没有提供,需要自行下载.具体位置在`https://nodejs.org/dist/`下,有每个版本的源代码及构建结果.这里选用`v10.15.0`这个`LTS`版本.

```BASH
Index of /dist/v10.15.0/

../
docs/
win-x64/
    node.exe
    node.lib
    node_pdb.7z
win-x86/
    node.exe
    node.lib
    node_pdb.7z
SHASUMS256.txt
node-v10.15.0-headers.tar.gz
```

为了给`vcpkg`提供适配,则需要下载`node-v10.15.0-headers.tar.gz`和`node.lib`.

在`vcpkg/ports`下新建`node`文件夹,并提供`CONTROL`和`portfile.cmake`两个文件.

在`CONTROL`文件中我们指定库名称,版本以及描述.内容如下:

```TXT
Source: node
Version: 10.15.0
Description: Node.js Addons develop support library.It can be used to provide an interface between JavaScript running in Node.js and C/C++ libraries.
```

而`portfile.cmake`则用来控制包的构建,这里采用直接下载的方式,实现如下:

```CMAKE
include(vcpkg_common_functions)

set(NODEJS_VERSION v10.15.0)

#下载头文件
vcpkg_download_distfile(ARCHIVE
    URLS "https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-headers.tar.gz"
    FILENAME "node-${NODEJS_VERSION}-headers.tar.gz"
    SHA512 6c155012b9e0346febdd3d60d2cbe4307502f9fbf432a70de699c1c26b25c634c38622bd5c2bf9fd90bf938e15cd845cdba1fc9e35612d106a65fb4595a11fae
)

#解压缩头文件包
vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF "${NODEJS_VERSION}"
)

#安装头文件
file(COPY ${SOURCE_PATH}/include/ DESTINATION ${CURRENT_PACKAGES_DIR}/include/)

#message(INFO "  ${SOURCE_PATH}")

#根据平台不同下载不同的内容?
if(VCPKG_TARGET_ARCHITECTURE MATCHES "x86")
    set(LIBRARY_FILENAME "node-${NODEJS_VERSION}-x86.lib")
    vcpkg_download_distfile(LIBRARY
        URLS "https://nodejs.org/dist/${NODEJS_VERSION}/win-x86/node.lib"
        FILENAME  "${LIBRARY_FILENAME}"
        SHA512 f1c201c23ea805b69e5da5be3089c24e7f9e36d9d1b8381ebacfd3579e64869f6824d0fb354d9cfaedd01a0f6e11f4adc991dc7942cadbfa9b525321ab600878
    )
elseif(VCPKG_TARGET_ARCHITECTURE MATCHES "x64")
    set(LIBRARY_FILENAME "node-${NODEJS_VERSION}-x64.lib")
    vcpkg_download_distfile(LIBRARY
        URLS "https://nodejs.org/dist/${NODEJS_VERSION}/win-x64/node.lib"
        FILENAME  "${LIBRARY_FILENAME}"
        SHA512 7e9fb14f113ea841d32da0805eeb5acaaa1ce7c7298d1bb929fdcc808f97067b83ded9dd361b9f9cf6667f1ec0ecb15179d248fbb65a187688d68346fe7f18d9
    )
else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()

file(MAKE_DIRECTORY
    ${CURRENT_PACKAGES_DIR}/lib
    ${CURRENT_PACKAGES_DIR}/debug/lib
    )

file(COPY ${LIBRARY} DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
file(RENAME ${CURRENT_PACKAGES_DIR}/lib/${LIBRARY_FILENAME} ${CURRENT_PACKAGES_DIR}/lib/node.lib)
file(COPY ${CURRENT_PACKAGES_DIR}/lib/node.lib DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)

#生成版权文件
file(WRITE ${CURRENT_PACKAGES_DIR}/share/node/copyright "See https://nodejs.org for the Node.js License")
```

主要实现方式就是下载头文件压缩包解压,然后复制到`vcpkg`头文件路径,而在处理`node.lib`时要根据平台的不同从不同路径下载,注意修改了`node.lib`的名字是为了能够利用其缓存,而不是每次都下载.最终生成版权文件.

经过上述步骤就可以以如下命令安装`Node.js C++ Addon`开发支持库了:

```CMD
.\vcpkg.exe install node node:x64-windows
```

## 使用`CMake`作为工程配置

经过上述步骤,在`Visual Studio 2015/2017`中就进行`Node.js C++ Addon`开发了.常规流程就是:

- 新建动态库工程
- 修改生成文件后缀(从`.dll`修改为`.node`)
- 构建

但是如果要跨平台等等,就得考虑使用`CMake`来管理.

假设新手上路,要试验一下[C++ Addons- Hello World](https://nodejs.org/api/addons.html#addons_c_addons).建立如下目录结构:

```CMD
src
    hello.cc
CMakeLists.txt
hello.js
```

这时`CMakeLists.txt`的初始内容为:

```CMAKE
#约束CMake脚本,因为是Modern CMake
cmake_minimum_required(VERSION 3.0)

#工程名
project(hello_nodejs)

#增加一个动态库
add_library(${PROJECT_NAME} SHARED "src/hello.cc")

#修改库的后缀为`.node`
set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "" SUFFIX ".node")
```

这时使用`Visual Studio 2017`的打开文件夹打开该目录,`VS`能够识别并建立工程.

但是目前位置还不能使用`vcpkg`中的库.在`VS`的`CMake`菜单下找到`更改CMake设置`,调整`hello_nodejs`的配置,在`ctestCommandArgs`后追加:

```JSON
"variables": [
    {
        "name": "CMAKE_TOOLCHAIN_FILE",
        "value": "C:\\xxxx\\vcpkg\\scripts\\buildsystems\\vcpkg.cmake"
    }
]
```

以上的配置方法详见[Vcpkg - Option B: CMake (Toolchain File)](https://github.com/Microsoft/vcpkg/blob/8379a80abe5288c7c06d5b9ab16efe355d1c6f62/docs/EXAMPLES.md#example-1-2-b).

将默认配置按需调整,譬如如下:

```JSON
{
  "configurations": [
    {
      "name": "x86-Debug",
      "generator": "Visual Studio 15 2017",
      "configurationType": "Debug",
      "inheritEnvironments": [
        "msvc_x86"
      ],
      "buildRoot": "${env.USERPROFILE}\\CMakeBuilds\\${workspaceHash}\\build\\${name}",
      "installRoot": "${env.USERPROFILE}\\CMakeBuilds\\${workspaceHash}\\install\\${name}",
      "cmakeCommandArgs": "",
      "buildCommandArgs": "",
      "ctestCommandArgs": "",
      "variables": [
        {
          "name": "CMAKE_TOOLCHAIN_FILE",
          "value": "C:\\Users\\Garfield\\Desktop\\vcpkg_node\\scripts\\buildsystems\\vcpkg.cmake"
        }
      ]
    }
  ]
}
```

上述内容指定了`x86-Debug`配置,`generator`为`Visual Studio`,环境为`msvc_x86`.`buildRoot`指定了`CMake`的`build`目录,`installRoot`指定了安装目录.

经过上述配置就可以使用`vcpkg`中安装好的第三方库了.`Modern CMake`的使用方式如下:

```CMAKE

find_package(node REQUIRED)
target_include_directories(${PROJECT_NAME} node)
target_link_libraries(${PROJECT_NAME} private node)
```

但是我们为`node`提供的`vcpkg`适配没有以`Modern CMake`的要求实现`Find{PackageName}.cmake`,导致以上述方式使用,需要以旧的`CMake`方法使用:

```CMAKE
#查找头文件路径

find_path(NODEJS_INCLUDE_DIR node/v8config.h)
include_directories(${NODEJS_INCLUDE_DIR})
#message(INFO " ${NODEJS_INCLUDE_DIR}")

#查找库文件
find_library(NODE_LIBRARY node)
link_libraries(${NODE_LIBRARY})
#message(INFO " ${NODE_LIBRARY}")
```

这时就可以编辑`hello.cc`内容为:

```C++
#include <node/node.h>

namespace demo {
	void Method(const v8::FunctionCallbackInfo<v8::Value>& args) {
		args.GetReturnValue().Set(v8::String::NewFromUtf8(args.GetIsolate(),
			"world", v8::NewStringType::kNormal).ToLocalChecked());
	}

	void Initialize(v8::Local<v8::Object> exports) {
		NODE_SET_METHOD(exports, "hello", Method);
	}

	NODE_MODULE(NODE_GYP_MODULE_NAME, Initialize)
}
```

然后就可以生成对应的`CMake Target`了.

## 命令行/自动化脚本 方式构建

上述可以完成对应的开发、调试等动作,而一旦源代码提交上去后就需要采用命令行/自动化脚本的方式构建了.

假设当前目录为`CMakeLists.txt`所在目录,而我们需要将其构建到`build`文件夹下:

```CMD
mkdir build
cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE="C:\\Users\\Garfield\\Desktop\\vcpkg_node\\scripts\\buildsystems\\vcpkg.cmake"
cmake --build . --config Release
```

上述命令即可将构建出结果,但是都是默认的,如果需要同时构建出 32 位和 64 位结果:

```CMD
mkdir build32 & pushd build32
cmake .. -G"Visual Studio 15 2017" -DCMAKE_TOOLCHAIN_FILE="C:\\Users\\Garfield\\Desktop\\vcpkg_node\\scripts\\buildsystems\\vcpkg.cmake"
popd
mkdir build64 & pushd build64
cmake .. -G"Visual Studio 15 2017 Win64" -DCMAKE_TOOLCHAIN_FILE="C:\\Users\\Garfield\\Desktop\\vcpkg_node\\scripts\\buildsystems\\vcpkg.cmake"
popd

cmake --build build32 --config Release
cmake --build build64 --config Release
```

## 运行`Hello.js`

实现`Hello.js`如下:

```JavaScript
const addon = require('./build/Release/hello_nodejs')

console.log(addon.hello());
```

然后切换到对应目录运行:

```CMD
node hello.js
```

注意如果报错说`hello_nodejs.node`不是有效的`Win32`应用程序,则需要检查两点:

1. 环境中的`node`平台`win32/x64`是否与`hello_nodejs.node`一致
2. 环境中的`node`版本是否与`vcpkg`中的`node`版本一致.

## 如何整合`CMake.js`与现有流程

上述流程虽然跑通了,但是我们还是希望`Node.js`的内容随着`Node.js`的开发流程走,譬如打包用`package.json`,这时就可以整合`CMake.js`到流程中.

调整之前的`CMakeLists.txt`,部分内容如下:

```CMAKE
cmake_minimum_required(VERSION 3.0)

include("C:\\Users\\Garfield\\Desktop\\vcpkg_node\\scripts/buildsystems/vcpkg.cmake")

project(hello_nodejs)
```

然后以`npm`的方式创建`package.json`:

```JSON
{
  "name": "hello_nodejs",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC"
}
```

在目录下运行`cnpm install --save cmake-js`来指定`cmake_js`依赖.

这时可以使用如下命令来全局安装`cmake-js`进行测试:

```CMD
npm install -g cmake-js
cmake-js build
```

这时修改`package.json`,使得模块可以被`npm`安装:

```JSON
{
  ...
  "scripts": {
    "install": "cmake-js compile"
  }
}
```

然后利用[`bindings`](https://www.npmjs.com/package/bindings)对模块进行导出:

- 设定`bindings`依赖

```CMD
npm install --save bindings
```

- 修改/创建`index.js`

```JavaScript
module.exports = require("bindings")("hello_nodejs");
```

## 总结

通过上述方式,就可以以统一流程实现开发 C++组件以及对应的`Node.js Addons`,辅助以一些自动化手段就能整合到 CI/CD 流程中去.

## TODO

- 能否以`Modern CMake`的方式实现`FindNode.cmake`
- `node-addon-api`提供了 C++的方式来做绑定,可以为其提供`vcpkg`的`port`
- Python 可以将 native 的模块打包成`.whl`来进行发布,`npm`是否有相应的方式

## 参考

- [CMake.js - a Node.js native addon build tool](https://github.com/cmake-js/cmake-js)
- [The Future of Native Modules in Node.js](https://www.nearform.com/blog/the-future-of-native-modules-in-node-js/)
- [node-addon-api module](https://www.npmjs.com/package/node-addon-api)
- [node-bindings - Helper module for loading your native module's .node file](https://www.npmjs.com/package/bindings)
