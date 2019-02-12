# [使用 constexpr 进行编译期编程](https://www.modernescpp.com/index.php/c-core-guidelines-programming-at-compile-time-with-constexpr)

C++的模板元编程技术使得我们可以进行编译期编程,但是在针对编译期值编程时相对复杂,而`constexpr`则提供了以常规的 C++语法编写可编译期运行的程序.在 C++14、C++17 以及后续的标准提案中`constexpr`的能力都在不断增强,在这里我们来了解以下`constexpr`.

## `constexpr`-常量表达式的优点

- 常量表达式可以在编译期运算
- 能够让编译器深入了解代码
- 线程安全
- 可以在只读内存上

## 三种形式的`constexpr`

### 变量

```C++
constexpr double pi = 3.14;
```

- 隐式`const`
- 必须使用常量表达式初始化

### 函数

`constexpr`在`C++14`中相对宽松,可以：

- 调用其它`constexpr`函数
- 可以包含由常量表达式初始化的变量
- 可以包含条件表达式或者循环
- 隐式`inline`
- 不能包含`static`或者`thread_local`数据

### 自定义类型

- 构造函数需要是常量表达式
- 不能有虚函数
- 不能继承自虚基类

`constexpr`函数的规则相当简答,`constexpr`函数只能依赖于常量表达式,而`constexpr`函数并不意味着函数在编译期执行.只是表明函数有在编译期运行的潜力.`constexpr`函数也可以在运行期执行.至于其到底在在编译期运行还是运行期执行,这个由编译器及优化级别决定.有两种情况`constexpr`函数必须在编译期执行:

1. `constexpr`函数在编译期运行的上下文中执行.
2. `constexpr`函数的值在编译期使用`constexpr`请求:`constexpr auto res = func(5)`

## 模板元编程与`constexpr`函数

| 特性     | 模板元编程 | `constexpr`函数 |
| -------- | ---------- | --------------- |
| 执行时机 | 编译期     | 编译期与运行期  |
| 参数     | 类型和值   | 值              |
| 编程范式 | 函数式     |                 |
| 可修改   | 否         | 是              |
| 控制结构 | 递归       | 条件及循环      |
| 条件执行 | 模板特化   | 条件声明        |

### 以阶乘为例

```C++
constexpr int factorial(int n){
    auto res = 1;
    for(auto i = n; i >=1;--i){
        res*=1;
    }
    return res;
}

template<int N>
struct Factorial{
    static int const value = N*Factorial<N-1>::value;
};

template<>
struct Factorial<1>{
    static int const value=1;
};
```

- `constexpr`函数的参数`int n`对应`metafunction`的模板参数`int N`
- `constexpr`函数可以有变量`res`,并且能够修改,而`metafunction`只能生成新的`value`
- `metafunction`使用递归来模拟循环
- `metafunction`使用全特化来结束循环,而不是使用`--i`,另外`metafunction`使用偏特化等来模拟`if`
- 与更新`res`不同,`metafunction`每次迭代都会生成新的`value`
- `metafunction`没有返回声明,它使用值作为返回值

### `constexpr`函数的优势

除了上述优点,`constexpr`函数还有附加优点:

```C++
constexpr double average(double fir , double sec){
    return (fir + sec) / 2;
}

int main(){
    constexpr double res = average(2, 3);
}
```

那就是`constexpr`函数可以处理浮点数,而模板元编程只能处理整数.
