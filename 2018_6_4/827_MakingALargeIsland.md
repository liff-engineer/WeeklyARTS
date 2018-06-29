# [827. Making A Large Island](https://leetcode.com/problems/making-a-large-island/description/)

>In a 2D grid of 0s and 1s, we change at most one 0 to a 1.
>
>After, what is the size of the largest island? (An island is a 4-directionally connected group of 1s).

题目大意为：有个2D网格,格子里要么是0要么是1,1代表陆地,0代表海,陆地连接起来形成岛,如果只能将一个海格子填成陆地,那么这个2D网格里最大的岛包含多少块儿陆地?

## 对问题的思考
如果不填海,那么这个2D网格最大的岛包含多少块儿陆地?通过使用DFS/DFT(广度优先遍历),将相连的陆地染色,即可得出2D网格有多少个岛,每个岛有多少块陆地。

那么填了块海会有什么结果？
- 这块海周围没有任何陆地,之前最大的岛就是所要的结果
- 这块海周围有一块陆地,这块陆地所属的岛大小加1,然后比较所有岛大小,得出最大值即为最大岛
- 这块海填充成为陆地后连接了周围的陆地,那么周围的陆地加上这块海形成了一个新的岛

总结上述结果,可以得出填海后影响到的岛大小变化：周围所有陆地所属岛(去重)大小之和加上这块海即为新的岛大小。

## 解决思路
1. DFS对2D网格进行染色,并记录下特定颜色的岛大小
2. 遍历所有是海的格子,计算出该格子填充成陆地后形成的岛大小
3. 对步骤1和2中岛大小取最大值

## 实现
```C++
int dfs_for_colorful(std::vector<std::vector<int>>& grid, int x, int y, int m, int n, int color,std::vector<std::vector<int>>& map) {
    static const std::vector<std::pair<int, int>> offsets{ { 1,0 },{ -1,0 },{ 0,1 },{ 0,-1 }};
    map[x][y] = color;

    int result = 1;
    for (auto& offset : offsets) {
        auto i = x + offset.first;
        auto j = y + offset.second;
        if (i < 0 || j < 0 || i >= m || j >= n || map[i][j] != 0 || grid[i][j] != grid[x][y])
            continue;
        result += dfs_for_colorful(grid, i, j, m, n, color,map);
    }
    return result;
}

int search_for_largest_island(std::vector<std::vector<int>>& map, int x, int y, int m, int n, std::map<int, int>& colors) {
    static const std::vector<std::pair<int, int>> offsets{ { 1,0 },{ -1,0 },{ 0,1 },{ 0,-1 }};

    std::set<int> results;//记录相邻的岛索引,不重复,重复只能加1
    for (auto& offset : offsets) {
        auto i = x + offset.first;
        auto j = y + offset.second;
        if (i < 0 || j < 0 || i >= m || j >= n || map[i][j] == 0)
            continue;
        //跳过周围为0的,因为有值的才是岛边界
        results.insert(map[i][j]);
    }

    //只要能连起来,统统相加即可!,因为对角线不算了,
    int result = 1;
    for (auto key : results) {
        result += colors[key];
    }
    return result;
}
int largestIsland(vector<vector<int>>& grid) {
    if (grid.empty()) return 0;
    auto m = grid.size();
    auto n = grid.front().size();
    for (auto& items : grid) {
        n = std::min(n, items.size());
    }
    if (n == 0) return 0;

    std::map<int, int> colors;
    std::vector<std::vector<int>> map(m, std::vector<int>(n, 0));
    //第一遍,着色！,把每个岛设置值索引
    int color = 1;//刚开始的颜色为1,递增
    for (std::size_t i = 0; i < m; i++) {
        for (std::size_t j = 0; j < n; j++) {
            //如果map值不等于0,则访问过了，如果grid上值为0,则不需要访问,因为形成不了岛
            if (map[i][j] != 0 || grid[i][j] == 0)
                continue;
            colors[color] = dfs_for_colorful(grid, i, j, m, n, color, map);
            color++;
        }
    }
    int result = 0;
    for (auto& kv : colors) {
        result = std::max(result, kv.second);
    }

    //第二遍,翻转查找,计算出相邻（岛值合并）最大值！
    for (std::size_t i = 0; i < m; i++) {
        for (std::size_t j = 0; j < n; j++) {
            if (map[i][j] != 0)//只访问海(非岛的地块儿)
                continue;
            result = std::max(result, search_for_largest_island(map, i, j, m, n, colors));
        }
    }
    return result;
}
```
## 学到的内容
- 图可以用来处理节点连接的情况
- 在进行关联内容的分类时可以考虑使用图+DFS的处理方法
- 最终耗时12ms,应该是C++的Solution中效率很高的了,算法真是挺有意思的