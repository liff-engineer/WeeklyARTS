# Weekly ARTS

## Algorithm [797. All Paths From Source to Target](https://leetcode.com/problems/all-paths-from-source-to-target/)

题目要求,给定有向、无环,包含`N`节点的图,找出所有能够从节点`0`到节点`N-1`的路径,可以以任意顺序返回这个结果.

图表达形式如下:

- 节点是 0、1、...、graph.length-1
- graph[i]列出了`i`连接到的节点`j`,即`edge(i,j)`存在.

刚开始做`leetcode`上的题目,就碰见了图相关的问题,从头学起图的表示,`DFS`以及`BFS`.之后就卡到动态规划算法上了...... 这次只好重新捡起来,又熟悉了下.

题目说图是无环的,这里采用深度优先遍历`DFS`方法,过程中记录结果,实现如下:

```C++
void dfs(vector<vector<int>> &graph, std::size_t idx, vector<vector<int>> &results, vector<int> path)
{
    path.push_back(idx);
    if (graph.size() == idx + 1)
    {
        results.push_back(path);
        return;
    }
    for (auto node : graph.at(idx))
    {
        dfs(graph, node, results, path);
    }
}
vector<vector<int>> allPathsSourceTarget(vector<vector<int>>& graph) {
    vector<vector<int>> results;
    std::vector<int> path;
    dfs(graph, 0, results, path);
    return results;
}
```

但是提交之后,运行速度和内存占用都不太满意,这里尝试利用一下`path`这个过程数据,不再每次复制,而是重用:

```C++
void dfs(vector<vector<int>> &graph, std::size_t idx, vector<vector<int>> &results, vector<int>& path)
{
    path.push_back(idx);
    if (graph.size() == idx + 1)
    {
        results.push_back(path);
    }
    for (auto node : graph.at(idx))
    {
        dfs(graph, node, results, path);
    }
    path.pop_back();
}
vector<vector<int>> allPathsSourceTarget(vector<vector<int>>& graph) {
    vector<vector<int>> results;
    std::vector<int> path;
    path.reserve(graph.size());
    dfs(graph, 0, results, path);
    return results;
}
```

经过上述操作调整,目前算是最快的实现了.

[Recursive descent parser](https://en.wikipedia.org/wiki/Recursive_descent_parser)

## Review

[TRANSLATOR PATTERN](http://www.iro.umontreal.ca/~keller/Layla/translator.pdf)

## Technique

[What's the practical difference between std::nth_element and std::sort?](https://stackoverflow.com/questions/10352442/whats-the-practical-difference-between-stdnth-element-and-stdsort)

[How I discovered the C++ algorithm library and learned not to reinvent the wheel](https://medium.freecodecamp.org/how-i-discovered-the-c-algorithm-library-and-learned-not-to-reinvent-the-wheel-2398a34e23e3)

## Share Work Hard 还是 Work Smart

## TODO

- [The space of design choices for std::function](https://quuxplusone.github.io/blog/2019/03/27/design-space-for-std-function/)
- [10 Code Smells a Static Analyser Can Locate in a Codebase](https://www.fluentcpp.com/2019/03/26/10-code-smells-a-static-analyser-can-locate-in-a-codebase/)

- [Alexander A. Stepanov](http://stepanovpapers.com)
