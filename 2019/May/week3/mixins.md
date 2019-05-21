# [What are Mixins (as a concept)](https://stackoverflow.com/questions/18773367/what-are-mixins-as-a-concept)

## 问题

我试图了解 Mixin 概念,但是我似乎无法理解这个是什么.我所能看到的是这是一种通过继承来扩展类能力的方式.我了解到人们将它们称为"抽象子类".有人能够给我解释一下为什么吗?

## 解答

在讨论什么是 Mixin 之前,先来描述以下它尝试解决的问题将会很有用.假设你有很多主意或者概念尝试去建模.他们可能以某种方式相关联,但是大多数情况下是正交的-- 这意味着它们可以彼此独立.现在,你可以通过继承建模,并将每个概念从一些通用接口类中派生出来.这时你在派生类中提供具体的方法来实现接口.

这种方法的问题在于,这种设计没有提供任何清晰直观的方法,来获取每个具体类,并将其组合在一起.

Mixin 的想法是提供一堆原始类,这些类中的每一个都对应了一个基本的正交概念/模型,然后可以将其组合在一起成为更为复杂的类,包含一些你想要的功能,就如乐高一样.这些原始类被当作构建块使用.这是比较有扩展性的,之后你可以添加其他原始类到集合,原有的原始类不会受到任何影响.

回到 C++中,实现这种想法的一种技术是使用模板和继承.基本的思路是,通过模板参数来提供对应的构建块,然后将其连接到一起.你可以通过`typedef`等方式将其链接到一起,构造出新的形式来包含你想要的功能.从你的例子来说,让我们看一看如果在其之上添加`redo`功能,其形式可能如下:

```C++
#include <iostream>
using namespace std;

struct Number
{
  typedef int value_type;
  int n;
  void set(int v) { n = v; }
  int get() const { return n; }
};

template <typename BASE, typename T = typename BASE::value_type>
struct Undoable : public BASE
{
  typedef T value_type;
  T before;
  void set(T v) { before = BASE::get(); BASE::set(v); }
  void undo() { BASE::set(before); }
};

template <typename BASE, typename T = typename BASE::value_type>
struct Redoable : public BASE
{
  typedef T value_type;
  T after;
  void set(T v) { after = v; BASE::set(v); }
  void redo() { BASE::set(after); }
};

typedef Redoable< Undoable<Number> > ReUndoableNumber;

int main()
{
  ReUndoableNumber mynum;
  mynum.set(42); mynum.set(84);
  cout << mynum.get() << '\n';  // 84
  mynum.undo();
  cout << mynum.get() << '\n';  // 42
  mynum.redo();
  cout << mynum.get() << '\n';  // back to 84
}
```

你会注意到我对你原始的代码做了一些修改:

- 虚函数没有必要,因为我们确切知道我们编写的类类型在编译期是什么
- 我添加了默认的`value_type`到第二个模板参数,使其使用不是那么繁琐.通过这种方式你不用每次都要输入`<foobar,int>`,诸如此类.
- 不再需要创建新的类来继承,只要简单的`typedef`就可以了.

注意,这只是一个简单的例子,用来说明 Mixin 的思路.它并没有考虑各种边角情况和有趣的用法.

作为旁注,你可能还会发现这篇文章很有帮助:[C++ Mixins - Reuse through inheritance is good... when done the right way](http://www.thinkbottomup.com.au/site/blog/C%20%20_Mixins_-_Reuse_through_inheritance_is_good)
