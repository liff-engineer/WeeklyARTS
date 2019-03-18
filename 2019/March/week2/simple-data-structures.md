# [简洁数据结构](https://arne-mertz.de/2018/12/simple-data-structures/)

保持简单数据结构简洁!当你拥有的是一堆数据时,不需要手工模拟封装.

最近我看到一个类声明及实现如下:

```C++
class Unit {
public:

  Unit(std::string name_, unsigned points_, int x_, int y_)
    : name{name_}, points{points_}, x{x_}, y{y_}
  {}

  Unit(std::string name_)
    : name{name_}, points{0}, x{0}, y{0}
  {}

  Unit()
    : name{""}, points{0}, x{0}, y{0}
  {}

  void setName(std::string const& n) {
    name = n;
  }

  std::string const& getName() const {
    return name;
  }

  void setPoints(unsigned p) {
    points = p;
  }

  unsigned getPoints() const {
    return points;
  }

  void setX(int x_) {
    x = x_;
  }

  int getX() const {
    return x;
  }

  void setY(int y_) {
    y = y_;
  }

  int getY() const {
    return x;
  }

private:
  std::string name;
  unsigned points;
  int x;
  int y;
};
```

让我们仔细看看,因为这种结构的实现可以更简洁.

## 开放成员访问

其中实现的`getter`和`setter`,基本上就是一堆样板代码.关于面向对象的书籍经常谈论封装,他们鼓励我们为所有的成员变量使用`getter`和`setter`.

封装意味着一些数据应该被保护起来避免直接访问.通常这是因为有相应逻辑与这些数据绑定在一起.这种情况下,访问函数需要做检查,并且一些数据可能需要同步调整.

但是C++[不是纯粹的面向对象语言](https://arne-mertz.de/2015/07/c-is-not-an-object-oriented-language/).在一些场景下,我们的数据结构仅仅是一堆数据.这时,最好是使用结构体及公开的数据成员,而不是隐藏到伪装类后面.效果是一样的,任何人都可以无限制地访问所有内容.

## 如果逻辑在其他地方怎么办?

有时,类似于这个的类只是作为数据容器,逻辑是在其他地方的.在`domain objects`场景下,是种被称为[Anemic Domain Model](https://www.martinfowler.com/bliki/AnemicDomainModel.html)的反模式.通常的解决方案是重构代码将逻辑移动到类中与数据共存.

无论我们这样做还是选择将数据和逻辑分离,都需要考虑情况.如果我们决定保持数据和逻辑的分离.那么就按照这次方式实现.这种场景下,回到我们最初的问题:使用带公开数据的结构体替代类.

即使我们决定将逻辑合并到类中,也很少有封装是存在于类之外的(?),其中一个例子是`pimpl idiom`的详细类;这个类只有`pimpl`和包含类可以访问,添加`getter`和`setter`也是没有意义的.

## 构造函数

通常需要构造函数来创建一致状态的对象并建立不变关系.在普通数据结构中,并没有一致状态和不变关系需要维护.示例中的构造函数只是为了避免这种场景:默认构造对象然后立即为每个成员通过`setter`设置值.

如果在咨询看,甚至会发现实现中有潜在的`bug`:任何`std::string`都会隐式转换成`Unit`,因为单参数构造函数没有声明为`explicit`. 这种写法会导致[许多调试乐趣和头脑风暴](https://arne-mertz.de/2015/03/fun-without-keyword-explicit/).

C++11提供了非静态成员初始化特性,在类似于示例中的场景,可以用来替代构造函数.上述所有的构造函数都可以通过该方法完成.这时,示例中的53行代码可以简化为6行:

```C++
struct Unit {
  std::string name{ "" };
  unsigned points{ 0 };
  int x{ 0 };
  int y{ 0 };
};
```

如果使用统一初始化,初始化方式就和之前的一样了:

```C++
Unit a{"Alice"};
Unit b{"Bob", 43, 1, 2};
Unit c;
```

## 如果其中一个成员有逻辑怎么办?

名字有可能不能为空或者包含特定字符.这是否意味着我们应该抛弃之前的,重新实现合适的`Unit`类? 可能不需要.通常我们会为字符串的验证提供逻辑实现.在我们使用这些数据之前,程序或者库应当校验过,我们可以假设这些数据都是有效的.

如果这个太接近`Anemic Domain Model`,我们仍然不需要在`Unit`中封装所有成员.我们可以实现包含逻辑的自定义类型来替代`std::string`.毕竟,`std::string`只是一堆字符.如果需要一些不同的东西,`std::string`只是使用起来便利,但是这是错误的选择.我们的自定义类型可能会包含合适的构造函数,从而使得它不能被默认构造成空字符串.

## 如果其中的一些数据属于一起的?

再检查一下类,可以很肯定`x`和`y`表示一些坐标.很可能是一起的,那么我们是否需要提供方法使其可以一起设置?又或者构造函数应允许其同时操作？

这不是合适的解决方案.它可以弥补一些存在的问题,但是依然存在[Data Clump](https://arne-mertz.de/2017/08/code-smells-short-list/#Data_Clump)这种代码坏味道.这是两个属于一起的变量,就应当拥有他们的结构体或者类.

## 结论

最后,我们的`Unit`实现如下:

```C++
struct Unit {
  PlayerName name;
  unsigned points{ 0 };
  Point location{ {0,0} };
};
```

它很小,很简洁.事实上,结构体加上公开的成员传达了正确的信息:这就是一堆数据.

## 总结

C++11开始引入了统一初始化,类/结构体的书写带来了一些改变,同时关于何时用`class`,何时用`struct`,[ C++ Core Guidelines](https://github.com/isocpp/CppCoreGuidelines/blob/master/CppCoreGuidelines.md)也有相应的总结. 我依然可以碰到大量文中开头的写法,可能是因为还用不上`Modern C++`,又或者总是想着面向对象. 记住, Keep It Simple,Stupid.