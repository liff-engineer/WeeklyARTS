# C++中的修饰器模式

我们都知道以面向对象的方式来实现修饰器是如何做到的,但是 C++支持另外一种写法:静态修饰器.

譬如我们有个`Shape`类,包含了`str`方法:

```C++
struct Shape
{
    virtual std::string str() const = 0;
};
```

然后我们会实现一些`Circle`,`Square`:

```C++
struct Circle:Shape
{
    float radius;

    explict Circle(float radius):radius{radius}{};

    void resize(float factor) { radius*=factor; }

    std::string str() const override
    {
        std::ostringstream oss;
        oss << "A circle of radius " << radius;
        return oss.str();
    }
};
```

## 动态修饰器

那么带颜色的`Shape`呢?我们会以如下方式实现:

```C++
struct ColoredShape: Shape
{
    Shape& shape;
    std::string color;

    ColoredShape(Shape& shape,std::string const& color)
    :shape{shape},color{color}{};

    std::string str() const override
    {
        std::ostringstream oss;
        oss << shape.str() << "has the color" << color;
        return oss.str();
    }
};
```

如果是带透明度的`Shape`呢?

```C++
struct TransparentShape: Shape
{
    Shape& shape;
    uint8_t transparency;

    TransparentShape(Shape& shape,uint8_t transparency)
    :shape{shape},transparency{transparency}{};

    std::string str() const override
    {
        std::ostringstream oss;
        oss << shape.str() << "has " << static_cast<float>(transparency) / 255.f*100.f <<"% transparency";
        return oss.str();
    }
};
```

## 静态修饰器

带颜色的`Shape`：

```C++
template<typename T> struct ColoredShape:T
{
    static_assert(std::is_base_of<Shape,T>::value,"Template argument must be a Shape");

    std::string color;

    std::string str() const override
    {
        std::ostringstream oss;
        oss << T::str() << "has the color" << color;
        return oss.str();
    }
};
```

带透明的`Shape`:

```C++
template<typename T> struct TransparentShape:T
{
    static_assert(std::is_base_of<Shape,T>::value,"Template argument must be a Shape");

    uint8_t transparency;

    template<typename... Args>
    TransparentShape(uint8_t transparency,Args... args)
    :T(std::forward<Args>(args)...),transparency{transparency}{};

    std::string str() const override
    {
        std::ostringstream oss;
        oss << T::str() << "has " << static_cast<float>(transparency) / 255.f*100.f <<"% transparency";
        return oss.str();
    }
};

```

使用方式如下:

```C++
ColoredShape<TransparentShape<Square>> sq = {"red",51,5};
std::cout<< sq.str()<< std::endl;
```

## 总结

可以看到,采用模板技术的静态修饰器不仅能够完成功能,而且还保留了最初的信息,不需要维持两份.
