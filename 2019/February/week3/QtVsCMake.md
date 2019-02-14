# Qt 与 CMake

Qt 与 CMake 是如何结合的?

## 找到 Qt

Qt 自身提供了与 CMake 整合的 cmake 脚本,位于安装目录的`lib/cmake`下,如果想要以`CMake`的方式使用 Qt,首先需要使`CMake`可以找到`lib/cmake`下的`cmake`脚本.

Qt 一般都是通过环境变量设置的,所以使用`$ENV{QTDIR}`就能够找到当前 Qt.而要使得`CMake`能够找到对应的脚本,需要追加到`CMAKE_PREFIX_PATH`上.形式如下:

```CMAKE
list(APPEND CMAKE_PREFIX_PATH $ENV{QTDIR})
```

## 查找 Qt 库依赖

通过以上步骤就可以使用`find_package`来查找`Qt`,譬如需要带`Widgets`模块的`Qt5`,则可以以如下方式实现:

```CMAKE
find_package(Qt5 COMPONENTS Widgets REQUIRED)
```

## 为目标设定 Qt 库依赖

找到对应的`Qt5`之后,就可以使用`target_link_libraries`来为目标配置 Qt 相关库依赖了.注意这个配置会自动配置好头文件路径、库依赖、编译选项等等等等.

```CMAKE
target_link_libraries(example
    PRIVATE Qt5::Widgets
)
```

可以看到语法中有个`PRIVATE`,来表示`Qt5::Widgets`仅仅被目标`example`内部依赖.如果`example`的外部接口使用到了`Qt5::Widgets`的头文件等定义,则需要定义为`PUBLIC`,否则依赖于`example`的目标还需要再配置一次`Qt5::Widgets`依赖.详情参见`CMake`文件及一些`Modern CMake`教程.

## 配置自动处理`MOC`

如果源代码中的类包含了`Q_OBJECT`,则需要`MOC`动作.QtCreater 会自动处理,VisualStudio 需要插件辅助,而在`CMake`中这个也可以通过配置来自动检测并处理.

譬如目标`example`中包含的`MainWindow`类需要`MOC`,可以给`example`目标配置自动检测处理:

```CMAKE
set_target_properties(example PROPERTIES
    AUTOMOC ON
)
```

由于有 moc 动作,需要将`moc_MainWindow.cpp`等自动生成的文件也置于`include`路径中.这需要如下设置:

```CMAKE
set(CMAKE_INCLUDE_CURRENT_DIR ON)
```

## 生成 GUI 程序

Windows 的 GUI 主程序入口是`WinMain`,而使用 Qt 时统一是`main`.如果要生成 GUI 程序,需要进行配置:

```CMAKE
if(MSVC)
    set_target_properties(example PROPERTIES
        WIN32_EXECUTABLE ON
    )
endif()
```

这样会链接`qtmain.lib`,来保证能够正确生成 GUI 程序.

## 完整实现

经过上述操作就能够使用`CMake`来构建 Qt 应用程序了.源代码如下:

```C++
//MainWindow.hpp
#pragma once

#include <QtWidgets/QMainWindow>

class MainWindow : public QMainWindow
{
    Q_OBJECT
  public:
    explicit MainWindow(QWidget *parent = nullptr, Qt::WindowFlags flags = 0);
    ~MainWindow() = default;
};
```

```C++
//MainWindow.cpp
#include "MainWindow.hpp"

MainWindow::MainWindow(QWidget *parent, Qt::WindowFlags flags)
    : QMainWindow(parent, flags)
{
    setWindowTitle(QString::fromWCharArray(L"Qt与CMake"));
}
```

```C++
//main.cpp
#include "MainWindow.hpp"
#include <QtWidgets/QApplication>

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    MainWindow w;
    w.show();
    return app.exec();
}
```

```CMAKE
#CMakeLists.txt

cmake_minimum_required(VERSION 3.13.2)

##从环境变量QTDIR加载Qt
list(APPEND CMAKE_PREFIX_PATH $ENV{QTDIR})
##从路径加载Qt
#list(APPEND CMAKE_PREFIX_PATH  "C:/Qt/5.6.3/msvc2015_64")

project(QtVsCMake)

##查找Qt5,必须包含组件Widgets
find_package(Qt5 COMPONENTS Widgets REQUIRED)

##添加应用程序
add_executable(example)

##如果是MSVC则指定应用程序为GUI
if(MSVC)
    set_target_properties(example PROPERTIES
        WIN32_EXECUTABLE ON
    )
endif()

##example目标自动处理MOC
set_target_properties(example PROPERTIES
    AUTOMOC ON
)

##由于有moc,则需要将moc生成目录也添加到include路径
set(CMAKE_INCLUDE_CURRENT_DIR ON)

##为目标配置源文件
set(PROJECT_SOURCES
    main.cpp
    MainWindow.cpp
)

target_sources(example
    PRIVATE ${PROJECT_SOURCES}
)

##为目标配置库依赖
target_link_libraries(example
    PRIVATE Qt5::Widgets
)
```

## 如何处理`qrc`

麻烦还没有结束,如果使用了 Qt 的资源管理,则需要处理`qrc`文件.同样的,CMake 也提供了自动检测处理的方法:

```CMAKE
set_target_properties(example PROPERTIES
    AUTORCC ON
)
```

这样之后,如果有`qrc`文件,就可以以类似源代码的形式添加了:

```CMAKE
target_sources(example
    PRIVATE src/resources.qrc
)
```

另外,Windows 的`rc`文件添加方式一致,不需要配置`AUTORCC`属性即可.

## 如何处理`ui`文件

虽然基本上都是用源代码构建 UI,但是也有需要使用`.ui`文件的时候,处理方式也一样:

```CMAKE
set_target_properties(example PROPERTIES
    AUTOUIC ON
)
```

然后以类似源代码的形式添加:

```CMAKE
target_sources(example
    PRIVATE src/mainwindow.ui
)
```

## 如何处理翻译文件

自行谷歌.

## 总结

Qt 和 CMake 都比较令人...,怎么说呢,整个 C++的生态环境都不太好.不过可以预见的是以后会向好的方向发展.譬如`Boost`和`Qt`都在转向使用`CMake`构建,各个工具(Visual Studio、QtCreater)对`CMake`的支持都在增强,包管理工具`vcpkg`就是基于`CMake`.

虽然`CMake`不怎么样,基本上已成为"事实标准",值得学习,不过记得学`Modern CMake`.网上能找到的资料都不怎么`Modern`.

PS.Qt 未来会加大对`CMake`的支持力度,个人觉得不要浪费时间搞什么`qmake`和`msbuild`.

- [The Qt Company Decides To Deprecate The Qbs Build System, Will Focus On CMake & QMake](https://www.phoronix.com/scan.php?page=news_item&px=Qt-QMake-CMake-Future-Not-Qbs)
- [Deprecation of Qbs](https://blog.qt.io/blog/2018/10/29/deprecation-of-qbs/)

## 参考文档

- [CMake Manual](https://doc.qt.io/qt-5/cmake-manual.html)
- [cmake-qt(7)](https://cmake.org/cmake/help/latest/manual/cmake-qt.7.html)
- [CMake 中添加 Qt 模块的合理方法](https://zhuanlan.zhihu.com/p/34667993)
- [CMake it modern using C++ and Qt, Part 1](https://www.cleanqt.io/blog/cmake-it-modern-using-c%2B%2B-and-qt,-part-1)
- [Qt-CMake-HelloWorld](https://github.com/jasondegraw/Qt-CMake-HelloWorld)
- [CMake: Finding Qt 5 the “Right Way”](https://blog.kitware.com/cmake-finding-qt5-the-right-way/)
