# [224. Basic Calculator](https://leetcode.com/problems/basic-calculator/)

题目要求实现一个基本的计算器用来计算简单的表达式.

字符串可能包含`(`、`)`、`+`、`-`,非负整数和空格. 可以假设表达式总是有效的.

## 解决思路

这种问题之前在工作中实现过,基本上分为三步:

1. 分解为 token
2. 调度场算法去除`(`和`)`,并调整计算顺序
3. 运算

## 分解为 token

这里的 token 只有三种类型:结束符、数字、标点符号,空格被移除掉.

其中标点符号直接读取,数字则需要一直读取直到遇到非数字符号.

```C++
std::vector<std::string> parse(std::string s)
{
    static constexpr int t_eof = 0;
    static constexpr int t_number = 1;
    static constexpr int t_punct = 2;

    std::stringbuf sb{s};
    std::string result;
    auto token = [&]() {
        auto t = t_eof;
        auto ch = sb.sbumpc();
        result.clear();
        while (ch != EOF)
        {
            if (ch == ' ')
            {
                ch = sb.sbumpc();
                continue;
            }

            //当数字结束
            if (t == t_number && !std::isdigit(ch))
            {
                sb.sputbackc(ch);
                return t_number;
            }

            if (std::isdigit(ch)) //数字未解析完成
            {
                t = t_number;
                result.push_back(ch);
            }
            else if (std::ispunct(ch)) //标点符号
            {
                result.push_back(ch);
                return t_punct;
            }
            ch = sb.sbumpc();
        }
        return t_eof;
    };

    std::vector<std::string> results;
    auto t = t_eof;
    do
    {
        t = token();
        if (!result.empty())
        {
            results.push_back(result);
        }
    } while (t != t_eof);

    return results;
}
```

## 调度场算法

调度场算法的功能是处理运算优先级,过程中会移除掉`(`和`)`.

```C++
std::vector<std::string> shunting_yard(std::vector<std::string> const &expr)
{
    std::vector<std::string> result;
    std::stack<std::string> oprs;

    auto is_operator = [](std::string const &token) -> bool {
        return token == "+" || token == "-";
    };

    bool expect_opr = false;
    for (auto i = 0ul; i < expr.size(); i++)
    {
        //如果是操作符
        if (is_operator(expr.at(i)))
        {
            //assert(expect_opr);
            //从栈中移除所有的操作符
            while (!oprs.empty() && is_operator(oprs.top()))
            {
                result.push_back(oprs.top());
                oprs.pop();
            }
            oprs.push(expr.at(i));
            expect_opr = false;
        }
        else if (expr.at(i) == "(")
        {
            //assert(!expect_opr)
            oprs.push(expr.at(i));
        }
        else if (expr.at(i) == ")")
        {
            //assert(expect_opr)
            while (!oprs.empty() && oprs.top() != "(")
            {
                result.push_back(oprs.top());
                oprs.pop();
            }

            //if(oprs.empty()) //不平衡的()

            oprs.pop();
            expect_opr = true;
        }
        else //找到数字
        {
            //assert(!expect_opr)
            result.push_back(expr.at(i));
            expect_opr = true;
        }
    }
    //assert(expect_opr)
    while (!oprs.empty())
    {
        //assert(oprs.top() != "(")
        result.push_back(oprs.top());
        oprs.pop();
    }
    return result;
}
```

## 运算

经过调度场算法后可以直接处理运算符和值:

```C++
int calculate(std::string s)
{
    std::stack<int> evals;
    auto tokens = shunting_yard(parse(s));
    std::queue<std::string> nodes;
    std::for_each(tokens.begin(), tokens.end(), [&](auto const &str) { nodes.push(str); });

    while (!nodes.empty())
    {
        auto v = nodes.front();
        nodes.pop();

        if (v == "+" || v == "-")
        {
            //注意左操作数和右操作数
            auto rhs = evals.top();
            evals.pop();
            auto lhs = evals.top();
            evals.pop();
            if (v == "+")
            {
                evals.push(lhs + rhs);
            }
            else if (v == "-")
            {
                evals.push(lhs - rhs);
            }
        }
        else
        {
            evals.push(std::stoi(v));
        }
    }
    return evals.top();
}
```

## 总结

之前因为工作需要实现过带变量的表达式计算器,今天完成了这个题目却发现运行效率非常差,下周要看看其它人的实现方式,再练习一下这种算法.
