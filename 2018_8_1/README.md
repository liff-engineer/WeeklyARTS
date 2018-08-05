# Weekly ARTS

## Algorithm

## Reivew [Code Quality – Cyclomatic Complexity](https://blog.feabhas.com/2018/07/code-quality-cyclomatic-complexity/)

## Technique [Elementary string conversions](P0067R5.md)

在C++17中 [P0067R5 Elementary string conversions](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2016/p0067r5.html)提供了标准化的整数、浮点数与字符串之间转换的方法,能够满足如下要求:

- no runtime parsing of format strings
- no dynamic memory allcoation inherently required by the interface
- 不考虑locale
- 不需要通过函数指针等方式
- 防止缓冲区溢出
- 当解析字符串时,如果无效可以得到错误信息
- 当解析字符串时,空格等不会被默认忽略

最重要的是有性能上的保证。

## Share [尽信书不如无书](AboutEffectiveCppItem36.md)
