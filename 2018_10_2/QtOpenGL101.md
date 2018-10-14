# Qt中的OpenGL

之前写过一篇介绍如何整合3D内容到QGraphicsView的文章,其中只简要介绍了一下Qt中如何使用OpenGL,实际上Qt对OpenGL进行了很多封装操作,而网上能够搜索到的资料都相对较旧,因而结合自己的学习,针对Qt与OpenGL整合使用做一些简要介绍。

## 运行环境

在Qt5.x版本中提供了`QOpenGLWindow`和`QOpenGLWidget`来供`OpenGL`进行绘制,这两者不同之处在于`QOpenGLWindow`不依赖于`QtWidget`模块,而且能够提供更好的性能;`QOpenGLWidget`可以作为`QWidget`使用。

需要注意的是使用到`QOpenGLWidget`等,如果设置了父`QWidget`,则会将整个父子关系下的所有`QWidget`绘制引擎全部调整为`OpenGL`,常规使用是没有问题的,一旦需要半透明等效果,和其他使用自定义绘制引擎的`QWidget`会出现先后绘制等问题。

`QOpenGLWindow`及`QOpenGLWidget`均可以构造`QPainter`并使用其进行常规绘制动作。

## QOpenGLShader及QOpenGLShaderProgram

在`OpenGL`编程中,提供给`GPU`的是`Shader`,Qt中对其进行了封装,来免除开发者手动封装`ShaderProgram`,同时将`VAO`等操作整合到了`QOpenGLShaderProgram`中,在操作`Shader`内部变量常量等时必须使用`QOpenGLShaderProgram`,这个是需要特别注意的

## `VBO`等`Buffer Objects`

在`OpenGL`中,顶点、索引、材质等等`Buffer Objects`,譬如`VBO`,这些需要传递给`GPU`的缓存对象,在Qt中被封装为`QOpenGLBuffer`,避免了手动操作或者自行封装的烦恼

## `VAO`

Qt将`VAO`封装成为`QOpenGLVertexArrayObject`,使用方式如下:

- 场景初始化时
    - 绑定VAO
    - 设置对象的顶点、法向、材质等顶点数据状态
    - 解绑VAO
- 渲染可视化对象时
    - 绑定VAO
    - 执行`glDraw*()`
    - 解绑VAO

这样可以仅仅在顶点数据状态更新时操作`VBO`等,渲染过程仅仅与`ShaderProgram`和`VAO`有关。

需要注意的是,`QOpenGLVertexArrayObject`实现是`nocopyable`的。

## 矩阵等操作

在`OpenGL`中要实现摄像机等则需要外部库的帮助,而Qt也提供了对应的类来辅助操作,譬如`QMatrix4x4`矩阵实现,以及2D、3D、4D空间的点及矢量表示`QVector2D`、`QVector3D`、`QVector4D`,使用四元数实现空间旋转时可以使用`QQuaternion`.

## 总结

在`OpenGL`编程中使用的基本内容均可以在`Qt`中找到相应的封装,如果是基于`Qt`的应用程序,可以考虑使用`Qt`封装的`OpenGL`类,能够方便不少。