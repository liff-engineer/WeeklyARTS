# [回溯法02](https://en.wikipedia.org/wiki/Backtracking)

本周又完成了几个关于回溯法的题目,有了一些新的收获。

## [22. Generate Parentheses](https://leetcode.com/problems/generate-parentheses/description/)

题目要求给定n对括号,生成括号正确匹配的所有集合,按照回溯法的套路,实现思路如下：

- 实现判断括号正确匹配的方法
- 每次循环走两个分支,当前取`(`还是`)`
- 通过递归生成括号序列,生成完成时判定是否正确匹配并记录

实现如下：

```C++
//使用栈判断括号是否匹配
bool accept(const std::vector<bool>& result) {
    std::stack<bool> stack;
    for (auto v : result) {
        if (v) {
            stack.push(v);
            continue;
        }

        if (stack.empty()) return false;
        stack.pop();
    }
    return stack.empty();
}

//回溯法主体
bool backtrack(std::vector<std::string>& results,std::vector<bool>& result,int n,int idx,int remain) {
    if (remain <= 0) {
        if (accept(result)) {
            std::string r(n, ')');
            for (int i = 0; i < n; i++) {
                if (result.at(i)) {
                    r[i] = '(';
                }
            }
            results.push_back(r);
        }
        return true;
    }
    if ((n - idx) < remain) return false;
    if (idx >= n) return false;
    //使用(
    result[idx] = true;
    backtrack(results, result, n, idx + 1, remain - 1);
    //使用)
    result[idx] = false;
    backtrack(results, result, n, idx + 1, remain);
    return false;
}
vector<string> generateParenthesis(int n) {
    std::vector<std::string> results;
    std::vector<bool> result(n*2, false);
    backtrack(results, result, n * 2, 0, n);
    return results;
}
```

虽然执行结果是正确的,但是运行速度出在`4.5%`的级别,明显有更好的解决办法;

那么之前的实现方案有什么问题?

1. 使用栈判定括号匹配
2. 过程中的`std::vector<bool>`问题

实际上在构成括号序列的过程中,只要每一步保证`(`比`)`多,就是能够匹配的序列;而且过程中可以直接合成字符串结果。

效率在`100%`级别的实现方案如下:

```C++
void backtrack(std::vector<std::string>& results, std::string result, char next, int n,int left, int right)
{
    if (left > n || (left - right) < 0)//保证左括号比右括号多
        return;

    result += next;
    if (right == n) {
        results.push_back(result);
        return;
    }
    backtrack(results, result, '(', n, left + 1, right);
    backtrack(results, result, ')', n, left, right + 1);
}


vector<string> generateParenthesis(int n) {
    std::vector<std::string> results;
    std::string result;
    backtrack(results, result, '(', n, 1, 0);
    return results;
}
```

## [216. Combination Sum III](https://leetcode.com/problems/combination-sum-iii/description/)

题目要求给定n,从1到9中挑选出k个数,这些数之和为n,要求拿到所有的集合.

这个就是非常简单直观的回溯法套路题目:遍历1到9,根据选不选当前数,走不同的分支,过程中使用求和的逆运算,当剩余为0时就是所求序列。

```C++
void backtrack(std::vector<std::vector<int>>& results, std::vector<int>& result,
    int n,int k,int next)
{
    if (n == 0 && k == 0) {//剩余个数为零,所余值为0
        results.push_back(result);
        return;
    }

    if (n <= 0 || k <= 0 || next > 9)
        return;

    result.push_back(next);
    backtrack(results, result, n - next, k - 1, next + 1);//使用当前值
    result.pop_back();
    backtrack(results, result, n, k, next + 1);//不使用当前值
}

vector<vector<int>> combinationSum3(int k, int n) {
    std::vector<std::vector<int>> results;
    std::vector<int> result;
    backtrack(results, result, n, k, 1);
    return results;
}
```

## [357. Count Numbers with Unique Digits](https://leetcode.com/problems/count-numbers-with-unique-digits/description/)

题目是这样的,给定非负数n,在0到10的n次方这些数中,求出所有数字不重复的整数数量,譬如`11`有两个1,就是重复的。

这个题目比较奇葩,题目的喜欢和不喜欢对比为169:416,原因可能在于这不是个回溯法题目,是找规律运算出来的。

假设n为0,那么只有0;n为1时,有9种情况(排除掉0);n为2时,十位取1到9,个位可以取10-1个,因为十位用了一个数字;也就是说n位数的非重复数个数为9*(10-1)*(10-2)*...。

实现如下：

```C++
int countNumbersWithUniqueDigits(int n) {
    //1-> 10
    //2-> 9*9 = 81
    //3-> 9*9*8 = 648
    //n-> 9*9*8*7*6*5*4*3*2*1
    //n <= 10
    std::vector<int> results{
        1, //0-> 0种
        9,//1-> 10种
        9 * 9,//2-> 首位9种*9种
        9 * 9 * 8,//3-> 9*9*8
        9 * 9 * 8 * 7,//4
        9 * 9 * 8 * 7 * 6,
        9 * 9 * 8 * 7 * 6 * 5,
        9 * 9 * 8 * 7 * 6 * 5 * 4,
        9 * 9 * 8 * 7 * 6 * 5 * 4 * 3,
        9 * 9 * 8 * 7 * 6 * 5 * 4 * 3 * 2,
        9 * 9 * 8 * 7 * 6 * 5 * 4 * 3 * 2 * 1
    };

    int result = 0;
    for (int i = 0; (i <= n) &&(i < results.size()); i++) {
        result += results[i];
    }
    return result;
}
```

## 总结

回溯法只是解决问题的思路,虽然套路可以重复用,但是也要根据应用场景做出调整,否则的话效率还是不高;有一些问题需要找出更有效的规律,而不是单纯套用算法。