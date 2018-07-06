# Algorithm [621. Task Scheduler](https://leetcode.com/problems/task-scheduler/description/)

### 问题描述
- 输入

一堆任务,每个任务耗时1,但是相同任务之间执行间隔不能小于 **n**（冷却时间）
- 约束

任务以`A`到`Z`的单个字母为代号,代号相同则任务相同,每个时间段CPU可以完成一个任务或者保持空闲,任务执行顺序无要求
- 输出

执行完任务队列最少需要耗时多久

### 初步思路
1. 统计每种任务的个数
2. 根据任务个数进行排序
3. 根据任务间隔填充不同的任务,任务不足则Idle,递减执行过的任务
4. 循环步骤3直到任务全部完成

### 存在的问题
上述思路如果 **n**小于任务个数,则数量最多的任务减少最快,如果过程中不调整排序,会导致头部先执行完,尾部的才执行,没有重复利用不同的任务,导致求出来的不是最少耗时。

### 解决方案
1. 统计每种任务的个数
2. 排序并移除为空的任务
3. 根据任务间隔填充不同任务,任务不足则Idle,递减执行过的任务
4. 排序并移除为空的任务
5. 循环执行步骤3和4直到任务队列为空

```C++
int leastInterval(vector<char>& tasks, int n) {
    if (n < 1) return tasks.size();
    
    std::vector<int> letter_numbers(26, 0);
    for (auto& ch : tasks) {
        letter_numbers[ch - 'A']++;
    }

    //排序并移除完成的任务
    auto action = [&]() {
        std::sort(std::begin(letter_numbers), std::end(letter_numbers),
            [](int lhs, int rhs)->bool { return lhs > rhs; });
        for (int i = 0; i < letter_numbers.size(); i++) {
            if (letter_numbers[i] == 0) {
                letter_numbers.resize(i);
                break;
            }
        }
    };
    action();

    int interval = n+1;
    int result = 0;
    while (!letter_numbers.empty()) {
        int v = std::min(interval, static_cast<int>(letter_numbers.size()));
        result += v;
        for (int i = 0; i < v; i++) {//移除执行完成的任务
            letter_numbers[i] -= 1;
        }
        action();//重排,确保数量最多的任务在前
        if (letter_numbers.empty()) {
            break;
        }
        result +=((interval > v)? (interval - v):0);//补完Idle
    }
    return result;
}
```

### 后记
解决这种问题背后的思路是贪心算法：先尽可能完成足够多的任务。之前没学习过这种算法,纯粹以常规的思路来思考,下周考虑做一些贪心算法标签的题目学习学习。

# Review [Variadic CRTP](VariadicCRTP.md)

[CRTP](https://eli.thegreenplace.net/2011/05/17/the-curiously-recurring-template-pattern-in-c)是一种模板技术,用来实现编译期多态,是一种静态多态技术,旨在解决性能关键位置动态多态带来的性能损耗问题。

这次将聊一聊组合式的`CRTP`,简单来讲就是,譬如动物有几种能力：走路、吃饭、跑步、睡觉,在编译期生成具有上述能力组合的`human`类型:
```C++
human_t<walk,eat,run,sleep> human;//编译器生成能够走路、吃饭、跑步、睡觉的人类
human.walk();
human.eat();
human.run();
human.sleep();
```

# Technique [C++17的Class template argument deduction](https://en.cppreference.com/w/cpp/language/class_template_argument_deduction)

在C++17之前,如果想要构造个`pair`、`tuple`、`shared_ptr`之类的,必须要指定模板参数,否则就要使用`make_pair`、`make_tuple`、`make_shared`之类的辅助函数来构造。

C++17实现了`Class template argument deducation`,模板类可以声明其如何推断出类模板,从而使得可以直接按照非模板类的方式进行构造,也无需指定模板参数,譬如之前的写法：
```C++
std::pair<int,double> p1(2,4.5);
auto p2 = std::make_pair(2,4.5);

std::tuple<int,int,double> t1(4,3,2.5);
auto t2 = std::make_tuple(4,3,2.5);
```
而C++17之后即可使用如下方式:

```C++
std::pair p(2,4.5);
std::tuple t(4,3,2.5);
```

那么如何使得自己写的模板类支持这种操作?你需要为模板类实现`deduction guide`,拿`pair`和`tuple`举例：
```C++
template<typename T1,typename T2>
pair(T1&&,T2&&) -> pair<std::common_type_t<T1>,std::common_type_t<T2>>;

template<typename Args...>
tuple(Args&&...) -> tuple<std::common_type_t<Args...>>;

```

# Share 可能你所努力去做的事情并没有什么意义
今年我给自己选了个年度专题《现代C++能为开发带来的改变》,试图借部门升级C++编译器的时机,改变一下充斥在空气中陈旧的C++代码实现。但是现在我很沮丧,我觉得可能努力去做的事情并没有什么意义。

作为所在的项目组的“架构师”,在技术方面拥有话语权,而我在研发流程中提出的设计审查、代码审查意见建议,经常性由于各种各样的原因被对应的开发略过,眼睁睁看着项目里令人不适的代码越来越多,被逼陪着加班解决问题。如果在你说话算话的一亩三分地就不能将好的实践推广出去,何谈改变部门那些大型项目组的开发?

研发管理中的风气是崇尚管理的力量,解决方案都是尝试从管理角度来解决问题,譬如推行静态检查工具,寄希望于通过机器解决问题,试图以此提高开发人员的效率,这个没错,确实需要,但是我觉得更为要紧的是提升研发能力：
- 学学啥是RAII,就不需要苦恼于内存泄漏,竟然还需要项目组专门抽调人去做内存泄漏分析工具?
- 给虚接口实现用上`override`,就不用因为功能用不了调试半天才发现虚接口改了声明。
- 读一下CppCoreGuidelines,别一个类写它几十个成员变量,满屏放不下的成员函数,至于维护代码改个BUG那么痛苦么？
- ......

人微言轻,做性能分析火焰图这么好的东西都推广不出去,或许,最难搞的是人,所以他们才倾向于从管理角度解决问题,代码？继续“烂”下去吧。


# TODO 
[Advanced Modern C++ Training](http://www.simunova.com/en/trainingDetails/advanced/advancedDetails/)



