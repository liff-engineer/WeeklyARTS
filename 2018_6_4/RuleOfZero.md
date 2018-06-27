# "Rule of Zero" - C++中的构造与析构
> [Keep it simple,stupid](https://en.wikipedia.org/wiki/KISS_principle)

Kate Gregory在Meeting C++ 2017上发表了主题演讲-[It's Complicated](https://www.youtube.com/watch?v=tTexD26jIN4)(强烈推荐),C++确实很复杂,你必须了解很多才能写出恰当的实现,但这不代表你只能写出复杂的实现。

现在我们就来了解一下C++中对象的构造与析构,以及接近 **KISS principle** 的实现。

## 开始之前
需要C/C++语言基础,明白object,struct,多态等概念。

## 前情提要
### 从C的[Struct](https://en.cppreference.com/w/c/language/struct)谈起
假设需要表达person这种对象,使用C语言可能会采用如下方式：
```C
typedef struct person_t {
    char  name[128];
    unsigned char age;
    bool    sex;//man:true;female:false
} person;
```
然后就可以构造person这种对象,对其进行各种操作:
```C
person young_man {"young_man_name",20,true};//构造
person old_woman {"old_woman_name",65,false};//构造

//复制1
person other = young_man;
//复制2
memcpy(&other,&young_man,sizoof(person));
```
但是名字如果不希望有128个char的限制,实现将变得复杂:
```C
typedef struct person_t {
    char* name;
    unsigned char age;
    bool  sex;
} person,*person_ptr;

//构造
person person_constructor(char* name,unsigned char age,bool sex){
    person result;
    int len = strlen(name);
    result.name = (char*)malloc(len+1);
    result.name[len]=0;
    strcpy(result.name,name);
    result.age = age;
    result.sex = sex;
    return result;
}

//释放/析构
void person_destructor(persion_ptr* target){
    if(target.name != NULL){
        free(target.name);
        target.name = NULL;
    }
    //外部需要释放target
}

//复制
person person_clone(persion_ptr* ptr){
    return person_destructor(ptr->name,ptr->age,ptr->sex);
}
//赋值
void   persion_assignment(persion_ptr* src,persion_ptr* dst){
    if(dst.name != NULL){
        free(dst.name);
    }

    int len = strlen(src->name);
    dst->name = (char*)malloc(len+1);
    dst->name[len]=0;
    strcpy(dst->name,src->name);

    dst->age = src->age;
    dst->sex = src->sex;
}
```
可以看到,在C中声明一个struct,可能需要以下操作：
- 构造：申请资源,初始化值等
- 析构：释放资源
- 复制：复制出一份新的
- 赋值：类似于复制,但不新建

C++在C语言的基础上做了一些改进,下面看以下C++里是怎么定义并实现的
### C++中的构造与析构
在之前演示的示例中,可以看到一些概念的来源,在C++中对象有以下几种基本方法：
- 构造函数constructor
- 析构函数destructor
- 拷贝构造copy constructor
- 拷贝赋值copy assignment operator
形式如下：
```C++
class object_t
{
public:
    object_t();  //构造
    ~object_t(); //析构
    object_t(object_t const& other);//拷贝构造
    object_t& operator=(object_t const& other);//拷贝赋值
}
```
C++编译器会自动为每个`class`生成这四种方法,当某个`class`不需要专门的操作时,则不需要专门实现这些方法;
默认生成的方法行为如下(?,可能与真实情况有出入,基于个人认知总结)：
- 构造函数：计算成员对象所需空间,请求空间并调用成员对象构造方法；
- 析构函数：调用成员对象的析构方法
- 拷贝构造：基于存储的内容复制(按byte复制,memcpy)
- 拷贝赋值：基于存储的内容复制(按byte复制,memcpy)

但是正如之前的示例,如果编译器为`class`生成的默认方法不满足要求,这时则需要专门实现,因而有了[**Rule of Three**](http://www.drdobbs.com/c-made-easier-the-rule-of-three/184401400)。
### Rule of Three
该规则指出,如果一个`class`定义了构造函数,则其几乎总是要定义拷贝构造函数和拷贝赋值操作,事实上它是两条规则：

1 如果你定义了构造函数,你可能需要定义拷贝构造函数和赋值操作

2 如果你定义了拷贝构造函数或者赋值操作，那么你可能两个都需要,并且也需要实现析构函数

根据这个规则,之前的示例可以改写成如下形式：
```C++
class person_t
{
public:
    person_t(const char* name_arg,unsigned char age_arg,bool sex_arg)
        :name(nullptr),age(age_arg),sex(sex_arg)
    {
        name = new char[std::strlen(name_arg)+1];
        std::strcpy(name,name_arg);
    };

    ~person_t(){
        if(name != nullptr){
            delete[] name;
            name = nullptr;
        }
    }

    person_t(person_t const& other)
        :name(nullptr),age(other.age),sex(other.sex)
    {
        name = new char[std::strlen(other.name)+1];
        std::strcpy(name,other.name);
    }

    person_t& operator=(person_t const& other){
        if(&other == this) return *this;//阻止赋值到自身
        if(name != nullptr){
            delete[] name;
            name = nullptr;
        }
        name = new char[std::strlen(other.name)+1];
        std::strcpy(name,other.name);

        age = other.age;
        sex = other.sex;
        return *this;
    }
private:
    char* name;
    unsigned char age;
    bool sex;
}
```
虽然这个被视为很好的实现规则,但是编译器对此并不作强制要求,[C++03标准](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2001/n1316/)中规定,如果用户没有显式声明,则编译器应当为默认为其创建相应实现：
> § 12.4 / 3 If a class has no user-declared destructor, a destructor is declared implicitly
>
> § 12.8 / 4 If the class definition does not explicitly declare a copy constructor, one is declared implicitly.
>
> § 12.8 / 10 If the class definition does not explicitly declare a copy assignment operator, one is declared implicitly

因而如果采用C++03标准的编译器,则不遵循`Rule of Three`来实现可能会出现问题,譬如示例中的`persion_t`,如果任意函数缺失,都有可能引起内存泄漏、崩溃等问题。

基于这个问题,在之后的[C++11标准](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2011/n3242.pdf)中废弃了之前的行为:
>D.3 Implicit declaration of copy functions [depr.impldec]
>
>The implicit definition of a copy constructor as defaulted is deprecated if the class has a user-declared copy assignment operator or a user-declared destructor. The implicit definition of a copy assignment operator as defaulted is deprecated if the class has a user-declared copy constructor or a user-declared destructor. In a future revision of this International Standard, these implicit definitions could become deleted

也就是说,符合C++11标准的编译器同样会生成默认的实现,但是编译器至少需要产生警告来提醒用户(知道警告的重要性了吧),虽然一直有讨论说要禁止而不是废弃这种行为,但是C++14标准和C++17标准并没有全面禁止掉该行为(后向兼容需要付出的代价)。

C++11标准引入了move操作,从而使`Rule of Three`变成了`Rule of Five`,基于之前谈到的问题,编译期生成move操作有所限制。

### 简单谈一下move
借用STL,之前的`persion_t`可以改写成如下形式:
```C++
class persion_t
{
    persion_t(const char* name_arg,unsigned char age_arg,bool sex_arg)
        :name(name_arg),age(age_arg),sex(sex_arg)
    {}
private:
    std::string name;
    unsigned  char age;
    bool sex;
}
```
借助于STL和编译器为`persion_t`默认生成的拷贝构造、拷贝赋值、析构函数,就可以实现安全的`persion_t`：
```C++
person_t young_man("young_man_name",20,true);//构造
person_t old_woman("old_woman_name",65,false);//构造

person_t other(young_man);
other = old_woman;
```
但是存在一个问题-效率,示例如下：
```C++
std::vector<person_t> list;
list.push_back(persion_t("name1",20,true));
list.push_back(persion_t("name2",40,false));
```
在示例中构造的`persion`直接存储到了`list`中,构造出来的`persion_t`只是临时的对象,然后就通过拷贝构造或者拷贝赋值用来初始化真正的对象,如果对象中纯粹是`value`还好说,`persion_t`中包含了`std::string`,在这个过程中多申请了一份内存,并多了一次字符串复制操作！

作为注重效率的语言,C++11通过引入move语义来解决这个问题,思路就是把内容从一个对象中移动到另外一个对象中,而不是复制一份,例如：
```C++
class array_t
{
    array_t(array_t&& other)
        :buffer(other.buffer),length(other.length)
    {
        other.buffer = nullptr;
        other.length = 0;
    };

    array_t& operator=(array_t&& other) {
        if(&other == this) return *this;
        if(buffer != nullptr){
            delete[] buffer;
        }
        
        buffer = other.buffer;
        length = other.length;

        other.buffer = nullptr;
        other.length = 0;
        return *this;
    }
private:
    char* buffer;
    int   length;
};
```
可以看到,`array_t`中的两个方法并没有申请新内存并执行复制操作,而是将`other`里的内容`偷`了过来,从而避免带来效率问题。

### Rule of Five
C++11标准引入的move语义,导致`class`多了两种基本方法
- 移动构造move constructor
- 移动赋值move assignment operator
形式如下:
```C++
class object_t
{
public:
    object_t();  //构造
    ~object_t(); //析构
    object_t(object_t const& other);//拷贝构造
    object_t& operator=(object_t const& other);//拷贝赋值
    object_t(object_t && other); //移动构造
    object_t& operator=(object_t && other);//移动赋值
}
```
之前`Rule of Three`要求实现三个方法,`Rule of Five`在其基础上新增了两个方法,但是不同之处在于,这两个方法并不是在所有情况下都自动生成,C++11标准中约束如下：
>§ 12.8 / 9
>
>If the definition of a class X does not explicitly declare a move constructor, one will be implicitly declared as defaulted if and only if
> - X does not have a user-declared copy constructor,
> - X does not have a user-declared copy assignment operator,
> - X does not have a user-declared move assignment operator,
> - X does not have a user-declared destructor, and
> - The move constructor would not be implicitly defined as deleted.

>§ 12.8 / 20
>
>If the definition of a class X does not explicitly declare a move assignment operator, one will be implicitly declared as defaulted if and only if
> - does not have a user-declared copy constructor,
> - does not have a user-declared move constructor,
> - does not have a user-declared copy assignment operator,
> - does not have a user-declared destructor, and
> - The move assignment operator would not be implicitly defined as deleted.

也就是说,一旦`class`定义了拷贝构造、拷贝赋值、析构函数、移动构造或者移动赋值,移动构造和移动赋值函数将不会自动生成。

在C++14标准中更进一步,一旦显式声明了移动构造或者移动赋值,则默认将拷贝构造和拷贝赋值声明为`deleted`,这就意味着显式移动操作会使对象默认不可复制/赋值,基本上非常接近于编译器强制要求`Rule of Five`：
> § 12.8 / 7
>
>If the class definition does not explicitly declare a copy constructor, one is declared implicitly. If the class definition declares a move constructor or move assignment operator, the implicitly declared copy constructor is defined as deleted; otherwise, it is defined as defaulted (8.4). The latter case is deprecated if the class has a user-declared copy assignment operator or a user-declared destructor.

>§ 12.8 / 18
>
>If the class definition does not explicitly declare a copy assignment operator, one is declared implicitly. If the class definition declares a move constructor or move assignment operator, the implicitly declared copy assignment operator is defined as deleted; otherwise, it is defined as defaulted (8.4). The latter case is deprecated if the class has a user-declared copy constructor or a user-declared destructor.

于是,C++在03标准的基础上又变得复杂了......

## 进入正题
从目前看来,在C++里写个`class`都简直是灾难,写个`class`除了构造函数还要多写5个函数?

实际上,可能连构造函数都不需要写!
### Rule of Zero
从`Rule of Three`到`Rule of Five`,终于到了`Rule of Zero` - [Peter Sommerlad在'Simpler C++ With C++11/14'中创造的术语](http://wiki.hsr.ch/PeterSommerlad/files/MeetingCPP2013_SimpleC++.pdf):
>Write your classes in a way that you do not need to declare/define neither a destructor, nor a copy/move constructor or copy/move assignment operator
>
>Use smart pointers & standard library classes for managing resources

借助于智能指针和标准库来管理资源,利用编译器默认生成的实现,不再需要为你的`class`声明或者定义析构、拷贝/移动构造,拷贝/移动赋值。

为什么我们要绕过编译器创建自己的实现?通常有两种情况：

    1 管理资源
    2 多态的析构及虚函数

### 管理资源
在C++98或者03中,如果需要与第三方库等交互，可能会面临资源管理的问题,`Rule of Three`的写法：
```C++
struct example_t
{
    example_t():m_ptr(API::createResource()){};
    ~example_t() { API::releaseResource(m_ptr);}
private:
    example_t(example_t const&);
    example_t& operator=(example_t const&);
    API::Resource* m_ptr;
}
```
到了C++11/C++14,需要采用`Rule of Five`的写法：

```C++
struct example_t
{
    example_t():m_ptr(API::createResource()){};
    ~example_t() { API::releaseResource(m_ptr);}

    example_t(example_t const&) = delete;
    example_t& operator=(example_t const&) = delete;

    example_t(example_t && other):m_ptr(other.m_ptr){ other.m_ptr = nullptr;} ;
    example_t& operator=(example_t && other){
        example_t tmp {std::move(other)};
        std::swap(m_ptr,tmp.m_ptr);
        return *this;
    }
private:
    API::Resource* m_ptr;
}
```
采用智能指针的`Rule of Zero`写法:
```
struct example_t
{
    example_t():m_ptr(API::createResource(),&API::ReleaseResoucreWrap){};
private:
    std::unique_ptr<API::Resource,decltype(&API::ReleaseResoucreWrap)> m_ptr;
}
```

### 运行时多态
当采用运行时多态时面临一些问题,C++的开发者之前被告知如果类中声明的有虚函数,则需要将析构函数声明成虚方法,例如:
```C++
struct itask_t
{
    virtual void run() = 0;
}
```
则需要写成:
```C++
struct itask_t
{
    virtual ~itask_t(){};
    virtual void run() = 0;
}
```
那么根据C++11标准,一旦声明了析构函数,编译期就会将move操作声明为`deleted`,为了支持move操作,必须写成：
```C++
struct itask_t
{
    virtual ~itask_t() = default;
    itask_t(itask_t &&) = default;
    itask_t& operator=(itask&&) = default;

    virtual void run() = 0;
}
```
如果是C++14标准,则会将拷贝构造和赋值构造一并`deleted`掉,那么就需要写成如下形式:
```C++
struct itask_t
{
    virtual ~itask_t() = default;
    itask_t(itask_t const&) = default;
    itask_t& operator=(itask const&) = default;
    itask_t(itask_t &&) = default;
    itask_t& operator=(itask&&) = default;

    virtual void run() = 0;
}
```
那么,是否真的不能使用`Rule of Zero`了?事情并不是这样的。
为何添加了虚函数,则“必须”声明虚构造函数？原因如下：
```
{//非智能指针
    std::vector<itask_t*> tasks;
    for(auto t:tasks){
        delete t;
    }
    tasks.clear();
}
{//智能指针
    std::vector<std::unique_ptr<itask_t>> tasks;
    tasks.clear();
}
```
当对`itask_t`进行`delete`操作时,必须定位到具体类的析构操作,否则会出现析构不正确的情况,例如：
```C++
struct task_t{
    virtual void run() = 0;
};

struct task_impl :public task_t
{
    void run() override;
};

void apply(){
    task_t* task = new task_impl();
    delete task;
    //调用的析构函数是task.~task_t();
    //正确的调用应该是task.~task_impl();
}
```

### 运行时多态的`Rule of Zero`
问题并非不能得到解决,在[`Rule of Zero`的第二部分`Use smart pointers & standard library classes for managing resources`]:

>Under current practice, the reason for the virtual destructor is to free resources via a pointer to base. Under the Rule of Zero we shouldn’t really be managing our own resources, including instances of our classes.

解决方案也很简单：
```C++
struct task_t{
    virtual void run() = 0;
};

struct task_impl :public task_t
{
    void run() override;
};

void apply(){
    std::shared_ptr<task_t> task = std::make_shared<task_impl>();
    //脱离作用域则task析构
    //task自身是std::shared_ptr<task_impl>的副本,能够正确找到析构函数
}
```

### 关于构造函数
在一些类声明中,构造函数的目标只是为了初始化成员变量,C++11标准允许为成员变量提供默认初始化操作,并且提供了通用初始化语法,如果构造函数的目的单纯为了把成员变量赋初值,可以参考如下写法：
```C++
class person_t
{
private:
    std::string name = "empty";
    unsigned char age = 20;
    bool        sex = true;
}
```

## 总结

C++很复杂,复杂到你需要深入地了解方方面面,但是在实现时,可以有尽可能简单的原则:

- 尽可能采用标准,使用智能指针和STL,应用`Rule of Zero`,避免不必要的复杂度
- 一旦无法做到,应用`Rule of Five`/`Rule of All`

> **Keep it simple,stupid!**

## 参考
- [Enforcing the Rule of Zero](https://accu.org/index.php/journals/1896)
- [Modern C++ Features – Default Initializers for Member Variables](https://arne-mertz.de/2015/08/new-c-features-default-initializers-for-member-variables/)



