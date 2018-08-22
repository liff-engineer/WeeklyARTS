# [回溯法01](https://en.wikipedia.org/wiki/Backtracking)

回溯法是暴力搜索方法的一种,我目前对它适用场景的理解是：

根据一些输入,要查找到满足特定约束条件的结果,这个结果通常是输入条件的排列组合,穷举法在这种场景下会迅速变得太慢而不可用;应用回溯法通过一步步进入不同的分支组合来搜索满足约束条件的结果,并且在查找失败后返回到上一次查找的分支继续搜索。

这种算法可以用来解决迷宫问题:每一次都从固定的方向走,如果固定方向路不通,返回上一步走另外的分支,直到找到出口或者全部路径搜索完成。

来看一看Wiki上对于回溯法的通常解法伪代码：

```
procedure bt(c)
  if reject(P,c) then return
  if accept(P,c) then output(P,c)
  s ← first(P,c)
  while s ≠ Λ do
    bt(s)
    s ← next(P,s)
```

其中`P`为数据,`c`为结果,以及6个`procedural parameters`：

1. root(P):原始数据
2. reject(P,c):无法满足后续搜索条件,中断搜索
3. accept(P,c):结果满足约束条件
4. first(P,c):初始化结果
5. next(P,c):下一种情况
6. output(P,c):输出结果

下面来分析一些示例,看一看使用这种思路解决问题的套路。

## [784. Letter Case Permutation](https://leetcode.com/problems/letter-case-permutation/description/)

给定一个字符串`S`,可以将每个字母独立地切换成大写或者小写来构成新字符串,要求返回所有可能的字符串。

### 思路分析

新字符串每个字符位置有两种可能：原始字符,切换大小写后的字符;所求结果就是将这些字符不断二选一来进行排列组合,得到新字符串.

如果使用回溯法,这个问题是没有`reject`条件的,约束条件也很简单,就是新字符串每个字符位置要求是原字符的大小写形式.`first`就是从字符位置0开始,`next`根据字符情况可能有两个分支,`output`就是要记录到结果中。

### 伪代码映射

- bt
    ```C++
    void backtrack(std::vector<std::string>& results,const std::string& target, std::vector<char>& buffer,int index)
    ```
- accept
    ```C++
    if (index >= target.size()) { //完成当前字符串的组合
        results.push_back(std::string(buffer.begin(),buffer.end()));
        return;
    }
    ```
- first
    ```C++
    backtrack(results, S, buffer, 0);
    ```
- next
    ```C++
    int i = index;
    auto ch = target.at(i);
    if (ch >= '0' && ch <= '9') {//非字母仅有一个分支,直接进入
        backtrack(results, target, buffer, i + 1);
    }
    else //大小写两个分支,记录当前情况,进入下一次next
    {
        //小写
        buffer[i] = std::tolower(ch);
        backtrack(results, target, buffer, i + 1);
        //大写
        buffer[i] = std::toupper(ch);
        backtrack(results, target, buffer, i + 1);
    }
    ```

- output
    ```C++
    if (index >= target.size()) { //记录到结果中
        results.push_back(std::string(buffer.begin(),buffer.end()));
        return;
    }
    ```

### 关键点

回溯法的关键点有两个部分：

- 递归调用
- 存储当前情况进入递归调用后要切换成另外的情况再执行调用,这就是“回溯”的概念

### 完整实现

```C++
void backtrack(std::vector<std::string>& results,
    const std::string& target, std::vector<char>& buffer,int index)
{
    if (index >= target.size()) {
        results.push_back(std::string(buffer.begin(),buffer.end()));
        return;
    }
    int i = index;
    auto ch = target.at(i);
    if (ch >= '0' && ch <= '9') {
        backtrack(results, target, buffer, i + 1);
    }
    else
    {
        //小写
        buffer[i] = std::tolower(ch);
        backtrack(results, target, buffer, i + 1);
        //大写
        buffer[i] = std::toupper(ch);
        backtrack(results, target, buffer, i + 1);
    }
}
vector<string> letterCasePermutation(string S) {
    std::vector<std::string> results;
    std::vector<char> buffer(S.begin(), S.end());
    backtrack(results, S, buffer, 0);
    return results;
}
```

## [401. Binary Watch](https://leetcode.com/problems/binary-watch/description/)

有10个LED灯,前4个表示小时,后6个表示分钟,每个LED灯的两种状态表示该位是`0`或者`1`.当有`n`个LED灯亮时,能够表示出多少种时间?

### 思路分析

有`N`个LED灯亮,可以根据亮灯位置排列组合出非常多情况,首先问题是怎么排列组合出这`N`个灯亮的情况,沿用回溯法的思路,可以遍历10个LED灯,分别切换成亮或者不亮的情况进入下一次操作,这个相对来讲也简单：

- 接受条件:如果递归操作后,需要亮的灯为0,那么`N`个亮灯指派完成,就可以退出
- 拒绝条件:如果递归操作过程种,需要亮的灯数量已经大于剩余灯数,那么就不能继续递归操作了
- 下一个条件:将当前位置灯亮后,递增灯位置,进入递归操作

### 伪代码映射

- bt
    ```C++
    void backtrack(std::vector<std::string>& results,std::bitset<10>& result,int index,int remain)
    ``
- accept
    ```C++
    if (remain == 0) {//分配完成
    }
    ``  
- output
    ```C++
    auto v = result.to_ulong();
    int hour = v >> 6;
    int minute = v & 0b111111;
    if (hour < 12 && minute < 60)
    {
        std::string hour_string = std::to_string(hour);
        std::string minute_string = ((minute < 10) ? "0" : "") + std::to_string(minute);
        results.emplace_back(hour_string + ":" + minute_string);
    }
    return;
    ```
- reject
    ```C++
    if (remain > (10 - index)) return;//剩余灯不够亮的
    ```
- next
    ```C++
    for (int i = index; i < 10; i++) {
        result.set(i, true);
        backtrack(results,result, i + 1, remain - 1);
        result.set(i, false);
    }
    ```
- first
    ```C++
    std::vector<std::string> results;
    std::bitset<10> result;
    result.reset();
    backtrack(results, result, 0, num);
    ```

###  完整实现

```C++
void backtrack(std::vector<std::string>& results,std::bitset<10>& result,int index,int remain)
{
    if (remain == 0) {//分配完成
        
        auto v = result.to_ulong();
        int hour = v >> 6;
        int minute = v & 0b111111;
        if (hour < 12 && minute < 60)
        {
            std::string hour_string = std::to_string(hour);
            std::string minute_string = ((minute < 10) ? "0" : "") + std::to_string(minute);
            results.emplace_back(hour_string + ":" + minute_string);
        }
        return;
    }

    if (remain > (10 - index)) return;//剩余灯不够亮的

    for (int i = index; i < 10; i++) {
        result.set(i, true);
        backtrack(results,result, i + 1, remain - 1);
        result.set(i, false);
    }
}    
vector<string> readBinaryWatch(int num) {
    std::vector<std::string> results;
    std::bitset<10> result;
    result.reset();
    backtrack(results, result, 0, num);
    return results;
}
```

## 总结

回溯法有其清晰的实现思路,应用场景也比较好识别,能够用来解决大多数需要排列组合的问题。