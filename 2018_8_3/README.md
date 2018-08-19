# Weekly ARTS

- 这周学习了用回溯法解决N皇后问题;
- 对模板元编程的一些技术进行了总结;
- 使用模板技术实现了一种组合式写法,体会到了模板的魅力所在;
- 柯P

## Algorithm [N皇后问题](https://leetcode.com/problems/n-queens/description/)

遇到题目要用回溯法,搜索了一下最典型的就是N皇后问题,于是就先来根据自己对回溯法有限的理解来解决一下N皇后问题:

1. 首先是实现判断在放置第row行col列时能否满足要求条件的函数

    ```C++
    bool accept(std::vector<int> result, int n, int row, int col) {
        //是否存在一列的
        if (std::find(result.begin(), result.end(), col) != result.end())
            return false;
        //是否存在同一斜线的
        for (int i = 0; i < n; i++) {
            if (i == col)
                continue;
            //列左移或者右移,同步移动行
            auto j = row - std::abs(col - i);
            if (j < 0)
                continue;
            if (result.at(j) == i)
                return false;
        }
        return true;
    }
    ```

2. 然后是针对第1行第i列已经放置好这种初始化条件查找其N皇后解法(递归)

    ```C++
    void backtrack(std::vector<std::vector<std::string>>& results, std::vector<int> result, int n, int nrow = 0) {
        auto size = result.size();
        if (size != nrow) return;//上一行没有找到合适的列
        if (size == n) {//记录这次查找到的正确结果
            std::vector<std::string> items;
            for (int i = 0; i < n; i++) {
                std::string row(n,'.');
                row.at(result.at(i)) = 'Q';
                items.emplace_back(std::move(row));
            }
            results.emplace_back(std::move(items));
            return;
        }
        else
        {
            int row = result.size();
            for (int i = 0; i < n; i++) {
                if (accept(result, n, row, i)) {
                    auto tmp = result;
                    tmp.push_back(i);
                    //result.push_back(i);
                    backtrack(results, tmp, n, row + 1);
                }
            }
        }
    }
    ```

3. 遍历列数提供不同的初始化列来查找N皇后解法

    ```C++
    vector<vector<string>> solveNQueens(int n) {
        std::vector<std::vector<std::string>> results;
        for (int i = 0; i < n; i++) {
            std::vector<int> result;
            result.push_back(i);
            backtrack(results, result, n, 1);
        }
        return results;
    }
    ```

确实解决了问题,但是运行结果只击败了9.9%的C++解决方案,大概翻阅了速度比较快的C++实现,发现自己对于之前使用的DFS等还不是很熟练,只能用比较直观的解决办法来处理.这一部分还是要多多练习。

## Reivew [模板元编程部分技术101](Metaprogramming101.md)

针对《C++ Templates - The Complete Guide, 2nd Edition》的`Chapter 23 Metaprograming`对模板元编程技术进行了讲解,在这里总结出部分技术及其使用方式。

## Technique [一种“渲染”功能的组合式写法](RenderImpl.md)

通过模板技术,仅仅为基本类型提供“渲染”方法,对于基本类型组合出的其它类型免去提供“渲染”方法的烦恼。

## Share 感受到了"民主自由"的气息

偶然的机会看了[《一日系列第六十九集》最強主管～市長柯P來了！邰哥來挑戰史上最崩潰工作！-一日市長幕僚feat.柯文哲](https://www.youtube.com/watch?v=Qkf4farak1k),然后对柯P有了很多兴趣,相信很多人看过柯P那个拍桌子的表情包,但你了解么,柯P作为一个“无党派”人士能够被台北市民选为台北市长,而且根据我目前的了解有非常大的机会连任,这在大天朝简直不敢想象。

虽然台湾搞民主感觉乱七八糟,至少从他们能够选出柯P作为台北市长,可以感受到民主的魅力,而你在youtube上去看一下一些台湾的youtuber的言论,譬如说[馆长](https://www.youtube.com/user/kos44444),言论自由的气息.

建议大家去看一看,了解一下,感受一下。