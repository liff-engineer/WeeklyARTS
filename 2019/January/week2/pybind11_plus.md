# 使用 pybind11 进行 python 绑定开发全流程

## 目录结构

```BASH
example
    CMakeLists.txt
    example.cpp
    setup.py
```

为了使得 VSC 支持对应场景下的开发,需要调整工作区/用户设置:

```JSON
  "cmake.configureSettings": {
    "CMAKE_TOOLCHAIN_FILE": "C:\\Repositories\\vcpkg\\scripts\\buildsystems\\vcpkg.cmake"
  }
```

以此来确保正确找到 vcpkg

## CMakeLists.txt 示例

```CMAKE
#CMakeLists.txt

cmake_minimum_required(VERSION 3.0)
project(example)

find_package(pybind11 REQUIRED)
pybind11_add_module(example example.cpp)

#find_package(Sqlite3 REQUIRED)
#target_link_libraries(example PRIVATE sqlite3)

##find_path(VCPKG_INCLUDE_DIR sqlite3.h)
##include_directories(${VCPKG_INCLUDE_DIR})
##find_library(VCPKG_LIBRARY sqlite3)

##message(INFO "  ${VCPKG_LIBRARY}")
##link_libraries(${VCPKG_LIBRARY})

##target_link_libraries(example PRIVATE ${VCPKG_LIBRARY})

set_target_properties(example PROPERTIES VS_GLOBAL_VcpkgEnabled true)

```

## example.cpp 示例

```C++
#include <pybind11/pybind11.h>
#include <sqlite3.h>

int add(int i, int j)
{
    return i + j;
}

std::string report()
{
    return sqlite3_libversion();
}

namespace py = pybind11;

PYBIND11_MODULE(example, m)
{
    m.doc() = R"pbdoc(
        Pybind11 example plugin
        -----------------------
        .. currentmodule:: example
        .. autosummary::
           :toctree: _generate
           add
           subtract
    )pbdoc";

    m.def("add", &add, R"pbdoc(
        Add two numbers
        Some other explanation about the add function.
    )pbdoc");

    m.def("report", report, R"pbdoc(
        report sqlite3 library version
        Some other explanation about the report function.
    )pbdoc");

    m.def("subtract", [](int i, int j) { return i - j; }, R"pbdoc(
        Subtract two numbers
        Some other explanation about the subtract function.
    )pbdoc");

#ifdef VERSION_INFO
    m.attr("__version__") = VERSION_INFO;
#else
    m.attr("__version__") = "dev";
#endif
}
```

## setup.py 示例

```PYTHON
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
        cmake_args = ['-DCMAKE_TOOLCHAIN_FILE=' + 'C:\\Repositories\\vcpkg\\scripts\\buildsystems\\vcpkg.cmake',
                      '-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=' + extdir,
                      '-DPYTHON_EXECUTABLE=' + sys.executable]

        cfg = 'Debug' if self.debug else 'Release'
        build_args = ['--config', cfg]

        if platform.system() == "Windows":
            cmake_args += [
                '-DCMAKE_LIBRARY_OUTPUT_DIRECTORY_{}={}'.format(cfg.upper(), extdir)]
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
    version='0.0.1',
    author='liff.engineer',
    author_email='liff.engineer@gmail.com',
    description='A test project using pybind11 and CMake',
    long_description='',
    ext_modules=[CMakeExtension('example')],
    cmdclass=dict(build_ext=CMakeBuild),
    zip_safe=False,
)

```

## 运行命令

```CMD
python setup.py bdist_wheel
```

以上操作能够利用 vcpkg 现有包,而且自动处理库依赖,动态链接库也会被打包到对应的`.whl`中去.

## 参考

针对`setup.py`编写参考[cmake 示例](https://github.com/pybind/cmake_example/blob/master/setup.py)

原始信息来自[pybind11 构建系统](https://pybind11.readthedocs.io/en/stable/compiling.html)
