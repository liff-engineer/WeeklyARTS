# [C++ & Python - pybind11 入门](https://github.com/pybind/pybind11)

虽然说"人生苦短我用Python",但是一旦追求效率,大家又会想起C++,那么有没有可能结合Python和C++各自优势呢?

你不是第一个这样想的人,在Boost库中提供了`Boost.Python`,使得可以直接将C++常量、函数、类到出成为Python库模块使用,而在C++11广泛应用的今天,相对更为简洁的`pybind11`更值得考虑,这里就展示一下如何使用C++为Python开发扩展模块.

## 前提条件

- Visual Studio 2015或者Visual Studio 2017,建议用Visual Studio 2017
- Python 3.x,使用Python 2.x也可以
- [vcpkg](https://github.com/Microsoft/vcpkg),C++库管理工具

环境准备:

1. 安装pybind11: .\vcpkg.exe install pybind11 pybind11:x64-windows
2. 检查python路径:python -h

## 建立工程

新建动态链接库工程,譬如说`example`.然后修改工程配置:

- 在"常规"页签将"目标文件扩展名"调整为`.pyd`
- 在"C/C++"页签将"附近包含目录"新增python头文件路径,例如`C:\Users\liff\AppData\Local\Programs\Python\Python36\include`
- 在"链接器"的"输入"页签向"附加依赖项"新增python库文件路径,例如`C:\Users\liff\AppData\Local\Programs\Python\Python36\libs\python36.lib`

这时工程就配置完成,可以开始编码了.

## `Hello pybind11`

假设有个`add`方法需要暴露给Python使用:

```C++
int add(int i, int j) {
    return i + j;
}
```

首先使用`#include <pybind11/pybind11.h>`导入`pybind11`,然后定义`module`:

```C++
#include <pybind11/pybind11.h>

PYBIND11_MODULE(example, m) {
    //...
}
```

在这里`PYBIND11_MODULE`定义了Python模块,`example`是模块名,`m`是模块入口.为其添加说明:

```C++
m.doc() = u8"pybind11示例插件";
```

然后向`m`添加`add`定义:

```C++
m.def("add",&add);
```

也可以为`add`添加函数说明:

```C++
m.def("add", &add, u8"两整数相加函数");
```

这时编译生成`example.pyd`,然后再其所在目录启动`python`试试:

```Python
λ python.exe                                                                                     
Python 3.6.5 (v3.6.5:f59c0932b4, Mar 28 2018, 17:00:18) [MSC v.1900 64 bit (AMD64)] on win32     
Type "help", "copyright", "credits" or "license" for more information.                           
>>> import example                                                                               
>>> help(example)                                                                                
Help on module example:                                                                          
                                                                                                 
NAME                                                                                             
    example - pybind11示例插件                                                                       
                                                                                                 
FUNCTIONS                                                                                        
    add(...) method of builtins.PyCapsule instance                                               
        add(arg0: int, arg1: int) -> int                                                         
                                                                                                 
        两整数相加函数                                                                                  
                                                                                                 
FILE                                                                                             
    c:\users\liff\source\repos\xanalyzer\x64\debug\example.pyd                                   
                                                                                                 
```

然后使用`add`试试:

```CMD
>>> example.add(1,2)
3
>>>
```

## 导出变量

如果要将C++中某个值导出,可以使用`attr`函数来实现,对于C++语言内建类型和一些通常的对象,`attr`可以自动处理,也可以使用`pybind11::cast`进行显式转换:

```C++
PYBIND11_MODULE(example, m) {
    m.attr("the_answer") = 42;
    py::object world = py::cast("World");
    m.attr("what") = world;
}
```

这时在Python中使用:

```Python
>>> import example
>>> example.the_answer
42
>>> example.what
'World'
```

## 导出类

针对C++中的类或者结构体,则需要使用`class_`来创建,譬如如下结构体:

```C++
struct Pet {
    Pet(const std::string &name) : name(name) { }
    void setName(const std::string &name_) { name = name_; }
    const std::string &getName() const { return name; }

    std::string name;
};
```

使用`class_`来创建对应的Python对象,同时要使用`pybind11::init`来为其定义初始化/构造函数:

```C++
#include <pybind11/pybind11.h>

namespace py = pybind11;

PYBIND11_MODULE(example, m) {
    py::class_<Pet>(m, "Pet")
        .def(py::init<const std::string &>())
        .def("setName", &Pet::setName)
        .def("getName", &Pet::getName);
}
```

然后就可以在Python中使用:

```C++
>>> import example
>>> p = example.Pet('Molly')
>>> print(p)
<example.Pet object at 0x10cd98060>
>>> p.getName()
u'Molly'
>>> p.setName('Charly')
>>> p.getName()
u'Charly'
```

## 总结

pybind11还有相当多的特性来支持将C++暴露成Python模块,而且具有相对无缝的"操作"体验.使用这样的库,就能够综合使用C++与Python两种语言来完成工作,鱼和熊掌可以兼得.