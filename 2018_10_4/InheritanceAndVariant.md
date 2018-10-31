# [Inheritance vs std::variant](https://cpptruths.blogspot.com/2018/02/inheritance-vs-stdvariant-based.html)

C++是比较复杂的语言,你如果用Java就压根没有这个题目存在的必要,但是在C++里,用不用继承,用继承和`std::variant`有什么优劣,这个都要探讨一下......

C++社区一直有些声音,诸如什么[Inheritance is evil. Stop using it](https://codeburst.io/inheritance-is-evil-stop-using-it-6c4f1caf5117),[OOP is dead, long live Data-oriented design](https://github.com/CppCon/CppCon2018/blob/master/Presentations/oop_is_dead_long_live_dataoriented_design/oop_is_dead_long_live_dataoriented_design__stoyan_nikolov__cppcon_2018.pdf),这次我们先来看看继承与`std::variant`的对比吧。

C++17新增了`std::variant`和`std::visit`,值得仔细研究研究,这篇文章对比了继承和`std::variant`,试图找出在处理`sum-types`时是否总是比继承要好,如果不是,什么情况下选择继承更好。

## 对比

| 继承 | `std::variant`|
| --- | --- |
| 不需要事先知道所有类型(开放世界设定) | 必须知道所有类型|
| 通常要动态分配内存 | 不需要动态分配内存 |
| 侵入(必须继承自基类) | 非侵入 (第三方库类也可使用)|
| 引用语义  |值语义 |
| 算法散布在类中 | 算法在一个位置|
| 语言级支持  | 库支持(错误信息比较差)|
| 类抽象 | 只是个容器 |
| 流畅的操作 |  重复`std::visit` |
| 支持递归类型(组合) |必须使用recursive_wrapper和动态内存分配,C++17标准不支持|
| 添加新接口需要修改所有类 | 添加新接口只需要写个free函数|
| 可使用Visitor设计模式访问 | |

## 示例

网球比赛的状态:

- NormalScore
- DeuceScore
- AdvantageScore
- GameCompleteScore

使用`std::variant`表达比赛状态:

```C++
struct NormalScore {
    Player p1,p2;
    int p1_score,p2_score;
};
struct DeuceScore {
    Player p1,p2;
};
struct AdvantageScore {
    Player lead,lagging;
};

struct GameCompleteScore {
    Player winner,loser;
    int loser_score;
};

using GameState = std::variant<NormalScore,DeuceScore,AdvantageScore,GameCompleteScore>;
```

下一个比赛状态实现(overloaded实现自行google或者参见之前介绍):

```C++
GameState next(const GameState& now,const Player& who_scored){
    return std::visit(overloaded{
        [&](const DeuceScore& ds )->GameState {
            if(ds.p1 == who_scored){
                return AdvantageScore{ds.p1,ds.p2};
            }
            else
            {
                return AdvantageScore{ds.p2,ds.p1}; 
            }
        },
        [&](const AdvantageScore& as) -> GameState{
            if(as.lead == who_scored){
                return GameCompleteScore{as.lead,as.lagging,40};
            }
            else{
                return DeuceScore{as.lead,as.lagging};
            }
        },
        [&](const GameCompleteScore& )->GameState {
            throw "Illegal State";
        },
        [&](const NormalScore& ns) -> GameState {
            if(ns.p1 == who_scored){
                switch(ns.pl_score){
                    case 0: return NormalScore{ns.p1,ns.p2,15,ns.p2_score};
                    case 15: return NormalScore{ns.p1,ns.p2,30,ns.p2_score};
                    case 30:
                        if(ns.p2_score < 40)
                            return NormalScore{ns.p1,ns.p2,40,ns.p2_score};
                        else
                            return DeuceScore{ns.p1,ns.p2};
                    case 40: return GameCompleteScore{ns.p1,ns.p2,ns.p2_score};
                    default: throw "Make no sense!";
                }
            }
            else{
                switch(ns.p2_score){
                    case 0: return NormalScore{ns.p1,ns.p2,ns.p1_score,15};
                    case 15: return NormalScore{ns.p1,ns.p2,ns.p1_score,30};
                    case 30:
                        if(ns.p1_score < 40)
                            return NormalScore{ns.p1,ns.p2,ns.p1_score,40};
                        else
                            return DeuceScore{ns.p1,ns.p2};
                    case 40: return GameCompleteScore{ns.p2,ns.p1,ns.p1_score};
                    default: throw "Make no sense!";
                }
            }
        }
    },now);
};
```

而如果使用继承方式实现:

```C++

class GameState{
    std::unique_ptr<GameStateImpl> _state;
public:
    void next(const Player& who_scored){};
};

class GameStateImpl {
    Player p1,Player p2;
public:
    virtual GameStateImpl* next(const Player& who_scored) = 0;
    virtual ~GameStateImpl(){};
};

class NormalScore:public GameStateImpl {
    int p1_score,p2_score;
public:
    GameStateImpl* next(const Player& who_scored);
};

//其它三种状态
```

可以看到,采用`std::variant`聚合程度更高,更为清晰,而采用继承的方式代码繁琐,算法分散,修改不易。

但是继承的方法共享状态更为简单:

```C++
class GameState{
    std::unique_ptr<GameStateImpl> _state;
public:
    void next(const Player& who_scored){};

    Player& who_is_serving() const;
    double fastest_serve_speed() const;
    GameState get_last_state() const;
};

class GameStateImpl {
    Player p1,Player p2;

    int serving_plasyer;
    double speed;
    GameState last_state;
public:
    virtual GameStateImpl* next(const Player& who_scored) = 0;
    virtual ~GameStateImpl(){};

    Player& who_is_serving() const;
    double fastest_serve_speed() const;
    GameState get_last_state() const;
};
```

而采用`std::variant`则需要重复性动作来完成.同样,想要获取某些信息,使用`std::visit`也非常繁琐:

```C++
GameState last_state = std::visit([](auto& s){
    return s.get_last_state();
},state);
```

如果要解决共享数据的问题,可以混合继承与`std::variant`实现:

```C++

struct SharedGameState{
    Player& who_is_serving() const;
};

struct NormalScore:public SharedGameState
{
    ;///
};
//其他三个状态

Player who_is_serving = std::visit([](SharedGameState & s){
    return s.who_is_serving();
},state);
```

## 总结

围绕着`std::variant`有很多文章讲述了替代继承的实现方式,在一些场景下确实非常有用,值得好好研究.围绕着`std::variant`及模式匹配,也有一些新的提案尝试解决`std::visit`这种相对繁琐的写法,感兴趣可以搜索并关注下.