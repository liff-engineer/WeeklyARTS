# C++中的 Visitor 模式的实现方式

假设有`Animal`基类:

```C++
struct Animal
{
  virtual std::string Noise() const = 0;
  virtual ~Animal() = default;
};

using AnimalCollection = std::vector<Animal*>;
```

`Person`需要根据`Animal`的不同做出不同的反应:

```C++
void Person::ReactTo(Animal* _animal){
  if (dynamic_cast<Dog*>(_animal))
    RunAwayFrom(_animal);
  else if (dynamic_cast<Cat*>(_animal))
    TryToPet(_animal);
  else if (dynamic_cast<Horse*>(_animal))
    TryToRide(_animal);
}
```

当`Animal`的种类越来越多时,代码就会越来越复杂了.

这时我们可以采用`Visitor`模式来实现.

## 实现

首先定义`Visitor`：

```C++
struct ReactionVisitor
{
  explicit ReactionVisitor(Person* _person) : person_{_person}
  {}
  Person* person_ = nullptr; // person doing the reacting
};
```

调整`Animal`基类为:

```C++
struct Animal
{
  virtual std::string Noise() const = 0;
  virtual ~Animal() = default;
  virtual void Visit(ReactionVisitor& _visitor) = 0;
};
```

有一种选择是将`React`写入到具体的`Animal`类实现中:

```C++
void Dog::Visit(ReactionVisitor& _visitor){
  Person* personWhoIsReacting = _visitor.person_;
  if (my_breed == DogBreed.Daschund)
    personWhoIsReacting.TryToPet(this);
  else
    personWhoIsReacting.RunAwayFrom(this);
}
```

而这时的`Person`可以以如下方式提供通用接口,完成`React`动作:

```C++
void Person::ReactTo(Animal* _animal){
  ReactionVisitor visitor{this};
  _animal->Visit(visitor);
}
```

但是这样有一些问题,`Animal`自身与`Person`对其如何反应无关.需要将`Animal::Visit`实现剥离到`Visitor`中:

```C++
struct AnimalVisitor
{
  virtual void Visit(Cat*) = 0;
  virtual void Visit(Dog*) = 0;
  /*...*/
};

```

这时具体的`Animal`类`Visit`实现如下:

```C++
void Cat::Visit(AnimalVisitor* _visitor){ // overridden virtual method
    _visitor->Visit(this);
}

void Dog::Visit(AnimalVisitor* _visitor){ // overriden virtual method
    _visitor->Visit(this);
}
```

而我们可以继承自`AnimalVisitor`来针对每种具体的`Animal`书写相关实现:

```C++

struct ReactionVisitor : public AnimalVisitor
{
  void Visit(Cat*) override;
  void Visit(Dog* _dog) override{
    if (_dog.GetBreed() == DogBreed.Daschund)
      person_.TryToPet(this);
    else
      person_.RunAwayFrom(this);
  }
  Person* person_ = nullptr;
};

```

最终在`Person`中以如下方式使用:

```C++
void Person::ReactTo(Animal* _animal){
  ReactionVisitor visitor{this};
  _animal->Visit(&visitor);
}
```

这样实现有以下好处:

- 速度:不需要`dynamic_cast`或者`if...else`,需要两个虚函数调用.
- 封装:`Person`控制了其如何针对任意动物类型的反应
- 分离关注:`Person`对具体`Animal`的反应实现到具体的成员函数中
- `Animal`类接口更加稳定,新增`Animal`类不影响基类或者派生类

## 存在的问题

但是上述实现也有一些问题,每实现一种`Animal`都要在`AnimalVisitor`中添加,以及具体的类中实现`Visit`.

### 统一实现`Animal`的`Visit`

使用`Mixin`方式为`Animal`提供统一的`Visit`:

```C++
struct Animal
{
  virtual void Visit(AnimalVisitor* _visitor) = 0;
  // ...
};
template<class T>
struct VisitableAnimal : Animal
{
  void Visit(AnimalVisitor* _visitor) override
  {
    _visitor->Visit(static_cast<T*>(this));
  }
};

struct Cat : VisitableAnimal<Cat>
{
};

struct Dog : VisitableAnimal<Dog>
{
};
```

### 只关注特定类型

如果只关注部分特定类型,则可以考虑使用 CRTP,提供默认的`fallback`实现,然后实现特定`Visitor`来完成动作:

```C++
// DefaultDoNothingAnimalVisitor.h
#include "AnimalVisitor.h"

template<class T>
struct SingleDoNothingAnimalVisitor : virtual AnimalVisitor
{
  using AnimalVisitor::Visit;
  void Visit(T*) override{}
};

template<class... T>
struct MultipleDoNothingAnimalVisitor : public SingleDoNothingAnimalVisitor<T>...
{
  using SingleDoNothingAnimalVisitor<T>::Visit...;
};

// strong typedef
struct DoNothingAnimalVisitor : public MultipleDoNothingAnimalVisitor<Cat, Dog, ...>
{};
```

之后就可以继承自`DoNothingAnimalVisitor`来实现特定类型的处理:

```C++
struct CatFilter : DoNothingAnimalVisitor
{
  using DoNothingAnimalVisitor::Visit;
  void Visit(Cat* _cat) override
  {
    cats_.push_back(_cat);
  }
  std::vector<Cat*> cats_;
};
```

### 分发到默认实现

```C++
struct AnimalVisitor
{
  virtual void Visit(Animal*) = 0;
  // ... (other Visit methods)
};

struct DefaultAnimalVisitor : AnimalVisitor
{
  void Visit(Animal*) override{}
  void Visit(Cat* _cat) override{
    Visit(static_cast<Animal*>(_cat);
  }
  void Visit(Dog* _dog) override{
    Visit(static_cast<Animal*>(_dog));
  }
  // ...
};
```

这样都会走到`Visit(Animal*)`实现中,这样可以排除掉特定实现:

```C++
struct DefaultAnimalVisitor : AnimalVisitor
{
    void Visit(Animal*){}
    void Visit(Cat* _cat){Visit(static_cast<Animal*>(_cat));}
    void Visit(Dog* _dog){Visit(static_cast<Animal*>(_dog));}
    // ...
};

struct AllButCatFilter : DefaultAnimalVisitor
{
    using DefaultAnimalVisitor::Visit;
    void Visit(Animal* _animal) override
    {
        animals_.push_back(_animal);
    }
    void Visit(Cat*) override{/*intentionally blank*/}
    std::vector<Animal*> animals_;
};
```

### 免依赖处理

之前的方式都需要`Visitor`基类知道几乎所有的派生类,还有一种方式可以免除这个烦恼:

```C++
template<typename Visitable>
struct Visitor
{
    virtual void Visit(Visitable* obj) = 0;
};

struct AnimalVisitorBase{
    virtual ~AnimalVisitorBase() = default;
};

struct Dog
{
  virtual void Visit(AnimalVisitorBase* _visitor) override
  {
    if(auto ev = dynamic_cast<Visitor<Dog>*>(_visitor)){
        ev->Visit(this);
    }
  }
};

```

这时就可以采用如下实现来处理几种具体的`Animal`类:

```C++
struct AnimalVisitor:AnimalVisitorBase,Visitor<Dog>,Visitor<Cat>
{
    void Visit(Dog* obj) override;
    void Visit(Cat* obj) override;
};
```

当类列表变得臃肿时可以使用模板:

```C++
template<typename... Args>
struct Visitors:Visitor<Args...>{
    ;
};

struct AnimalVisitor:AnimalVisitorBase,Visitors<Dog,Cat>{
    void Visit(Dog* obj) override;
    void Visit(Cat* obj) override;
};
```

## 另外一种方式

在[Implementation Challenge: Revisiting the visitor pattern](https://foonathan.net/blog/2017/12/21/visitors.html)中展示了另外一种`Visitor`模式实现的方式,利用`typeid`、`void*`等方式达到了更好的效果.

## 参考资料

-[Stop reimplementing the virtual table and start using double dispatch](https://gieseanw.wordpress.com/2018/12/29/stop-reimplementing-the-virtual-table-and-start-using-double-dispatch/)

-[https://gieseanw.wordpress.com/2018/12/29/reuse-double-dispatch/](https://gieseanw.wordpress.com/2018/12/29/reuse-double-dispatch/)
