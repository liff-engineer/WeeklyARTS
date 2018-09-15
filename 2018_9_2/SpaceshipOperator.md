# [Spaceship操作符](https://blog.tartanllama.xyz/spaceship-operator/)

在C++中实现自定义类型时,有些情况需要为其实现关系操作,最多可能要实现6种关系操作：

- `==`
- `!=`
- `>`
- `<`
- `>=`
- `<=`

你需要理清楚这几种关系以及如何实现,还要提防不小心书写错误造成隐藏的BUG。

虽然现在C++实践中有一些方案可以缓解这种情况,都不甚理想,而这个就是C++20的`Spaceship Operator`所要解决的问题。

## 问题域抽象

这些关系操作会被分为两类:`equality`和`ordering`,`equality`用来表示相等/等价关系,`ordering`则用来定义顺序。

`equality`分为两种:`strong equality`、`weak equality`,这两种代表什么含义?

`strong equality`比较好理解,譬如矩形类,如果长宽都一致,那就是相等,一旦对象关系是`strong equality`,那么就是可替换的;那什么是`weak_equality`?如果为矩形定义比较操作,在这种场景下使用`strong equality`,那么就会出现问题,假设两个矩形`a`和`b`其长宽不相等,`( a==b ) || (a > b) || ( a < b)`在这种情况下将不能为`true`,这个就会让人无法理解,两个类型一致的对象既不相等,也不是大于或者小于关系。所以判断`a`和`b`是否`equality`就不能使用长宽都相等的条件了,我们可能会使用一些限定条件定义是否`equality`,而这种情况下的`equality`就是`weak equality`。

在`Spaceship Operator`中定义了五种关系表达结果:

![关系转换图](https://blog.tartanllama.xyz/assets/relation_conversion.png)

其中`strong_equality`和`weak_equality`表示`equality`,对应操作符`==`和`!=`,而`strong_ordering`、`weak_ordering`和`partial_ordering`则表示顺序关系,对应了`>`、`<`、`>=`和`<=`四种操作符,其中`strong`、`weak`的含义与`equality`中的一致,至于为什么还有`partial_ordering`,这是比`weak_ordering`还弱的关系,主要是给一些无顺序值的情况使用,譬如浮点数中的`Nan`。

## 如何使用

现在来看一下如何使用,譬如定义了一个结构体根据其`ID`内容进行排序,而且是`strong_ordering`关系,那么可以这样实现:

```C++
struct object_identify_by_id
{
    int id;

    std::strong_ordering operator<=>(object_identify_by_id const& other){
        return  id <=> other.id;
    }
}
```

从上述示例可以看到,如果用来排序的内容有`<=>`即`Spaceship Operator`的定义,可以简单地对其使用`<=>`,那么没有`<=>`的类型呢?

你可以使用`std::compare_3way`,如果类型没有`<=>`,`std::compare_3way`会转而使用类型定义的那六种关系操作,譬如对`pair`类型的关系操作:

```C++
template<class T, class U>
struct pair {
  T t;
  U u;

  auto operator<=> (pair const& rhs) const
    -> std::common_comparison_category_t<
         decltype(std::compare_3way(t, rhs.t)),
         decltype(std::compare_3way(u, rhs.u)> {
    if (auto cmp = std::compare_3way(t, rhs.t); cmp != 0) return cmp;
    return std::compare3_way(u, rhs.u);
  }
}
```

注意`common_comparison_category_t`会选择关系最弱的作为最终结果,譬如`std::common_comparison_category_t<std::strong_ordering, std::partial_ordering>`的结果是`std::partial_ordering`。

这种写法相对比较复杂,当然如果你针对对象的排序操作是按照成员变量顺序进行比较的,那么完全可以交给编译器给你生成默认的操作:

```C++
struct object_identify_by_id
{
    int id;

    auto operator<=>(object_identify_by_id const& other)=default;
}

template<class T, class U>
struct pair {
  T t;
  U u;

  auto operator<=> (pair const& rhs) const = default;
}
```

## 总结

可以看到,使用`Spaceship`操作符,可以简化掉非常多的关系操作代码,使得实现更为简洁。