# Weekly ARTS

- 算法与 KISS
- `std::any`实现技术解析

## Algorithm [71. Simplify Path](https://leetcode.com/problems/simplify-path/)

题目要求给定 Unix 风格得绝对路径,计算出规范路径,即不包含`.`、`..`.开头必须是`/`,结尾不能有`/`,且两个路径之间只能有一个`/`分隔.

操作可以分隔为以下:

- 分隔路径
- 化简路径
- 合成路径

首先根据`/`将路径进行分段,分成一个个目录,然后根据目录特性,`.`为当前路径直接舍弃,`..`为进入上一级目录,如果以`vector`存储目录,则表征为回退.之后合成标准目录.

麻烦之处在于分隔路径时的处理,容易出错.

我的实现如下:

```C++
string simplifyPath(string path) {
    std::vector<std::string> parts;

    auto push = [&](std::string const &part) {
        if (part == ".") //当前目录不处理
        {
            return;
        }
        else if (part == "..") //上级目录
        {
            if (!parts.empty()) //只有上级目录非空才回退
            {
                parts.pop_back();
            }
        }
        else
        {
            parts.push_back(part);
        }
    };
    auto l = path.find_first_not_of('/');
    while (l != path.npos)
    {
        auto r = path.find_first_of('/', l);
        if (r != path.npos)
        {
            //parts.push_back(path.substr(l, r - l));
            push(path.substr(l, r - l));
            l = path.find_first_not_of('/', r);
        }

        if (r == path.npos) //没有/,直接是路径
        {
            //parts.push_back(path.substr(l));
            push(path.substr(l));
            break;
        }
        else if (l == path.npos) //后续全部是/
        {
            break;
        }
    }

    std::string result;
    if (parts.empty())
    {
        result = "/";
    }
    else
    {
        for (auto &part : parts)
        {
            result += "/" + part;
        }
    }
    return result;
}
```

上述实现还是需要非常小心地处理的,不过 C++有`std::getline`,可以根据分隔符将流内容进行拆分.具体可以参考相应实现.

## Review [算法与 KISS](algo_kiss.md)

## Technique [`std::any`实现技术解析](any_impl.md)

## Share

## TODO

- [Clear, Functional C++ Documentation with Sphinx + Breathe + Doxygen + CMake](https://devblogs.microsoft.com/cppblog/clear-functional-c-documentation-with-sphinx-breathe-doxygen-cmake/)

- [A Weakness in the Niebloids](https://thephd.github.io/a-weakness-in-the-niebloids)
  文中讲述了编译期扩展支持的实现方式及其问题,相应的还有[示例](https://github.com/ThePhD/sol2/blob/develop/examples/source/customization_multiple.cpp).

一些关于`function_ref`的实现方法:

- [foonathan](https://github.com/foonathan/type_safe/blob/master/include/type_safe/reference.hpp#L489-L655)
- [TartanLlama](https://github.com/TartanLlama/function_ref/blob/master/function_ref.hpp)

而如果只是想使用函数指针,则可以参考[std::is_function](https://en.cppreference.com/w/cpp/types/is_function).
