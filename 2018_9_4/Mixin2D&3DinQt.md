# 如何整合3D内容到Qt Graphics View

最近工作中碰到一个场景,要在3D模型的Viewer上嵌入2D的内容,并且提供编辑功能,思路如下:

- 3D模型的Viewer切换成特定的2D视角
- 2D内容以Qt Graphics View实现
- 将2D内容覆盖到3D内容上
- 在QGraphicsView上实现平移缩放等操作,同步调整3D

看了各种资料都不太清晰,譬如:

- [Qt的Graphics-View框架和OpenGL结合详解](http://www.cnblogs.com/suncoolcat/p/3343369.html)
- [C++ GUI Programming with Qt4: 3D Graphics](http://www.informit.com/articles/article.aspx?p=1405557&seqNum=2)

而且从Qt5.4开始提供了相对Modern的OpenGL操作方式,资料相对较旧,不推荐使用。

经过一段时间的了解及摸索,阅读了一些资料：

- [Convert Your Legacy OpenGL Code to Modern OpenGL with Qt](https://www.slideshare.net/ICSinc/convert-your-legacy-opengl-code-to-modern-opengl-with-qt-ondemand-video)

搞清楚了实现的思路及方法,记录如下。

## 解决方案

游戏等3D应用均以定时刷新来触发OpenGL重绘三维场景,而Qt的QGraphicsView等界面是按需绘制的,也就是说,如果想要实现2D内容覆盖到3D内容上的方式,则需要使用OpenGL先绘制3D场景,再绘制2D场景,并且同步刷新。

- 切换QGraphicsView的viewport为QOpenGLWidget,使得2D场景以OpenGL进行绘制
- 重载QGraphicsView或者QGraphicsScene的drawBackground方法,在这个时机绘制3D场景

由于QGraphicsScene的背景在内容之前绘制,就使得先绘制3D场景再绘制2D场景有了保证。

## 替换QGraphicsView的viewport

QGraphicsView通过自身的viewport来进行绘制动作,如果想要以OpenGL绘制QGraphicsScene进行绘制,则需要构造出QOpenGLWidget并替换掉原有viewport：

```C++
QOpenGLWidget* viewport = new QOpenGLWidget;
QGraphicsView viewer;
viewer.setViewport(viewport);
viewer.setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
```

需要注意的是QOpenGLWidget使用时要指定`QSurfaceFormat`,如果多个QOpenGLWidget的父一样,其`QSurfaceFormat`也应该一样,可以指定默认的`QSurfaceFormat`:

```C++
QSurfaceFormat fmt;
fmt.setRenderableType(QSurfaceFormat::OpenGL);
fmt.setProfile(QSurfaceFormat::CoreProfile);
fmt.setVersion(3, 3);

QSurfaceFormat::setDefaultFormat(fmt);
```

由于OpenGL不能局部刷新,要把`QGraphicsView`的刷新模式修改为`FullViewportUpdate`,全部重绘。

使用上述操作,即可将`QGraphicsView`的场景绘制引擎替换成OpenGL。

## Qt中使用OpenGL

在常规的操作中,通常是直接使用`glClearColor`等OpenGL API的,而在Qt中,为了避免使用扩展的OpenGL接口较为麻烦等困扰,Qt提供了`QOpenGLFunctions`,通过继承自`QOpenGLFunctions`,即可使用经过包装过的OpenGL API,使用方式如下:

```C++
class D3Scene :protected QOpenGLFunctions
{
public:
    void initialize();
    void render();
};
void D3Scene::initialize()
{
    initializeOpenGLFunctions();
}
void D3Scene::render()
{
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
}
```

注意要在合适的时机调用`initializeOpenGLFunctions`完成初始化动作,也可以在`render`中执行,内部保证了只会调用一次完成初始化。

## `drawBackground`来实现3D绘制

对`QGraphicsScene`等的`drawBackground`进行重载时需要注意要检查当前的绘制引擎是否为OpenGL,且在使用OpenGL的API完成绘制时,要使用`QPainter`的`beginNativePainting`和`endNativePainting`方法：

```C++
class D3GraphicsScene :public QGraphicsScene,protected QOpenGLFunctions
{
protected:
    void drawBackground(QPainter *painter, const QRectF &rect);
};

void D3GraphicsScene::drawBackground(QPainter * painter, const QRectF & rect)
{
    auto type = painter->paintEngine()->type();
    if (type != QPaintEngine::OpenGL && type != QPaintEngine::OpenGL2) {
        qWarning("D3GraphicsScene: drawBackground needs a QOpenGLWidget to be set as viewport on the graphics view");
        return;
    }
    initializeOpenGLFunctions();

    painter->beginNativePainting();

    //绘制3D场景
    glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    painter->endNativePainting();
}

```

## 完整代码样例

`D3GraphicsScene.hpp`:

```C++
#include <QtGui/QOpenGLFunctions>
#include <QtWidgets/QGraphicsScene>

class D3GraphicsScene :public QGraphicsScene,protected QOpenGLFunctions
{
public:
    explicit D3GraphicsScene(QObject *parent = nullptr);
    ~D3GraphicsScene();

protected:
    void drawBackground(QPainter *painter, const QRectF &rect);
};
```

`D3GraphicsScene.cpp`:

```C++
#include <QtGui/QPainter>
#include <QtGui/QPaintEngine>
#include <QtCore/QDebug>

D3GraphicsScene::D3GraphicsScene(QObject * parent)
    :QGraphicsScene(parent)
{

}

D3GraphicsScene::~D3GraphicsScene()
{
}

void D3GraphicsScene::drawBackground(QPainter * painter, const QRectF & rect)
{
    auto type = painter->paintEngine()->type();
    if (type != QPaintEngine::OpenGL && type != QPaintEngine::OpenGL2) {
        qWarning("D3GraphicsScene: drawBackground needs a QOpenGLWidget to be set as viewport on the graphics view");
        return;
    }
    initializeOpenGLFunctions();

    painter->beginNativePainting();

    glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    painter->endNativePainting();
}
```

`main.cpp`：

```C++
#include <QtWidgets/QApplication>
#include <QtWidgets/QGraphicsView>
#include <QtWidgets/QOpenGLWidget>
#include <QtWidgets/QGraphicsItem>

int main(int argc, char** argv)
{
    QApplication app(argc, argv);
    QSurfaceFormat fmt;
    fmt.setRenderableType(QSurfaceFormat::OpenGL);
    fmt.setProfile(QSurfaceFormat::CoreProfile);
    fmt.setVersion(3, 3);
    QSurfaceFormat::setDefaultFormat(fmt);

    QOpenGLWidget* viewport = new QOpenGLWidget;

    D3GraphicsScene *scene = new D3GraphicsScene;

    QGraphicsView viewer;

    viewer.setViewport(viewport);
    viewer.setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
    viewer.setScene(scene);

    auto item = scene->addSimpleText("!--------------------!");
    item->setFlag(QGraphicsItem::ItemIsSelectable);
    item->setFlag(QGraphicsItem::ItemIsFocusable);
    item->setFlag(QGraphicsItem::ItemIsMovable);

    viewer.resize(800, 600);
    viewer.show();

    return app.exec();
}
```
