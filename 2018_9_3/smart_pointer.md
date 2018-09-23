# 关于智能指针

- [Being smart about ownership](https://hackernoon.com/being-smart-about-ownership-5ba2569a3ed7)
- [C++ Core Guidelines - Smart pointers](http://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#rsmart-smart-pointers)
- [Top 10 dumb mistakes to avoid with C++ 11 smart pointers](http://www.acodersjourney.com/2016/05/top-10-dumb-mistakes-avoid-c-11-smart-pointers/)
- [GotW #91 Solution: Smart Pointer Parameters](https://herbsutter.com/2013/06/05/gotw-91-solution-smart-pointer-parameters/)

## 什么是智能指针

智能指针是用来辅助管理资源的类型,C++中没有GC,通过使用智能指针来达到类似GC的效果;智能指针,其本身不是指针,但是使用起来类似于指针,通过使用智能指针,可以申请资源,待使用结束后自动释放,从而减少出错概率,将程序员从资源管理中释放出来。

STL中有三种智能指针,分别是`std::unique_ptr`、`std::shared_ptr`、`std::weak_ptr`.

## 智能指针如何实现

智能指针的实现使用了这几种技术:RAII、运算符重载、引用计数、CRTP。

### RAII

C++语言特性,对象在脱离作用域后自动释放,示例如下:

```C++

class RAIIObject
{
public:
    RAIIObject()
    {
        std::cout<<"RAIIObject create\n";
    }
    ~RAIIObject()
    {
        std::cout<<"RAIIObject destory\n";
    }
};

void example(){
    {
        RAIIObject obj1;
    }
}
```

运行结果如下:

```CMD
RAIIObject create
RAIIObject destory
```

通过RAII这种技术,可以将资源申请和释放放在构造与析构函数中,这样就不需要关注资源的申请和释放了。

### 运算符重载

C++中很多运算符都可以重载,包括指针相关操作`->`和`*`,示例如下:

```C++

struct action
{
    std::string command;
    void execute(){
        std::cout<<command<<"\n";
    }
};

class action_ptr
{
public:
    actionr_ptr(std::string v):act(v){};

    action* operator->()  { return &act; }
    action& operator*()  { return act; }
private:
    action act;
};

void example(){
    action_ptr  act("report");

    act->execute();
    (&act).command = "print";
    act->execute();
}
```

运行结果如下:

```CMD
report
print
```

可以看到使用运算符重载即可将一个对象作为“指针”使用。

### 引用计数

引用计数用来追踪对象引用,示例如下:

```C++
class ref_count
{
public:
    ref_count() = default;
    ref_count(const ref_count& other) = default;

    long count() const { return n; };

    template<typename U>
    void inc_ref(U* p){
        if(p != nullptr){
            n++;
        }
    }

    template<typename U>
    void dec_ref(U* p)
    {
        n--;
        if(n == 0){
            delete p;
        }
    }
public:
    long n{0};
};

template<typename T>
class ref_count_user
{
public:
    explicit ref_count_user(T* p)
        :p_(p)
    {
        count.inc_ref(p_);
    }

    ~ref_count_user(){
        count.dec_ref(p_);
    }
private:
    T* p_{nullptr};
    ref_count count;
};
```

可以看到利用RAII和引用计数,即可实现追踪对象的使用情况。

### CRTP



### `std::unique_ptr`

## 智能指针如何使用

## 总结