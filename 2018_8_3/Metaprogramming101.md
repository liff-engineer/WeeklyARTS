# C++模板元编程部分技术101

[Template metaprogramming](https://en.wikipedia.org/wiki/Template_metaprogramming)作为C++中的一种相对 **高阶** 的模板技术,可能很多人对模板有过一定了解,也读过相关书籍,但是真正写起来却不得要领,究其原因在于对整个概念和技术并不是非常清楚。

模板元编程的特征是编译期执行,并在编译期生成代码;模板本身是图灵完备的,也就是说常规编程使用到的常量、变量、循环语句、分支语句、函数等等均可以在模板中有对应的使用形式。

在 [C++ Templates - The Complete Guide, 2nd Edition](http://www.tmplbook.com/)的`Chapter 23 Metaprograming`中对元编程的各种技术进行了讲解,下面我们来通过示例具体分析以下各种技术。

## 模板元编程部分技术

常规编程技术与模板元编程技术对应关系:

- 状态变量:模板参数
- 循环:通过递归实现
- 执行路径选择:条件表达式或者特化
- 整数运算

### 状态变量

模板是针对类型、整数的操作,所需的状态变量也不外乎类型、整数等等,在常规代码里书写可能是这样的：

```C++
var_t var; //特定类型变量
int  var_int;//整数变量
bool var_b;//布尔变量
```

而在模板里该如何表示?

```C++
template<typename T>;
template<int  I>;
template<bool B>;
```

### 循环

在常规代码里,循环书写是这样的形式:

```C++
for(int i = 0 ;i < n ;i++){
    //循环条件
}
```

而在模板之中,需要采用递归的方式来实现循环:

```C++

//循环体
template<size_t N>
struct loop{
    using type = loop<N-1>::type;
};

//终止条件
template<>
struct loop<0>{
    using type = size_t;
};
```

### 执行路径选择

在常规代码里,可以有`if`、`else`等来书写执行路径选择,在模板里该如何实现?

```C++
//默认模板进入T分支
template<bool B,typename T,typename F>
struct if_then_else{
    using type = T;
};

//模板偏特化进入F分支
template<typename T,typename F>
struct if_then_else<false,T,F>{
    using type = F;
};
```

### 运算

针对布尔量的运算：

```C++
template<typename T>
struct condition1{
    constexpr static bool value = true;
};

template<typename T>
struct condition2{
    constexpr static bool value = false;
};

template<typename T,typename U>
struct condition {
    constexpr static bool value = condition1<T>::value || condition2<U>::value;
};
```

## `sqrt`实现分析

用二分法求平方根,如果用常规代码来实现：

```C++
int Sqrt(int N){
    int LO = 1;
    int HI = N;
    while(LO != HI){
        int mid = (LO+HI+1)/2;
        if(N < mid*mid){ //在(LO,mid)范围
            HI = mid-1;
        }
        else //在(mid,HI)范围
        {
            LO = mid;
        }
    }
    return LO;
}
```

可以看到其中利用了变量,循环,分支,运算等要素,那么如何将其转换成编译期实现呢?

首先声明变量:

```C++
template<int N,int LO,int HI>
struct Sqrt{
    constexpr static int mid;
};
```

然后初始化变量:

```C++
template<int N,int LO = 1,int HI = N>
struct Sqrt{
    constexpr static int mid = (L0+HI+1)/2;
};
```

之后实现循环:

```C++
//循环体
template<int N,int LO = 1,int HI = N>
struct Sqrt{
    constexpr static int mid = (L0+HI+1)/2;
    constexpr static auto value = //循环;
};

//终止条件
template<int N,int S>
struct Sqrt<N,S,S>{
    constexpr static auto value = S;//预期结果
}
```

之后是循环体和条件分支

```C++
template<int N,int LO =1,int HI = N>
struct Sqrt
{
    static constexpr auto mid = (L0+HI+1)/2;
    static constexpr auto value = std::conditional< (N<mid*mid),Sqrt<N,LO,mid-1>,Sqrt<N,mid,HI>>::value;
};
```

完整的代码示例如下：

```C++

template<int N,int LO =1,int HI = N>
struct Sqrt
{
    static constexpr auto mid = (L0+HI+1)/2;
    static constexpr auto value = std::conditional< (N<mid*mid),Sqrt<N,LO,mid-1>,Sqrt<N,mid,HI>>::value;
};

template<int N,int S>
struct Sqrt<N,S,S>{
    static constexpr auto value = S;
};

```

## 总结

通过对模板元编程中一些技术的介绍,可以看到模板元编程并没有那么神秘,对比常规编程的要素去学习对应的技术即可初步掌握模板元编程。