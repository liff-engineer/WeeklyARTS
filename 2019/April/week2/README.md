# Weekly ARTS

- C++排序算法
- 10 种静态分析可以识别的代码味道
- Work Hard 还是 Work Smart

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

## Review [10 种静态分析可以识别的代码味道](code_smells.md)

[TRANSLATOR PATTERN](http://www.iro.umontreal.ca/~keller/Layla/translator.pdf)

## Technique [C++排序算法](cpp_sort.md)

[What's the practical difference between std::nth_element and std::sort?](https://stackoverflow.com/questions/10352442/whats-the-practical-difference-between-stdnth-element-and-stdsort)

[How I discovered the C++ algorithm library and learned not to reinvent the wheel](https://medium.freecodecamp.org/how-i-discovered-the-c-algorithm-library-and-learned-not-to-reinvent-the-wheel-2398a34e23e3)

## Share Work Hard 还是 Work Smart

最近关于`996`的讨论很多,虽然我所在的公司部门并没有这种要求,但是现实情况是部门有部分员工由于各种原因,日常基本上`996`,将部门平均上班时间拉到 11 小时以上.

这里我无意探讨`996`的对与错,只是从开发者角度来探讨,如何摆脱"主动`996`"这种困境.

时间紧、任务重、事情多,基本上项目都会遇到,如果碰到水平较高的管理者,还不至于那么辛苦,但是当管理者没有更好的手段,加班就不可避免了.

我也能理解这部分管理者的无奈,任务那么多,手下上班时间做不完,怎么办,怎么能让手下上班时间就做完? 他们的首选方案肯定是提升团队人员能力,提高工作效率.但是现实情况是,所谓的人员能力和工作效率,很大程度依赖于具体的人,而不是说你可以通过管理手段来改善.

于是,团队就出现了`Work Hard`的情况,努力干,付出不亚于任何人的努力.当你偶尔回想其这样的工作历程,会不会发现自己和搬砖"工人"相差无几.

都说编程是智力活动,而我们却将其变成了体力劳动,比谁更能加班更能熬......

能不能`Work Smart`,探索更好的方式方法,通过技术提高生产力?

在我们`Work Hard`的过程中,能不能抽出时间思考思考,工作`Hard`在哪里,困境是什么,是真的只能这样?还是说可以有所改变,来跳出这个循环?

举个简单的例子,公司针对 UI 有相应的规范,会对产品实现进行检查,他们为了降低成本,基于 Qt 的 Designer 开发了支持 UI 规范的版本,让产品组使用这个工具来设计 UI. 在我看来,这只是个`Work Hard`的例子,开发者在使用这个工具时,需要同步维护 UI 文件和代码,在很多自定义 UI 的场景下又无法使用工具.

而回到问题的最初,你追求的是产品组在实现 UI 时遵循 UI 规范,那么你要解决的问题应当是让开发者按照规范来做.那你提供符合 UI 规范的组件,以及文档,甚至说开发检查工具才是`Work Smart`的方法,让别人知道规范是什么,这样才有可能遵循你的规范.

提供 UI 设计工具,那么开发者永远不清楚你的规范是什么,依然会有不遵守规范的情况.

## TODO

- [The space of design choices for std::function](https://quuxplusone.github.io/blog/2019/03/27/design-space-for-std-function/)
- [10 Code Smells a Static Analyser Can Locate in a Codebase](https://www.fluentcpp.com/2019/03/26/10-code-smells-a-static-analyser-can-locate-in-a-codebase/)

- [Alexander A. Stepanov](http://stepanovpapers.com)
