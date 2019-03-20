# Python"原生"包构建实现解析

最近在尝试为现有C++模块提供`Python`接口,遇到一些问题,关于如何构建出对应的`.whl`文件,尝试查阅了能找到的资料,发现没有针对`Python`包构建的详细说明,只有一些片段提供了部分扩展`distutils.command`样例.

实际上为现有C++模块构建`Python`接口,是相对复杂的,构建流程要能够正确处理,打包时还要处理所依赖的动态链接库,更不用说还有数据等内容要处理.如果默认行为无法完成打包动作,就需要扩展打包流程了.

这里尝试记录下跟踪`Python`打包实现的方式方法,以及部分实现解析,还有扩展样例的分析.

## 前提条件

在Windows上安装完`Python`后,默认提供了`distutils`包用来打包,而目前用得较多的是`setuptools`,如果要打包成为`.whl`文件则需要`wheel`,因而需要使用`pip`安装这些内容:

```cmd
pip install setuptools
pip install wheel
```

我选用`Visual Studio Code`来进行开发和调试.这里需要安装`C/C++`以及`Python`扩展.

有了上述准备之后,就可以开始分析整个打包流程了.

## `example`源代码示例

这里使用`Python`的`C/C++`扩展方式,不借助外部库,示例`example.cpp`如下:

```C++
#include <Python.h>

static PyObject *pants(PyObject *self, PyObject *args) {
  int input;
  if (!PyArg_ParseTuple(args, "i", &input)) {
    return NULL;
  }

  return PyLong_FromLong((long)input * (long)input);
}

static PyMethodDef example_methods[] = {
    {"pants", pants, METH_VARARGS, "Returns a square of an integer"},
    {NULL, NULL, 0, NULL},
};

static struct PyModuleDef example_definition = {
    PyModuleDef_HEAD_INIT,
    "example",
    "example module containing pants() function",
    -1,
    example_methods,
};

PyMODINIT_FUNC PyInit_example(void) {
  Py_Initialize();
  PyObject *m = PyModule_Create(&example_definition);

  return m;
}
```

## 使用`distutils`从源代码构建

`example`示例对应的`setup.py`如下:

```python
from distutils.core import setup, Extension

module = Extension('example',
                    sources = ['example.cpp'],
                    language='C++',)

setup (name = 'example',
       version = '0.1.0',
       description = 'example module written in C++',
       ext_modules = [module])
```

这里的`ext_modules`指的是`C/C++`扩展模块,对应的`Extension`则保存了构建扩展模块的源代码、头文件路径等等信息.

在`setup.py`同目录下执行命令:

```cmd
python setup.py --help-commands
```

可以看到能够执行的命令列表,这里我们选择`build`命令来构建整个包.

在`Visual Studio Code`的调试面板,选择齿轮按钮,修改`launch.json`,可以看到调试配置片段如下:

```json
"name": "Python: Current File (Integrated Terminal)",
"type": "python",
"request": "launch",
"program": "${file}",
"console": "integratedTerminal"
```

这时按`F5`启动调试则会在终端执行`python setup.py`,我们需要执行`python setup.py build`,而且要调试`Python`的标准库,因而调整配置为如下:

```json
"name": "Python: Current File (Integrated Terminal)",
"type": "python",
"request": "launch",
"program": "${file}",
"console": "integratedTerminal",
"args": [
    "build"
],
"debugStdLib": true
```

现在可以在`setup.py`中打断点进行调试了.

## `distutils`构建原生模块实现

`python setup.py build`启动执行后,会构建`setup`,参数为`build`,之后进入`distutils/core.py`的`setup`方法,然后执行如下内容:

1. 获取用户自定义的`distclass`
2. 解析配置文件`setup.cfg`
3. 解析命令,这里拿到`build`
4. 执行命令

这里进入`dist.run_commands()`来执行命令`build`(位于`distutils/command/build.py`).

`build`命令根据`setup`参数判断是否要执行以下四个子命令中的哪些命令:

- `build_py`:纯`Python`模块
- `build_clib`
- `build_ext`:`Python`扩展
- `build_scripts`: 脚本

由于我们的示例只有`ext_modules`,则会执行子命令中的`build_ext`(位于`distutils/command/build_ext.py`),流程如下:

1. 获取编译器信息
2. 针对每个扩展执行构建动作
    1. 调用编译器的`compile`
    2. 调用编译器的`link_shared_object`

经过上述步骤,会在同目录下创建`temp`和`lib`文件夹,针对Windows,`Python 3.7`,64位,结构如下:

- build
- lib.win-amd64-3.7
  - example.cp37-win_amd64.pyd
- temp.win-amd64-3.7

其中`temp`是临时文件夹,`lib`则为构建结果存放路径

## `setuptools`打包原生模块

我们的目的是生成`.whl`,这就需要使用`setuptools`和`wheel`,`setup.py`需要调整为:

```python
#from distutils.core import setup, Extension
from setuptools import setup, Extension

module = Extension('example',
                    sources = ['example.cpp'],
                    language='C++',)

setup (name = 'example',
       version = '0.1.0',
       description = 'example module written in C++',
       ext_modules = [module])
```

因为要执行`python setup.py bdist_wheel`,`launch.json`也需要将参数进行调整:

```json
"name": "Python: Current File (Integrated Terminal)",
"type": "python",
"request": "launch",
"program": "${file}",
"console": "integratedTerminal",
"args": [
    "bdist_wheel"
],
"debugStdLib": true
```

这时`F5`首先进入`setuptools/__init__.py`的`setup`方法,然后进入`distutils.core.setup`,执行`bdist_wheel`命令(位于`wheel/bdist_wheel.py`):

1. 重新初始化`build_scripts`及`build_ext`命令
2. 执行`build`命令
3. 重新初始化`install`命令
4. 调整`install`子命令的路径信息
5. 执行`install`命令
6. 合成包名称,生成`.whl`文件
7. 删除临时文件

## 采用`CMake`构建扩展库

在C++项目中通常采用`CMake`来构建,那么构建`Python`原生模块时是否可以用`CMake`呢?

这个是可行的,不过需要对`setup.py`做比较大的调整.首先为`example`提供`CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.12)

add_library(example SHARED example.cpp)

target_include_directories(example
    PRIVATE "C:/Users/liff/AppData/Local/Programs/Python/Python37/include"
)

target_link_directories(example
    PRIVATE "C:/Users/liff/AppData/Local/Programs/Python/Python37/libs"
)

target_link_libraries(example PRIVATE "python37.lib" "python3.lib")

set_target_properties(example PROPERTIES SUFFIX ".pyd")
```

这时就可以以`CMake`的方式构建出`example.pyd`来.

那么如何使得构建使用`CMake`呢? 之前分析打包流程,可知可以为`setup`提供`cmdclass`来覆盖旧的`build_ext`指令,完整的`setup.py`实现如下:

```python
import os
import re
import sys
import platform
import subprocess


from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
from distutils.version import LooseVersion


class CMakeExtension(Extension):
    def __init__(self, name, sourcedir=''):
        Extension.__init__(self, name, sources=[])
        self.sourcedir = os.path.abspath(sourcedir)

class CMakeBuild(build_ext):
    def run(self):
        try:
            out = subprocess.check_output(['cmake', '--version'])
        except OSError:
            raise RuntimeError("CMake must be installed to build the following extensions: " +
                               ", ".join(e.name for e in self.extensions))

        if platform.system() == "Windows":
            cmake_version = LooseVersion(
                re.search(r'version\s*([\d.]+)', out.decode()).group(1))
            if cmake_version < '3.1.0':
                raise RuntimeError("CMake >= 3.1.0 is required on Windows")

        for ext in self.extensions:
            self.build_extension(ext)

    def build_extension(self, ext):
        extdir = os.path.abspath(os.path.dirname(
            self.get_ext_fullpath(ext.name)))
        cmake_args = ['-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=' + extdir,
                      '-DPYTHON_EXECUTABLE=' + sys.executable]

        cfg = 'Debug' if self.debug else 'Release'
        build_args = ['--config', cfg]

        if platform.system() == "Windows":
            cmake_args += [
                '-DCMAKE_RUNTIME_OUTPUT_DIRECTORY_{}={}'.format(cfg.upper(), extdir)]
            if sys.maxsize > 2**32:
                cmake_args += ['-A', 'x64']
            build_args += ['--', '/m']
        else:
            cmake_args += ['-DCMAKE_BUILD_TYPE=' + cfg]
            build_args += ['--', '-j2']

        env = os.environ.copy()
        env['CXXFLAGS'] = '{} -DVERSION_INFO=\\"{}\\"'.format(env.get('CXXFLAGS', ''),
                                                              self.distribution.get_version())
        if not os.path.exists(self.build_temp):
            os.makedirs(self.build_temp)
        subprocess.check_call(['cmake', ext.sourcedir] +
                              cmake_args, cwd=self.build_temp, env=env)
        subprocess.check_call(['cmake', '--build', '.'] +
                              build_args, cwd=self.build_temp)

setup(
    name='example',
    version='0.1.0',
    description='example module written in C++',
    long_description='',
    ext_modules=[CMakeExtension('example')],
    cmdclass=dict(build_ext=CMakeBuild),
    zip_safe=False,
)
```

这里将`build_ext`扩展成为`CMakeBuild`,同时将`Extension`扩展为`CMakeExtension`,来正确配置源代码目录.

注意`CMakeBuild.build_extension`,获得正确的`extdir`,然后构建结果写入到这个位置,其他基本上是执行`CMake`的配置和构建动作.

经过`CMakeBuild`之后,扩展模块就会输出到之前的`lib.win-amd64-3.7`路径下,这里可以使用`CMake`脚本复制所依赖的动态库和资源文件到相同目录,后续的`install_lib`动作会安装整个目录,然后`.whl`会包含整个内容,保证可以正常安装运行.

## 包与模块

上述步骤生成的都是某个模块,对应的`pyd`等文件安装后直接存在于`site-packages`目录,如果需要将其包裹在包中,操作也相对简单,修改`setup.py`如下:

```python
setup(
    name='py',
    version='0.1.0',
    description='example module written in C++',
    long_description='',
    ext_modules=[CMakeExtension('py.example')],
    cmdclass=dict(build_ext=CMakeBuild),
    zip_safe=False,
)
```

这时就会生成`py`包,内含`example`模块,包形态如下:

- py-0.1.0-cp37-cp37m-win_amd64.whl
  - py
    - example.pyd
    - py-0.1.0.dist-info

注意这时无法正常使用`example`模块,需要为`py`包提供`__init__.py`,内容类似如下:

```python
__all__ = "example"
```

保证`example`模块能够正常加载.

## 总结

从最终分析结果来看,`Python`原生包构建还是比较简单的,结合`CMake`与`pybind11`,可以很轻松地为`C++`模块提供`Python`接口,还能享受`pip install`的简洁体验.