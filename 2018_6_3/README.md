# Algorithm - Graph、DFS、BFS
完成了以下两个leetcode题目：
- [329.Longest Increasing Path in a Matrix](https://leetcode.com/problems/longest-increasing-path-in-a-matrix/description/)
- [515.Find Largest Value in Each Tree Row](https://leetcode.com/problems/find-largest-value-in-each-tree-row/description/)

其中**329**最初的思路是将其转换成graph,然后用类似最短路径的方法来计算最长路径,可惜最终结果是运行超时了,然后阅读了题目的**Discuss**部分,才得以解决,思路是原地DFS。
```C++
int dfs(std::vector<std::vector<int>>& matrix, int x, int y, int m, int n, std::vector<int>& results)
{
    static const std::vector<std::pair<int, int>> offsets{ { 0,1 },{ 0,-1 },{ 1,0 },{ -1,0 } };
    if (results[x*n+y] != 0) return  results[x*n + y];

    int result = 1;

    auto v = matrix[x][y];
    for (auto& offset : offsets) {
        auto i = x + offset.first;
        auto j = y + offset.second;
        if (i < 0 || j < 0 || i >= m || j >= n || matrix[i][j] >= v)
            continue;
        //从减小的方向查找
        result = std::max(result, dfs(matrix, i, j, m, n, results) + 1);
    }
    results[x*n + y] = result;
    return result;
}
int longestIncreasingPath(vector<vector<int>>& matrix) {
    if (matrix.empty()) return 0;
    auto m = matrix.size();
    auto n = matrix.front().size();
    for (auto& items : matrix) {
        n = std::min(n, items.size());
    }
    if (n == 0) return 0;
    std::vector<int> dist(m*n, 0);

    int result = 1;
    for (std::size_t i = 0; i < m; i++)
    {
        for (std::size_t j = 0; j < n; j++) {
            result = std::max(result, dfs(matrix,i, j, m, n, dist));
        }
    }
    return result;
}
```

通过解决题目**329**,学习了graph这种数据结构的概念及表示法,深度优先遍历/查找 - [Depth First Traversal(Or Search)](https://www.geeksforgeeks.org/depth-first-search-or-dfs-for-a-graph/),广度优先遍历/查找 - [Breadth Firsh Traversal(Or Search)](https://www.geeksforgeeks.org/breadth-first-search-or-bfs-for-a-graph/),受益颇深。

经过**329**之后解决**515**简直易如反掌,直接深度优先遍历搞定,提交时"击败了99%的解决方案",不服,然后看了“金字塔顶端”的解决方案-广度优先遍历,不得不服,还是要多琢磨。
```C++
void  bfs(TreeNode* node, std::size_t idx, std::vector<int>& result) {
    if (result.size() < idx + 1) {
        result.push_back(node->val);
    }
    else
    {
        result[idx] = std::max(result[idx], node->val);
    }

    if (node->left) {
        bfs(node->left, idx + 1, result);
    }

    if (node->right) {
        bfs(node->right, idx + 1, result);
    }
}
vector<int> largestValues(TreeNode* root) {
    std::vector<int> results;
    if (root != nullptr) {
        results.reserve(1024);
        bfs(root, 0, results);
    }
    return results;
}
```

# Review - 《std::embed - 编译期可用、可访问的程序外部资源》
[std::embed - Accessing program-external resources at compile-time and making them available to the developer](https://www.reddit.com/r/cpp/comments/8rrz07/stdembed_accessing_programexternal_resources_at/)

这事终于有人管了,作者“受到#include的启发”,希望以标准方式将外部文件嵌入到C++代码中,并且编译期可访问,如果该标准提案通过,C++将会有比较优雅的编译期资源管理标准解决方案,Qt的资源管理器等应用场景就会被大大削弱。

可以预想到的应用场景有：
- 应用程序的版本号、图标、版权声明等
- 材质、图标、Shader及脚本代码等
- 性能要求十分苛刻时的系数、数值常量等信息
- 嵌入式场景下的固件、数据等

基本上如果编译期不会变化的资源,均可以采用这种方式。

由于编译期可用且为**constexpr**,之后肯定有开发者会开发出各种编译期技术来操作这些数据,毕竟已经实现了编译期排序、Hash等方法。

有人也提出一些可实现以及安全性问题,作者已经基于clang做出了初步实现,并且在reddit上进行了回复。

3年又3年,拭目以待吧。

# Technique - CRTP的接口封装
在[Better Encapsulation for the Curiously Recurring Template Pattern](https://accu.org/index.php/journals/296)中,作者对**CRTP**中的封装技术进行了分析,提出了一种更好的封装思路,挺有借鉴意义。

对比如下OO技术
```C++
//库代码
class Base
{
  public:
    virtual ~Base();
    int foo() { return this->do_foo(); }

  protected:
    virtual int do_foo() = 0;
};
//用户代码
class Derived : public Base
{
  private:
    virtual int do_foo() { return 0; }
};
```
如果使用CRTP技术来实现：
```C++
//库代码
template<class DerivedT>
class Base
{
  public:
    DerivedT& derived() {
       return static_cast<DerivedT&>(*this); }
    int foo() {
       return this->derived().do_foo(); }
};
//用户代码
class Derived : public Base<Derived>
{
  public:
    int do_foo() { return 0; }
};
```
以上实现有个问题,``do_foo``被暴露出来了,导致用户代码可以访问它。

为了解决这个问题,作者利用继承的特性实现了如下辅助类:
```C++
struct accessor : DerivedT
{
    static int foo(DerivedT& derived)
    {
        int (DerivedT::*fn)() 
            = &accessor::do_foo;
        return (derived.*fn)();
    }
};
```
通过辅助类将私有成员函数暴露出来,然后提供给CRTP来调用私有成员函数,由此来避免私有成员函数暴露,而CRTP依然可访问。

完整代码如下:
```C++
//库代码
template<class DerivedT>
class Base
{
  private:
    struct accessor : DerivedT
    {
        static int foo(DerivedT& derived)
        {
            int (DerivedT::*fn)() 
               = &accessor::do_foo;
            return (derived.*fn)();
        }
    };
  public:
    DerivedT& derived() {
       return static_cast<DerivedT&>(*this); }
    int foo() { return accessor::foo(
       this->derived()); }
};
//用户代码
struct Derived : Base<Derived>
{
  protected:
    int do_foo() { return 1; }
};
```

# Share - in-place construction(C++如何追求极致性能)
C++中的“原地构造”技术及其应用,以及为什么建议使用``emplace_back``方法。

参考：
- [new expression](https://en.cppreference.com/w/cpp/language/new)
- [optional lite - A single-file header-only version of a C++17-like optional, a nullable object for C++98, C++11 and later](https://github.com/martinmoene/optional-lite)
- [Modern C++ features – in-place construction](https://arne-mertz.de/2016/02/modern-c-features-in-place-construction/)


# todo list

- [SQLite ORM light header only library for modern C++](https://github.com/fnc12/sqlite_orm)

看了示例挺有意思的,到底怎么实现的？

- [Revisiting Regular Types](https://abseil.io/blog/20180531-regular-types)

**Regular**,C++目前的 **concept**、 **range**等提案,蕴含了C++专家们很多深度的思考,还需要多读读。

- [Mathematics behind Comparison #1: Equality and Equivalence Relations](https://foonathan.net/blog/2018/06/20/equivalence-relations.html)

数学概念、**value** 和 **object**、等价种种之间的关联
