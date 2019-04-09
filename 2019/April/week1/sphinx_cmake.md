# Sphinx 与 CMake

Sphinx 是以 Python 编写的文档生成工具,Python 官方文档就是使用 Sphinx 构建的. 最近在使用 pybind11 为现存的 C++模块提供 Python 接口,涉及到提供相应文档,而工程又是以 CMake 构建的.这里记录下如何整合 Sphinx 文档构建到 CMake 构建流程中.

## 前提条件

需要安装 CMake 和 Sphinx,既然是需要安装 Python,那么通过 pip 进行安装最为简便:

```BAT
pip install cmake
pip install Sphinx
```

Sphinx 相关使用知识是必须的,这里不再赘述,如果需要入门,可以参考[How to generate beautiful technical documentation](https://www.tjelvarolsson.com/blog/how-to-generate-beautiful-technical-documentation/).

## 实现思路

这里采用的 C++工程的布局如下:

- include
- src
- cmake
- docs
- examples
- CMakeLists.txt

我们在`CMakeLists.txt`中提供选项来控制是否生成文档.Sphinx 生成文档可以通过以下命令执行:

```BAT
sphinx-build -b BUILDER -c PATH SOURCEDIR OUTPUTDIR
```

其中,`-b`指定了要生成的文档类型,如果不指定,默认为`html`. `-c`指定了 Sphinx 所识别的配置文件`conf.py`所在路径,`SOURCEDIR`指定了文档源文件路径,`OUTPUTDIR`指定了文档输出路径.

这里我们采用如下约定:

- 文档源代码位于`docs`
- 工程根目录包含`README.rst`
- 配置文件`conf.py`的模板存放在`cmake`中构建时生成
- 示例代码存放在`examples`

在`CMakeLists.txt`中使用`configure_file`生成`conf.py`,然后使用`add_custom_target`生成构建目标.

## 材料准备

工程根目录的`README.rst`存放工程的 README,这里示例如下:

```rst
Sphinx与CMake
===============

Sphinx与CMake整合使用来为项目生成文档的示例.
```

在`docs`提供三个文件:

- index.rst 文档入口
- intro.rst 简介
- example.rst 示例

在`examples`下提供`script.py`作为示例.

其中`docs/index.rst`内容如下:

```rst
.. include:: ../README.rst

.. toctree::
    :maxdepth: 2

    intro
    example

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
```

这里采用的方式是引入根目录的 README,然后添加目录,包含简介和示例.最后包含各种索引和搜索.

`docs/intro.rst`则包含了简介:

```rst
简介
=====

如何使用Sphinix.

```

在`docs/example.rst`中展示了如何内嵌代码以及引用外部源代码文件:

```rst
代码示例
==========

这里是一个Python函数.

.. code-block:: python

    def hello(name):
    """返回问候语."""
    return "你好 {}!".format(name)

这里是一个C函数.

.. code-block:: C

    int add(int a,int b){
        return a+b;
    }

以下是Python示例脚本的内容:

.. literalinclude:: ../examples/script.py
    :language: python

```

## `conf.py`模板

Sphinx 从`conf.py`中获取配置信息,可以使用`CMake`的`configure_file`来制作模板,这里仅提供示例`cmake/sphinx_conf.py.in`:

```python

# 工程信息
project = 'Sphinx与CMake应用示例'
copyright = '2019,liff.engineer@gmail.com'
author = 'liff.engineer@gmail.com'

# 版本号
release = '0.0.1'

# 通用配置

extensions = []
templates_path = []
exclude_patterns = []

# HTML输出选项
html_theme = 'alabaster'
html_static_path = []

```

## 构建脚本

在 CMakeLists.txt 中添加文档构建脚本:

```cmake
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
```

首先生成配置文件,然后设定 Sphinx 缓存目录及输出目录,最终添加生成用`target`.

## 如何构建

在工程根目录下执行如下命令:

```bat
mkdir build
cd build
cmake ..
cmake --build .
```

经过上述命令,就会在`build/doc`下生成项目文档.
