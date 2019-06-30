# Weekly ARTS

- 什么是对象?
- 如何检查类型 `T` 是否在模板参数包 `Ts...`中
- 项目中的"破窗效应"

## Algorithm [929. Unique Email Addresses](https://leetcode.com/problems/unique-email-addresses/)

随机个 easy 的题目轻松一下,题目要求是找出邮箱列表中包含有多少个地址.邮箱包含了`local name`和`domain name`,两者使用`@`分隔开来.邮箱除了小写字母外,还可能包含`.`或者`+`.在`domain name`中这两个字符对地址没有影响.如果存在于`local name`中,则会影响到地址.其中`.`在地址表示中会被移除,而`+`则会将`local name`中后续的字符串移除.

这个题目关键在于如何从邮箱得到地址,处理思路如下:

1. 截取`local name`,遇到`.`跳过,遇到`+`或者`@`跳出
2. 找到`domain name`位置,查询直到碰到`@`
3. 保存`domain name`

然后遍历所有邮箱获得地址表示存入`unordered_set`中,最终集合元素个数即为地址个数:

```C++
int numUniqueEmails(vector<string>& emails) {
    std::unordered_set<std::string> results;

    auto simplify = [](const std::string &email) -> std::string {
        std::string result;
        result.reserve(email.size());

        std::size_t idx = 0ul;
        //获取local name
        for (; idx < email.size(); idx++)
        {
            if (email[idx] == '.')
                continue;
            if (email[idx] == '+' || email[idx] == '@')
                break;
            result.push_back(email[idx]);
        }

        //找到domain name位置
        for (; idx < email.size(); idx++)
        {
            if (email[idx] == '@')
                break;
        }

        //获取domain name
        if (idx < email.size())
            result.append(email, idx);
        return result;
    };

    for (const auto &email : emails)
    {
        results.insert(simplify(email));
    }
    return results.size();
}
```

## Review [什么是对象?](object.md)

## Technique [如何检查类型 `T` 是否在模板参数包 `Ts...`中](https://stackoverflow.com/questions/56720024/how-can-i-check-type-t-is-among-parameter-pack-ts-in-c)

C++11 有了可变参数模板支持,使用时就会有这样的需求,判定类型`T`是否在`Ts...`中.我们的直觉是使用可变参数函数模板:

```C++
template<typename T,typename... Ts>
bool is_one_of<T,Ts...>();
```

使用递归遍历类型,检查类型是否相同,不同则继续下一个,直到到达终止条件:

```C++
template<typename T,typename U>
bool is_one_of<T,U>(){
    return std::is_same<T,U>;
}

template<typename T,typename U,typename... Ts>
bool is_one_of<T,U,Ts...>(){
    if(std::is_same<T,U>){
        return true;
    }
    else {
        return is_one_of<T,Ts...>();
    }
}
```

想法是挺好,但是 C++是不支持函数模板的偏特化的.

编译期表达常量,譬如布尔值,可以使用`std::true_type`以及`std::false_type`,这里可以使用类模板及其偏特化来实现:

```C++
template<typename...>
struct is_one_of: std::false_type{
};

template<typename T,typename U>
struct is_one_of<T,U>: std::is_same<T,U>{
};

template<typename T,typename U,typename... Ts>
struct is_one_of<T,U,Ts...>: std::conditional_t<std::is_same_v<T,U>,std::is_same<T,U>,is_one_of<T,Ts...>>{
};
```

默认`is_one_of`为`std::false_type`,指定终止条件`is_one_of<T,U>`为`std::is_same<T,U>`,然后使用`is_one_of<T,U,Ts...>`遍历`Ts...`.

C++模板编程需要转换观念,很多书写方式与普通的写代码不一样.不过后续的 C++标准一直在增强/简化模板编程,在 C++17 中使用`fold expression`就可以避免用类型及递归的方式实现,譬如:

```C++
template<typename T,typename... Ts>
constexpr bool is_one_of() noexcept {
    return (std::is_same_v<T,Ts>|| ...);
}
```

`fold expression`会将可变参数操作展开,针对`is_one_of<int,int,double,bool>`会被展开成如下形式:

```C++
return (std::is_same_v<int,int> || std::is_same_v<int,double> || std::is_same_v<int,boool> );
```

## Share 项目中的"破窗效应"

[破窗效应](https://zh.wikipedia.org/wiki/%E7%A0%B4%E7%AA%97%E6%95%88%E5%BA%94)指的是环境中的不良现象如果被放任存在,就会诱使人们仿效,甚至变本加厉.

为什么想起这个,我所在的项目中最初因为赶进度等因素,导致存在一些比较糟糕的代码.如今多年过去了,一直尝试修改,只是因为没有"赶尽杀绝",新同事竟然能从庞大的代码基中翻出最糟糕的写法,而对那么多好的实现方式"置之不理".

年初费尽心思在项目中实践 Modern CMake,提供了非常完善的文档,结果随着时间的推移,文档维护成为"大问题".你永远不知道团队会提交什么样的东西.而且被发现后也没什么影响.更别说一些存在的问题迟迟不解决.

也不是没有不能发,不过至今为止项目还没迁移到 git,使用`Pull Request`约束也"遥不可及".艰辛.
