# Weekly ARTS

- `简洁`数据结构
- cmake 部署小提示
- 不要"考验"开发者

## Algorithm [868. Binary Gap](https://leetcode.com/problems/binary-gap/)

随机个题目休闲一下,题目要求给定整数,求出其二进制表示中两个`1`之间最远间隔,其中`0b11`间隔为`1`,如果找不到则返回`0`.

### 第一种解法

通过不断除以`2`,可以理解为右移,取得的余数就是二进制的值,当为`1`时开始重新计数,并记录过程中的最大值:

```C++
int binaryGap(int N)
{
    int  last = 0;
    int  current = 0;
    bool flag = false;
    while (N > 0)
    {
        if (N % 2 != 0)
        {
            if (flag)
            {
                last = std::max(last, current);
            }
            flag = true;
            current = 1;
        }
        else if(flag)
        {
            current++;
        }
        N /= 2;
    }
    return last;
}
```

可以看到这种解法上,写法还是需要注意的,需要三个变量,`last`存储结果,`current`进行间隔计数,`flag`用来控制是否计数. 条件判断需要比较小心,可以使用`std::bitset`来改进.

### 采用`std::bitset`的写法

采用`std::bitset`则可以使用普通循环,而无需使用`while`,由于可以追溯,用于计数的变量也不需要了:

```C++
int binaryGap(int N)
{
    std::bitset<32> v = N;
    int  result = 0;
    auto last = 0ul;
    for (auto i = 0ul; i < v.size(); i++)
    {
        if (!v[i])
            continue;
        if (v[last]) {
            result = std::max(result, static_cast<int>(i - last));
        }
        last = i;
    }
    return result;
}
```

`std::bitset`的优势在于可以将其直接作为二进制数组进行操作,写法上会简单清晰许多.

## Review [`简洁`数据结构](simple-data-structures.md)

## Technique [cmake 部署小提示](cmake-deploy-tips.md)

## Share 不要"考验"开发者

项目目前在将`Visual Studio`的工程文件转换为`Modern CMake`,处理Qt的`moc`时发现个很奇怪的问题,同一个头文件,生成的`moc`文件是一份,而在最终的`mocs_compilation.cpp`中该文件被包含了两次......

一直无法通过编译,尝试了各种办法,确定的结论是源代码没有问题.但是查看`CMakeLists.txt`也没发现存在问题.我甚至翻阅了`CMake`关于生成`mocs_compilation.cpp`文件的源代码来确定是否有机制可以查阅文件包含依据是什么.最终回过头来继续查源代码的问题,直到删掉其他所有文件,只剩下出问题的头文件和源文件,问题依然存在!

而最终发现问题原因在于头文件和源文件文件名有个字母不一样,原本应该为`I`,被写成了`i`.我不知道Qt的`moc`机制究竟为何,从现象看,源文件和头文件都会触发`moc`,从而生成两个`moc`文件,由于Windows的文件夹系统大小写不敏感,导致最终只有一个`moc`文件,但是`CMake`本身跨平台,生成的`mocs_compilation.cpp`并没有去重(是否真的需要?),从而导致开发者很难发现自己的问题.

工作这些年,碰见过各种让人苦笑不得的问题,开发者会在不经意的地方犯一些小错误,导致长时间的调试和问题追踪.这个给我的启示是什么? 需要对开发者"耳提面命",要求他注意这个检查那个,万分小心么?我觉得可能不应该是这样的.

不要"考验人性",也不要"考验"开发者,我们在制定工作流程,在提供开发工具时,如果可能就选择自动化,选择更好的语言/工具来帮助开发者,而不是增加开发者的心智成本.

## TODO

- [Hello C++ Insights](https://www.andreasfertig.blog/2019/03/hello-c-insights.html)
- 使用`Modern CMake`进行`deploy`
