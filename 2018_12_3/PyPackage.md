# [如何打包Python模块](https://packaging.python.org/guides/distributing-packages-using-setuptools/)

## 典型结构

- `setup.py`
- `setup.cfg`
- `README.rst/README.md`
- `MANIFEST.in`
- `LICENSE.txt`
- `<your package>`

## `setup.py`

`setup.py`文件是支撑打包最重要的文件,需要放置在工程路径的根目录.它有两个功能:

- 包含了工程配置的各个方面.`setup.py`的主要特性是其包含了全局的`setup()`方法.该方法用来指定工程的具体细节.
- 能够用来运行各种与模块相关任务的命令.获取可用命令可使用`python setup.py --help-commands`

## `setup()`参数

`setup()`方法有许多相关参数可以指定.详细信息如下:

### `name`

> `name='sample',`

这是工程名,用来决定你的工程在`PyPI`上的名称.根据[PEP 508](https://www.python.org/dev/peps/pep-0508),有效的工程名必须满足如下约束:

- 只能包含ASCII字母、数字、下划线`_`、分隔线`-`,以及/或者`.`,并且
- 开始和结束都只能是ASCII字母或者数字

### `version`

> `version='1.2.0',`

这是你的工程当前版本号.这个允许你的用户决定是否使用最新的版本还是指定使用特定版本.

### `description`

> description='A sample Python project',
> long_description=long_description,
> long_description_content_type='text/x-rst',

为你的工程指定短的以及长的描述.

长描述的内容类型可以由`long_description_content_type`指定,可以是`text/plain`、`text/x-rst`、`text/markdown`其中的一个,分别对应无格式、reStructuredText、Github Markdown方言.

### `url`

> `url='https://github.com/pypa/sampleproject',`

为你的工程指定主页.

### `author`

> `author='The Python Packaging Authority',`
> `author_email='pypa-dev@googlegroups.com',`

提供作者相关信息.

### `license`

> `license='MIT',`

许可证参数不必指示发布程序包的许可证，但如果需要，可以选择执行此操作.如果你使用的是标准化的、广泛应用的许可证.你可以通过`classifiers`参数来指定.`Classifiers`包含所有主流的开源协议.

许可证参数通常是用来指定与众所周知的许可证不同的,或者你自己独特的许可证.使用标准的、广泛应用的许可证是比较好的选择.

### `classifiers`

```PYTHON
classifiers=[
    # How mature is this project? Common values are
    #   3 - Alpha
    #   4 - Beta
    #   5 - Production/Stable
    'Development Status :: 3 - Alpha',

    # Indicate who your project is intended for
    'Intended Audience :: Developers',
    'Topic :: Software Development :: Build Tools',

    # Pick your license as you wish (should match "license" above)
    'License :: OSI Approved :: MIT License',

    # Specify the Python versions you support here. In particular, ensure
    # that you indicate whether you support Python 2, Python 3 or both.
    'Programming Language :: Python :: 2',
    'Programming Language :: Python :: 2.6',
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.2',
    'Programming Language :: Python :: 3.3',
    'Programming Language :: Python :: 3.4',
],
```

为你的工程提供分类列表.查看全部分类可以参见[https://pypi.org/classifiers/](https://pypi.org/classifiers/).

需要注意的是,虽然可以在分类中指定工程支持的Python版本,但是这个信息只是用来检索和查询.不是在安装工程时使用的.如果要限制工程能安装到的Python版本,可以使用`python_requires`参数.

### `keywords`

> `keywords='sample setuptools development',`

用来描述工程的关键字列表

### `project_urls`

```PYTHON
project_urls={
    'Documentation': 'https://packaging.python.org/tutorials/distributing-packages/',
    'Funding': 'https://donate.pypi.org',
    'Say Thanks!': 'http://saythanks.io/to/example',
    'Source': 'https://github.com/pypa/sampleproject/',
    'Tracker': 'https://github.com/pypa/sampleproject/issues',
},
```

### `packages`

> `packages=find_packages(exclude=['contrib', 'docs', 'tests*']),`

设置`packages`参数来列出你工程中的所有包,包含他们的子包等.虽然包可以手动列出,`setuptools.find_packages()`可以自动找出他们.使用`exclude`参数来指定哪些包不是用来发布和安装的.

### `py_modules`

> `py_modules=["six"],`

如果工程中包含一些单文件Python模块不属于这个包,设置`py_modules`列出所有的模块名(不带`.py`扩展名),这样`setuptools`就可以注意到.

### `install_requries`

指定工程运行所需的最小依赖,当工程通过`pip`安装时,能够自动安装其依赖.

### `python_requires`

如果你的工程只能运行在特定的Python版本上,则需要通过`python_requires`参数来指定对应的版本号.譬如你的包只能用于Python 3+:

> `python_requires='>=3',`

如果你的包用于Python 3.3之上,但是不支持Python 4:

> `python_requires='~=3.3',`

如果你的包是用于Python 2.6、Python2.7,所有在Python 3.3版本的Python 3:

> `python_requires='>=2.6, !=3.0.*, !=3.1.*, !=3.2.*, <4',`

### `package_data`

```PYTHON
package_data={
    'sample': ['package_data.dat'],
},
```

很多时候一些附加文件需要安装到包.这些通常是一些关系到包实现的数据文件,或者一些使用包的开发者会关注的文档内容,这些文件被成为"包数据".

该值必须是从包名称到应该复制到包中的相对路径名列表的映射,路径被解释为相对于包含包的目录.

更多详细信息参见`setuptools`的[Including Data Files](https://setuptools.readthedocs.io/en/latest/setuptools.html#including-data-files).

### `data_files`

> `data_files=[('my_data', ['data/data_file'])],`

虽然`package_data`能够满足大多数需求,但是在一些情况下你需要将数据文件放置于包之外.`data_files`允许你这样做.如果你需要安装一些其它程序要使用的文件,这个能满足你的需求.

每一个`(directory,files)`对指定了要安装到的路径以及要安装的文件.`directory`必须是相对路径,被解释为相对安装路径而言(针对默认安装设置使用`sys.prefix`;针对单一用户安装使用`site.USER_BASE`).在`files`的每个文件被解释为相对`setup.py`所在路径的相对路径.

想要获取更多信息可以参加[Installing Additional Files](http://docs.python.org/3/distutils/setupscript.html#installing-additional-files).

### `scripts`

虽然`setup()`支持使用`scripts`来指定要安装的`pre-make`脚本,为了保证跨平台兼容性,推荐使用`console_scripts`入口点设置.

### `entry_points`

```PYTHON
entry_points={
  ...
},
```

使用这个参数来指定工程提供的任何命名入口点插件.需要更多信息参见[Dynamic Discovery of Services and Plugins](https://setuptools.readthedocs.io/en/latest/setuptools.html#dynamic-discovery-of-services-and-plugins).

最常用的入口点是`console_scripts`.

### `console_scripts`

```PYTHON
entry_points={
    'console_scripts': [
        'sample=sample:main',
    ],
},
```

使用`console_scripts`来注册脚本入口(interfaces).可以让工具链将这些脚本入口转换成实际脚本.更多信息参见[Automatic Script Creation](https://setuptools.readthedocs.io/en/latest/setuptools.html#automatic-script-creation).

## `setup.cfg`

`setup.cfg`是`ini`格式的配置文件,用来为`setup.py`命令提供默认选项.

例如如果要生成的`whl`模块是纯`Python`模块,且支持`Python2`和`Python3`,则可以使用如下指令:

```CMD
python setup.py bdist_wheel --universal
```

而如果使用`setup.cfg`,其书写方式如下:

```INI
[bdist_wheel]
universal=1
```

运行`python setup.py bdist_wheel`时选项`universal`就会作为默认值使用.

也可以在`setup.cfg`中指定`license`文件,譬如:

```INI
[metadata]
license_files = LICENSE.txt
```

## `README.rst/README.md`

所有的工程都应该包含`readme`文件来阐述工程的目的.以`rst`为后缀的`reStructuredText`文件支持最为广泛,但不是必须的.多种格式的`Markdown`文件也支持.支持的格式具体参见`setup()`的参数[long_description_content_type](https://packaging.python.org/guides/distributing-packages-using-setuptools/#description).

`setuptools`在36.4.0+之后能够自动识别`README.rst`、`README.txt`、`README`以及`README.md`.如果使用`setuptools`,则不需要在`MANIFEST.in`文件中列出`readme`文件.

## `MANIFEST.in`

如果你需要打包一些附加文件,这些附加文件在以源代码发布时不会自动添加,那么你就需要`MANIFEST.in`文件.如果需要知道哪些文件会被默认添加,可以参见`distutils`文档[Specifying the files to distribute](https://docs.python.org/3/distutils/sourcedist.html#specifying-the-files-to-distribute)部分.

至于如何书写`MANIFEST.in`文件,可以参见`distutils`的[The MANIFEST.in template](https://docs.python.org/2/distutils/sourcedist.html#the-manifest-in-template)部分.

示例可见[PyPA sample project-MANIFEST.in](https://github.com/pypa/sampleproject/blob/master/MANIFEST.in)

## `LICENSE.txt`

版权文件,不用多说.

## 准备好之后

```CMD
python setup.py bdist_wheel
```

在`dist`文件夹下的`.whl`文件即为发布包.

## 参考链接

- [Packaging and distributing projects](https://packaging.python.org/guides/distributing-packages-using-setuptools/)
- [Welcome to Setuptools’ documentation!](https://setuptools.readthedocs.io/en/latest/index.html)

- [How To Package Your Python Code](https://python-packaging.readthedocs.io/en/latest/#)

- [Python application 的打包和发布](http://wsfdl.com/python/2015/09/06/Python%E5%BA%94%E7%94%A8%E7%9A%84%E6%89%93%E5%8C%85%E5%92%8C%E5%8F%91%E5%B8%83%E4%B8%8A.html)
- [Python application 的打包和发布](http://wsfdl.com/python/2015/09/08/Python%E5%BA%94%E7%94%A8%E7%9A%84%E6%89%93%E5%8C%85%E5%92%8C%E5%8F%91%E5%B8%83%E4%B8%8B.html)
