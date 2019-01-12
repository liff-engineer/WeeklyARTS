# Weekly ARTS

- C++中派生类如何使用基类的构造函数
- 基于 Visual Studio 开发 Node.js C++ Addons 简介
- 我不建议你学 C++

## Algorithm [647. Palindromic Substrings](https://leetcode.com/problems/palindromic-substrings/)

题目要求给定字符串,返回子字符串是回文的个数.

```C++
int countSubstrings(string s) {
    int n = s.size();
    int result = 0;
    std::vector<std::vector<bool>> dp(n,std::vector<bool>(n,false));

    for(int i = n-1; i >= 0 ;i--){
        for(int j = i;j<n;j++){

            if(s.at(i) == s.at(j)){

                //如果是AXA形式
                if(j - i < 3){
                    dp[i][j]=true;
                }
                else if(dp[i+1][j-1]){//如果i+1,j-1的dp一样,这样就构成回文
                    dp[i][j]=true;
                }
            }

            if(dp[i][j]){
                result++;
            }
        }
    }
    return result;
}
```

## Review [使用基类的构造函数](using_base_constructor.md)

## Technique [基于 Visual Studio 开发 Node.js C++ Addons 简介](VSNodeAddonDevIntro.md)

## Share 我不建议你学 C++

虽然我现在手头上趁手的兵器就是 C++,但是我不建议学 C++.为什么?

C++的问题不在于太过复杂学不完,也不在于难度太高学不会,甚至说不在于传说的 C++语言没落了.

我认为 C++目前整个的发展有两个大问题:

1. 教育
2. 开发者

C++从 2011 年 C++11 开始发力,三年一个标准版本,C++14,C++17,在 2019 年将会发布 C++20.语言已经发生了相当多的变化,可是关于 C++语言的教育目前还是停留在 C++03?甚至 C++98 的时候.整个社区对新进入的开发者没有较好的协助.

当语言发生了如此大的改变,是否应该用“全新”的资料、方式等等来进行教育,帮助开发者掌握?而现状又是什么?

在 2018 年我开始深入了解 C++,拿到的大多数资料都是面向 C++开发者的,而不是初学者.前 C++开发者都因为各种原因“弃坑”了,新鲜血液补充起来太艰难,语言的发展和应用多么尴尬.

然后是开发者,据说很多程序员混"知乎",动不动"怎么评价 xxx".自己的学习理念和方法在哪里?学不会 C++,就完全是 C++的问题么,遇到点儿困难就克服不了,只能弃坑.那么不仅 C++不建议学,还有很多东西也不建议学.

开发者不应当视自己为码农,你可以创造一些东西,也可以将复杂、困难的事情简单化,你应当对自己提出更高的要求.

顺便说一句,选择合适的,人生苦短,我也用 Python.

## TODO

- [Editing files in your Linux Virtual Machine made a lot easier with Remote VSCode](https://medium.com/@prtdomingo/editing-files-in-your-linux-virtual-machine-made-a-lot-easier-with-remote-vscode-6bb98d0639a4)
- [CMake Presentation](http://purplekarrot.net/blog/cmake-introduction-and-best-practices.html)
