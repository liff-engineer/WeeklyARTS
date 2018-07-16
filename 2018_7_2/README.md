# Algorithm [773. Sliding Puzzle](https://leetcode.com/problems/sliding-puzzle/description/)

## 问题描述

在2X3的棋盘上,随机放置着1~5共5个棋子,空的位置以0表示,仅允许棋子与空位置进行户换,也就是说0可以在四个方向上与对应的数值互换,如果最终能够成为[[1,2,3],[4,5,0]]这种状态,则棋局可解,否则棋局不可解;

问最少需要几步可以解决这个棋局,不可解时返回-1.

## 解决思路

这个问题可以类比图这种数据结构来描述,因为只有0可以与4个方向上的位置互换,以当前所有棋子状态为节点,其最多能够连接到4个节点,也就是说棋盘初始状态能够呈现出的所有状态可以以节点相连这种形式表达,列出的所有状态就是状态转换图,然后这个问题可以转换成最短路径问题-BFS广度优先查找。

- 将棋盘状态以字符串形式表示
- 从棋盘起始状态进行广度优先查找,一直找到目标状态或者遍历完所有状态

## 解决方案

```C++
int slidingPuzzle(vector<vector<int>>& board) {
    std::string origin(6,'0');
    for (std::size_t i = 0; i < board.size(); i++) {
        for (std::size_t j = 0; j < board.at(i).size(); j++) {
            origin[i * 3 + j] = board[i][j]+'0';
        }
    }

    std::string target("123450");
    std::set<std::string> visited;
    visited.insert(origin); 

    std::array<int, 4> offsets{ 1,-1,3,-3 };
    std::vector<std::string> ranges;
    ranges.push_back(origin);
    int result = 0;
    while (!ranges.empty()) {
        std::vector<std::string> nexts;
        for (auto item : ranges) {
            if (item == target) return result;

            for (int i = 0; i < 6; i++) {
                if (item[i] != '0')
                    continue;

                for (auto offset : offsets)
                {
                    int j = i + offset;
                    if (j < 0 || j > 5) continue;
                    if (i == 2 && j == 3) continue;
                    if (i == 3 && j == 2) continue;

                    auto tmp = item;
                    std::swap(tmp[i], tmp[j]);
                    if (visited.find(tmp) != visited.end())
                        continue;
                    nexts.push_back(tmp);
                    visited.insert(tmp);
                }
                break;
            }
        }
        ranges = std::move(nexts);
        result++;
    }
    return -1;
}
```

## 后记

这个问题困扰了不少时间,刚开始想着穷举出所有状态,但是这种方法不能找到最少需要多少步;后来看了`Discuss`标题,也没有意识到字符串表示和BFS意味着什么,直到阅读了别人的解决方案,才明白其中缘由.

那么些经典的数据结构,肯定是对各种问题域的抽象,在解决问题时,需要更多地思考,提炼,从中找出对应的数据结构,这样就能把“未知”问题转换为已知问题,从而得到解决。

# Review [Delegate this! Designing with delegates in modern C++](Delegatethis.md)

最近CppCon即将召开,ISOCpp站点推送了一些去年的演讲,看到这个C++中的`delegate`就按图索骥全阅读了一遍,了解了其来龙去脉,同时也搞清楚了之前的`function_ref`标准提案的目的。

C++语言的一大设计哲学是避免`overhead`,不要为你不使用的付出成本,使用时只付出必要的成本,但是一切并不是那么美好,虽然`std::function`有一些问题,目前还是没好的方案来解决。

# Technique [一些lambda的“高级”用法](LambdaHackery.md)

递归lambda和重载lambda,尤其在使用`std::variant`时非常有价值。

# Share 不要拒绝沟通

最近在忙装修的前期准备,完全门外汉,对这些都一头雾水,周末和装修过的朋友聊了聊,发现自己对一些事情的看法存在严重的问题：
装修公司的骚扰电话要不要接?要不要找装修公司?

之前因为买完房子个人信息泄漏,每天接到无数骚扰电话,对装修公司产生了极大的反感,也听说这个行业非常混乱,所以就坚决拒绝装修公司。等开始装修时发现自己对这个行业了解太少,无从下手,想找人咨询下,并不是有多少人有那闲情逸致,朋友说“专业的事情交给专业的人去做”、“跟装修公司聊聊需求,让他们给出方案,大不了不用就是”、“装修公司不会嫌麻烦不愿意给你这小白用户讲事情”等等等等。

琢磨了一下,确实是这样,不要拒绝沟通,哪怕你并不信任对方的专业水准,你依然可以学到很多东西,否则的话自己在那儿硬杠,浪费了宝贵的时间和精力。