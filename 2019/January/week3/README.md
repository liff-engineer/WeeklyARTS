# Weekly ARTS

- C++17 新特性之使用`auto`声明免类型模板参数
- Boost.MultiIndex 部分特性的 C++17 实现
- 语言对软件设计的影响

## Algorithm [120. Triangle](https://leetcode.com/problems/triangle/)

题目要求给定一个三角形,找出从顶到底和最小的路径,每次只能移动到下一行的相邻数字.

这里可以采用从底到顶的方法,计算出每一层到目标位置的最小路径和.其中的子问题关系如下:

```C++
dp[i][j]=triangle[i][j]+std::min(dp[i+1][j],dp[i+1][j+1])
```

直接将`dp`合并到`triangle`上,子问题结果为:

```C++
triangle[i][j]+=std::min(triangle[i+1][j],triangle[i+1][j+1])
```

实现如下:

```C++
int minimumTotal(vector<vector<int>>& triangle) {
    auto n = triangle.size();
    for (int i = n - 1; i > 0; i--)
    {
        for (auto j = 0; j < triangle[i].size() - 1; j++)
        {
            triangle[i - 1][j] += std::min(triangle[i][j], triangle[i][j + 1]);
        }
    }
    return triangle[0][0];
}
```

## Review [使用`auto`声明免类型模板参数](P0127R2.md)

## Technique [Boost.MultiIndex 部分特性的 C++17 实现](MultiIndex.md)

## Share 语言对软件设计的影响

2018 年做了个专题:现代 C++对开发带来的改变.之前目的就是探索现代 C++对于软件设计及实现带来的影响.过程中也对软件设计有了很多想法.

譬如可测试性设计,借用 C++类型系统及模板,能够完全将 UI 与业务逻辑剥离,针对 UI 和业务逻辑使用模板"胶水"粘合成具体操作.以编译期配置的方式构造业务流程实现.

亦或者可扩展设计,在向对象增加新类型的属性时,完全不需要新增接口,直接使用模板接口读写对应属性.

再比如 ORMaping,访问数据库之前要手动实现结构体与数据库记录之间的转换,别的语言通过 ORM 库来实现,而在 C++中完全可以实现编译期的 ORM,针对自己实现的数据库也没有问题.

之前写代码追求可复用,实际上最好的可复用方式是能够在原始接口类上直接新增方法,这样才算更好的可复用方式,譬如修饰器模式就是这种方法,而在 C++中可以通过代理模式和修饰器模式(Mixin 技术)实现可拼接的 API.

可以看到,利用语言的一些特性,能够使软件设计更好的落地,而不是设计很美好,实现乱七八糟.

但是细细想来,如果用 OO 的那种思路,那种方式,也能实现对吧? 所以,钻研语言对成为架构师有帮助么?
