# [Thanks for the memory(allocator)](https://blog.feabhas.com/2019/03/thanks-for-the-memory-allocator/)

`Modern C++`的其中一个设计目标就是找到新的 - 更好、更有效 - 方式来做一些我们已经可以用C++做的事情.又人可能会说这是`Modern C++`比较令人沮丧的一方面 - 如果能工作,就不要尝试调整它(或者说:当我们有完美的蜡烛时,为什么要使用灯泡).

这次我们将看到`Modern C++`的一个新特性:动态容器的`Allocator`模型.目前该特性还处于实验阶段,但是将会进入`C++20`.

`Allocator`模型允许程序员使用自己的内存管理策略来替换默认实现.默认实现虽然`C++`标准没有约定,大多数实现还是使用的`malloc/free`.

如果你的项目是高完整性或者安全关键,要求不能使用`malloc`时,理解这个特性就显得特别重要.

## 标准模板库模型

`STL`有一个分离关注点的模型,基本的拆分如下:

- 容器持有数据、管理其声明周期
- 算法处理容器中的数据
- 迭代器提供接口,允许算法访问/修改容器里的内容.

还有三个附加的概念涵盖其中:

- 仿函数允许客户端给算法提供回调
- 适配器为异构类提供一致接口
- `Allocator`管理容器的原始内存

![STL模型](https://i1.wp.com/blog.feabhas.com/wp-content/uploads/2019/03/The-STL-model.jpeg?w=643&ssl=1)

在这篇文章中,我们将会看一看`Allocator`,特别是`C++17`中`Allocator`模型的变化.

## 容器和`allocator`

所有需要申请存储空间的标准库组件(除了`std::array`,`std::shared_ptr`,和`std::function`)都是通过`allocator`来完成的.这包括STL动态容器以及`std::string`等组件.

`Allocator`负责管理原始内存存储,也负责构建/销毁分配的对象.`C++`的`Allocator`表征的是一系列需求而不是具体的类型.任何满足`Allocator`需求的类型都可以给容器用来进行内存申请和释放.

任何需要内存分配的组件都包含`Allocator`作为模板参数,让我们看一下`std::vector`的声明:

```C++
template<typename T, typename Allocator = std::allocator<T>>
class vector;
```

注意`Allocator`模板参数默认是`std::allocator`.这个`Allocator`实现使用空闲存储作为其内存资源.

> 空闲存储和堆的区别是什么?
> 在C++中,空闲存储时用来作为动态对象分配的内存区域.这个区域由new和delele使用.
> 堆是用来动态内存申请的其他区域;这个区域由malloc和free使用.
> 也就是说,这种差异主要是概念上的.在很多实现中,空闲存储和堆被映射到同样的内存段;而且很多new/delete实现底层用的是malloc/free.
> 很多程序员(包括我)倾向于交替使用这些术语.你可以认为保持概念分离是用来强调你不能混淆new/delete及malloc/free.

## 创建`Allocator`

既然`Allocator`定义的是需求,我们可以实现自己的`allocator`类型.因为很多嵌入式项目,禁止使用堆(更具体一点是指malloc算法)来作为内存资源.

让我们来构建一个非常简单的固定块`allocator`给容器使用.

在`C++03`中创建`allocator`非常直接,但是需要大量的样板代码.从`C++11`开始,简化了`Allocator`的最小需求;使得很多`Allocator`定义变得可选.这样在`Modern C++`中创建`allocator`类型相对来讲不那么复杂.

`allocator`类型是模板类;模板参数就是要申请内存的对象类型:

```C++
template <typename T>
class Pool_allocator {
public:
  using value_type = T;

  T* allocate(size_t num);
  T* allocate(size_t num, const void* hint);
  void deallocate(T* ptr, size_t num);

  Pool_allocator(const Pool_allocator&)            = default;
  Pool_allocator(Pool_allocator&&)                 = default;
  Pool_allocator& operator=(const Pool_allocator&) = default;
  Pool_allocator& operator=(Pool_allocator&&)      = default;
};


template <typename T1, typename T2>
bool operator==(
    const Pool_allocator<T1>& lhs, 
    const Pool_allocator<T2>& rhs
);


template <typename T1, typename T2>
bool operator!=(
    const Pool_allocator<T1>& lhs, 
    const Pool_allocator<T2>& rhs
)
```

因为我们的`allocator`没有内部状态,这里忽略了构造函数和析构函数.

注意,`Allocator`必须支持复制和移动构造.在示例中默认实现就足够了.

下一步,关键的实现:分配和释放.

`Allocator`是用来分配对象,而不是分配原始内存,从接口就能够看出来.在这里我们假定一些固定块内存资源已经创建了.

```C++
template <typename T>
T* Pool_allocator<T>::allocate(size_t num)
{
  T* ptr = reinterpret_cast<T*>(fixed_block_alloc(num * sizeof(T)));
  return ptr;
}


template <typename T>
void Pool_allocator<T>::deallocate(T* p, size_t num [[maybe_unused]])
{
  fixed_block_dealloc(p);
}
```

注意`alloc()`方法分配了`num*sizeof(T)`字节的原始内存,然后返回了指针.元素并没有构造/初始化-构造函数不是必须调用的.

`alloc()`的重载附带一个`void*`提示.这个提示的作用与实现相关.它可能被`allocator`使用来改善性能.例如,`std::allocator`使用这个提示来允许容器提供地址.`allocator`使用这个来提供参考引用:`allocator`尝试申请与提示尽可能靠近的内存块.

类似的,释放操作简单地返回了对象的地址.对象的析构函数没有被调用,这要求元素已经被销毁了.

另外,被申请的内存必须使用`allocate`,指针必须不能为空指针.

最终,你需要提供相等及不相等的操作符重载.

```C++
template <typename T1, typename T2>
bool operator==(
    const Pool_allocator<T1>& lhs [[maybe_unused]], 
    const Pool_allocator<T2>& rhs [[maybe_unused]]
)
{
  return true;
}


template <typename T1, typename T2>
bool operator!=(
    const Pool_allocator<T1>& lhs, 
    const Pool_allocator<T2>& rhs
)
{
  return !(lhs == rhs);
}
```

如果使用一个`allocator`实例申请的对象可以被另外一个`allocator`是否,则相等操作符才可以返回`true`.这就意味着`allocator`是可交换的.如果不能保证,则相等操作符必须返回`false`,例如`allocator`维护了自己的内存池的情况.

使用新的`allocator`比较简单,我们可以为容器提供`allocator`类型作为第二个参数,或者使用别名.

```C++
#include <vector>
#include “Pool_allocator.h”

using namespace std;

// Something to put in a container.
//
class Part {
public:
    Part() = default;
    Part(unsigned int);
    void show() const;

private:
    unsigned int part_num;
};


// Using-alias to simplify code
//
template<typename T>
using Pool_vector = vector<T, Pool_allocator<T>>


int main()
{
    // Explicitly specifying the allocator
    //
    vector<Part, Pool_allocator<Part>> part_list1 { };

    // Using the alias
    //
    Pool_vector<Part> part_list2 { };

    for (int i { 0 }; i < 20; ++i) {
        part_list1.emplace_back(i);
    }

    for (auto& part : part_list1) {
        part.show();
    }
}
```

## `allocator`和容器存在的问题

当我们开始替换`allocator`时会导致我们的代码存在语义上的问题.

```C++
#include <vector>
#include "Pool_allocator.h"
#include "Other_allocator.h"

using namespace std;


int main()
{
  vector<int, Pool_allocator<int>>  pool_vec  { 1, 2, 3, 4 };
  vector<int, Other_allocator<int>> other_vec { };

  other_vec = pool_vec;    // ERROR!
}
```

STL使用`allocator`模型将容器和他们的内存管理分开.从语义上来讲,`std::vector<int>`应该与其他`std::vector<int>`一样,而且可赋值.但是,`allocator`类型作为`std::vector`模板的参数,这会导致这两个`vector`是不同的类型.

## 多态`allocator`模型

多态`allocator`提供抽象的接口用来将容器从内存分配语义分离开.所有的多态`allocator`组件都处于`pmr`命名空间(可能是`Polymorphic Memory Resource`的缩写?)

![pmr](https://i1.wp.com/blog.feabhas.com/wp-content/uploads/2019/03/Polymorphic-allocators.jpeg?w=692&ssl=1)

`pmr::polymorphic_allocator`必须提供`allocator`要求的所有方法和属性.

`pmr::polymorphic_allocator`也提供了多态接口用来申请和释放内存.

这意味着不同的`polymorphic_allocator`实例可能有着完全不同的内存申请特性.但是对于容器来讲,他们是一样的类型.

## 内存资源

让我们从基本的开始讲.`pmr::memory_resource`是内存申请和释放的抽象接口.继承类必须实现纯虚的申请和释放函数.

注意,内存资源申请原始内存:

```C++
// <experimental/memory_resource>
//
namespace pmr {

    class memory_resource {
    public:
        memory_resource()          = default;
        virtual ~memory_resource() = default;

        void* allocate(
            std::size_t bytes,
            std::size_t alignment = alignof(std::max_align_t)
        );

        void deallocate(
            void* p,
            std::size_t bytes,
            std::size_t alignment = alignof(std::max_align_t)
        );

        bool is_equal(
            const memory_resource& other
        ) const noexcept;

    private:
        virtual void* do_allocate(
            std::size_t bytes,
            std::size_t alignment
        ) = 0;

        virtual void  do_deallocate(
            void* p, 
            std::size_t bytes, 
            std::size_t alignment
        ) = 0;

        virtual bool do_is_equal(
            const std::pmr::memory_resource& other
        ) const noexcept = 0;
    };
}
```

内存资源允许开发者控制申请内存块的对其方式.默认是`std::max_align_t`.`std::max_align_t`通常是最大标量类型,在大多数平台上是`long double`,对其需要8或者16字节.

要创建新的内存资源,你需要继承自`pmr::memory_resource`并实现纯虚函数.我们可以自己实现,但是STL也提供了一些预定义的类:

|类型|释义|
|--|--|
|`pmr::null_resource`|静态内存资源,不会进行申请动作|
|`pmr::new_delete_resource`|使用new和delete的静态程序范围的内存资源|
|`pmr::unsynchronized_pool_resource`|非线程安全内存资源,用来管理内存池中不同大小的块申请|
|`pmr::synchronized_pool_resource`|非线程安全内存资源,用来管理内存池中不同大小的块申请|
|`pmr::monotonic_buffer_resource`|仅在资源被销毁时才释放已分配内存的专用资源|

## 使用多态`allocator`

`pmr::polymorphic_allocator`类满足`Allocator`的要求,所以可以被STL的容器使用.

`polymorphic_allocator`对象在构造时需要一个指向`memory_resource`的指针.

```C++
#include <experimental/memory_resource>
#include <vector>

using namespace std;
using namespace std::experimental::pmr;


int main()
{
  polymorphic_allocator<int> alloc { new_delete_resource() };
  polymorphic_allocator<int> other { unsynchronized_pool_resource() };

  vector<int, polymorphic_allocator<int>> v1 { alloc };
  vector<int, polymorphic_allocator<int>> v2 { other };

  // Insert some data into v1...

  v2 = v1;   // OK
}
```

STL容器可以通过以一个多态`allocator`来更新.

这时,我们的`vector`拥有一样的类型.因而赋值操作也能够成功执行.

默认的内存资源可以全局调整:

```C++
include <experimental/memory_resource>
#include <vector>

using namespace std;
using namespace std::experimental::pmr;


int main()
{
  // Set the default memory resource
  //
  set_default_resource(unsynchronized_pool_resource());


  // If no memory resource is provided, use the default.
  //
  polymorphic_allocator<int> alloc     { new_delete_resource() }; 
  polymorphic_allocator<int> def_alloc { };

  vector<int, polymorphic_allocator<int>> v1 { alloc };
  vector<int, polymorphic_allocator<int>> v2 { def_alloc };

  // ...
}
```

## 同步/异步内存池

`synchronized_pool_resource`管理内存池集合,来处理不同内存块大小的请求.每个内存池管理块的集合,这些块被分成相同的大小.

![同步/异步内存池](https://i1.wp.com/blog.feabhas.com/wp-content/uploads/2019/03/unsynchronized-pool-resource.jpg?w=884&ssl=1)

调用`do_allocate()`可以根据请求的大小返回最小的内存块.

池中的耗尽内存导致该池的下一个分配请求从上游分配器分配额外的一块内存以补充池.获得的块大小在几何上增加.超过最大块大小的分配请求直接从上游分配器提供.

最大`block`大小和最大`chunk`大小可以通过配置`pmr::pool_options`给其构造函数来调整.

```C++
namespace pmr {

  struct pool_options {
    // The maximum number of blocks that will be
    // allocated at once from the upstream memory
    // resource to replenish the pool.
    //
    size_t max_blocks_per_chunk;

    // The largest allocation size that could be
    // allocated from a pool. Attempts to allocate
    // a single block larger than this will be
    // allocated directly from the upstream memory
    // resource.
    //
    size_t largest_required_pool_block;
  };
}
```

`synchronized_pool_resource`可以从多个线程访问,无需外部同步,并且可能具有特定于线程的池以降低同步成本.如果内存资源只是被一个线程访问,`unsynchronized_pool_resource`更有效率.

同步/异步内存池可能需要从上游的内存资源获取额外的`chunk`.如果需要,上游内存资源可以传递给构造函数.

如果默认的上游`allocator`没有设置,则会获取默认的内存资源.

```C++
#include <experimental/memory_resource>
#include <vector>

using namespace std;
using namespace std::experimental::pmr;


int main()
{
    // Define an ‘upstream’ memory resource
    // for our pool allocator to use.
    //
    auto upstream = monotonic_buffer_resource();
    unsynchronised_pool_resource unsync_pool { upstream };

    // Use the default memory resource -
    // new_delete_resource, in this case.
    //
    polymorphic_allocator<int> def_alloc { };

    // Use the custom memory resource.
    //
    polymorphic_allocator<int> pool_alloc { unsync_pool };


    vector<int, polymorphic_allocator<int>> v1 { def_alloc };
    vector<int, polymorphic_allocator<int>> v2 { pool_alloc };

    // ...
}
```

## 创建自己的内存资源

如果要创建自己的内存资源,则必须继承自`pmr::memory_resource`然后实现纯虚函数:

```C++
#include <experimental/memory_resource>

using namespace std::experimental::pmr;

class Tracking_resource : public memory_resource {
public:
    void* do_allocate(
        std::size_t bytes, 
        std::size_t alignment
    )                             override;
    void do_deallocate(
        void*  p, 
        size_t bytes, 
        size_t alignment
    )                             override;
    bool do_is_equal(
        const memory_resource& other
    ) const noexcept              override;

private:
  // Implementation details, as required...
};
```

我的实现仅仅是作为示例来解释如何去做:

```C++
void* Tracking_resource::do_allocate(
    std::size_t bytes,
    std::size_t alignment [[maybe_unused]]
)
{
    void* ptr = malloc(bytes);
    clog << "Allocating " << bytes << " bytes ";
    clog << "at address " << ptr << endl;
    return ptr;
}


void Tracking_resource::do_deallocate(
    void* p,
    std::size_t bytes     [[maybe_unused]],
    std::size_t alignment [[maybe_unused]]
)
{
    clog << "Freeing " << bytes << " bytes ";
    clog << "at address " << p << endl;
    free(p);
}


bool Tracking_resource::do_is_equal(
    const memory_resource& other [[maybe_unused]]
) const noexcept
{
    return true;
}
```

自定义的内存资源可以以和STL内存资源相同的方式来使用,也可以作为默认的系统内存资源.

```C++
#include "Tracking_resource.h"
#include "Non_tracking_resource.h"


int main()
{
    Tracking_resource     tracker     { };
    Non_tracking_resource not_tracker { };

    polymorphic_allocator<int> tracking_alloc     { &tracker };
    polymorphic_allocator<int> non_tracking_alloc { &not_tracker };

    vector<int, polymorphic_allocator<int>> v1 { tracking_alloc };
    vector<int, polymorphic_allocator<int>> v2 { non_tracking_alloc };

    // Insert elements...

    v2 = v1;

  // etc...
}
```

## 总结

有时候对于你的项目需求来说,默认的内存分配模型是不满足或者无法接受的.很多嵌入式开发组织已经去开发自己的容器库了,而这可能通过修改内存分配模型即可满足要求.

可以创建自己的内存分配策略非常有用,虽然早期版本的C++过于(不必要的)复杂.新的内存分配模式使得做这事情不那么繁重.

在一个分配策略不够的情况下,多态分配器提供类型擦除分配,具有多个不同的内存管理策略,同时仍保留容器的“明显”语义.

在写下这篇文章的时候,新的内存分配模型依然处于实验状态,没有全部完成.由于此功能现已包含在C++20中,我希望它很快会完成.
