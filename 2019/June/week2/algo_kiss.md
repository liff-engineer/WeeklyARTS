# [算法与 KISS](https://arne-mertz.de/2019/05/algorithms-and-the-kiss-principle/)

你可能听说过标准算法优先于原始循环的规则.主要原因在于这些算法在名字中表明了什么会发生,并且封装了循环逻辑.但是它们并不总是最佳选择.

## 使用标准算法

特别是当我们手动实现时更为复杂的算法会变得相当混乱.所以,除了代码中算法的名字之外,将算法部分与剩余逻辑剥离也是另外一个优点.它使得代码不那么复杂,因而坚持 KISS 原则.[Sean Parent 有个广为人知的演讲](https://channel9.msdn.com/Events/GoingNative/2013/Cpp-Seasoning)是关于这个主题的,我建议你看一看它.

译注:有一段内容是从 twitter 来的,作者解释了"obviously a rotate".

所以我强烈建议你学习这些算法.或者,如果你已经知道它们了,使用它,保持知识熟悉度.还有一个非常好的资源来自于[Jonathan Boccara](https://www.youtube.com/watch?v=2olsGf6JIkU).

## 有没有一些示例?

让我们看一些原始循环的示例,可以用算法来替换.我列举的这些示例与我目前工作的代码库中的内容非常相似.我将专注于两个案例.

### 复制

想象一下我们有一些容器,手写的或者获取自第三方库.它具有标准兼容的迭代器,并包含一堆`Employee`数据.为了在业务逻辑中复用这些数据,数据将会转换到`std::vector`中:

```C++
OtherContainer<Employee> source;
//...

std::vector<Employee> employees;
employees.reserve(source.size());

for (auto const& employee : source) {
    employees.push_back(employee);
}
```

那么将循环替换成算法是相当直接的,我们只是需要一个简单的复制:

```C++
std::vector<Employee> employees;
employees.reserve(source.size());

std::copy(std::begin(source), std::end(source), std::back_inserter(emplyoees));
```

这里的`std::back_inserter`创建了`std::back_insert_interator`通过`push_back`来写入容器.

看起来比较简单了对吧? 想一想,这里有个更为简单的版本:

```C++
std::vector<Employee> employees(std::begin(source), std::end(source));
```

这个是`std::vector`的迭代器范围构造函数,在其他标准容器中也存在,因此有时候甚至比标准算法更好地替代原始循环.

### 转换

在我们后续的代码中,想要分析员工的工资.`Employee`类包含`uniqueName`方法,我们可以将员工的名字和工资存储到`std::map`中:

```C++
std::map<std::string, unsigned> salariesByName;

for (auto const& employee : employees) {
    salariesByName[employee.uniqueName()] = employee.salary();
}
```

我们可以使用`map`的`insert`方法来替换访问操作:

```C++
std::map<std::string, unsigned> salariesByName;

for (auto const& employee : employees) {
    salariesByName.insert(
        std::make_pair(
            employee.uniqueName(),
            employee.salary()
        )
    );
}
```

从一个容器中获取元素为另一个容器创建不同元素的算法是`std::transform`:

```C++
std::map<std::string, unsigned> salariesByName;

std::transform(
    std::begin(employees),
    std::end(employees),
    std::inserter(salariesByName, std::end(salariesByName)),
    [](auto const& employee) {
        return std::make_pair(
        employee.uniqueName(),
        employee.salary()
        );
    }
);
```

`std::inserter`与`back_inserter`比较类似,但是其需要一个迭代器来调用`insert`.针对`std::map`这个迭代器表示了元素要插入的位置提示.lambda 执行了`Employee`到`map`入口的转换.

现在,这看起来并不像我们之前的第一个循环那样清晰明了,对吧? 不用担心,它会变得更好.

## 条件转换

列出所有员工的工资很有意思,但是或许你的管理者不希望你知道他们的薪水.因而我们面临附加的要求,从工资列表中排除掉管理者.在我们的原始循环中,可以这样做:

```C++
std::map<std::string, unsigned> salariesByName;

for (auto const& employee : employees) {
    if (!employee.isManager()) {
        salariesByName[employee.uniqueName()] = employee.salary();
    }
}
```

循环变得复杂了但是仍然可读.我们可能不相信为了使其更具可读性,在这里使用算法是必要的.但是让我们看看我们这样做会怎样.通常包含条件的算法,会有个`_if`的后缀名
.譬如`std::copy_if`是复制满足条件的内容,而`std::find_if`和`std::remove_if`则作用于那些满足条件而不是值的元素.那么我们要找的算法是`transform_if`.但是标准库不存在这样的算法.幸运的是实现这样的算法并不困难.我们自行实现算法,然后代码变成如下形式:

```C++
template <typename InIter, typename OutIter,typename UnaryOp, typename Pred>
OutIter transform_if(InIter first, InIter last,OutIter result, UnaryOp unaryOp, Pred pred) {
    for(; first != last; ++first) {
        if(pred(*first)) {
        *result = unaryOp(*first);
        ++result;
        }
    }
    return result;
}

//...

std::map<std::string, unsigned> salariesByName;

transform_if(
    std::begin(employees),
    std::end(employees),
    std::inserter(salariesByName, std::end(salariesByName)),
    [](auto const& employee) {
        return std::make_pair(
        employee.uniqueName(),
        employee.salary()
        );
    },
    [](auto const& employee) {
        return !employee.isManager();
    }
);
```

现在我们有两个 lambda - 转换操作和判断操作.传统上,后者是算法的最后一个参数.如果我们认真编写`transform_if`,那就需要实现 4 个版本的`std::transform`.

这个实现看起来一点儿也不明显,我随时会使用 3 行循环替换掉这个怪物.

## 性能怎么样

这个问题总会出现,我给出的第一个答案总是:首先,编写可读代码.其次,检查这种情况下性能是否重要.然后,测量,测量,测量.

至于可读代码,我隐含了我的偏好.在这些简单案例中,for 循环明显更可读.第二,我们构造容器然后填充它们,这个应当在输入时就发生,而不是在循环中.在任何情况下,插入到`map`总会分配内存.内存分配对性能的影响要远远大于手写循环和库实现的影响.

但是,我当然会做一些测量.

![m1](https://arne-mertz.de/blog/wp-content/uploads/2019/05/copy.png)
![m2](https://arne-mertz.de/blog/wp-content/uploads/2019/05/transform.png)
![m3](https://arne-mertz.de/blog/wp-content/uploads/2019/05/transform_if.png)

在这里,测量结果标签带`naive_`的是手写循环,然后针对每个上述片段都有个测量.我并没有分析算法的性能表现为何比`map`插入要差.我的猜测是`insert_iterator`在大多数情况下有错误的提示.使用排序过的输入`vector`的基准测试看起来要完全不同.我们可以看到,与循环总运行时间相比,算法和循环性能之间的差异很小.

## 那么`ranges`呢?

C++20 中有[Ranges](https://arne-mertz.de/2017/01/ranges-stl-next-level/).使用`ranges`,复制自定义容器元素的实现如下:

```C++
OtherContainer<Employee> source;

auto employees = source | std::ranges::to_vector;
```

无论在你看来这个是否比迭代器范围构造要清晰,我都会告诉你,我认为对于我来说这个看起来更优雅.我没有测量其性能表现.

`transform_if`示例实现如下:

```C++
auto salariesByName = employees
    | std::view::filter([](auto const& employee) {
        return !employee.isManager();
    })

    | std::view::transform([](auto const& employee) {
        return std::make_pair(
        employee.uniqueName(),
        employee.salary()
        );
    })

    | to<std::map>;
```

依然有两个 lambda,但是它更结构化,因为每个 lambda 都传递给了一个带有描述性名字的函数.个人来说,我依然喜欢循环版本,那个看起来更为紧凑.但是,随着更多要求的增加,循环将变得不那么明显.

## 总结

算法更优的规则依然适用:无论何时你看到一个原始循环,检查一下看是否可以用算法替换掉(或者`ranges`,如果可用的话).无论如何,这个规则更像是指导:不要盲目遵循,而是要有意识地做出选择,而且要注意其他替代方案,譬如迭代器范围构造函数.
