# entt 中 Component 的存储实现

在 ECS 架构中,需要从 Entity 上获取各种 Component 的引用(地址)进行操作.这就涉及到如何涉及 Component 的存储方式.

之前我们知道可以使用稀疏来实现非常高效的整数插入、删除、查找、清楚等操作.而在 entt 中,也是基于稀疏集合实现的 Component 存储.既可以在操作上最大化效率,也兼顾了内存使用.

## 使用示例

Entity 以及 Component 如何搭配使用,以下是 entt 的示例:

```C++
struct position {
    float x;
    float y;
};

struct velocity {
    float dx;
    float dy;
};

void update(entt::registry &registry) {
    auto view = registry.view<position, velocity>();

    for(auto entity: view) {
        // gets only the components that are going to be used ...

        auto &vel = view.get<velocity>(entity);

        vel.dx = 0.;
        vel.dy = 0.;

        // ...
    }
}
```

可以看到,通过`registry.view`,搭配 Component 类型,即可取出所有满足条件的 Entity.

那么这个操作是如何完成的?

## `sparse_set`

在 entt 的`sparse_set`中提供了两个`sparse_set`模板类:

- `sparse_set<Entity>`
- `sparse_set<Entity,Type>`

这两个的作用不一样,其中`sparse_set<Entity>`目标是通用的`Entity`稀疏集合;而`sparse_set<Entity,Type>`则是设计用来存储特定的 Component 类型的.

`sparse_set<Entity,Type>`继承自`sparse_set<Entity>`,并添加了存储内容:

```C++
std::conditional_t<std::is_empty_v<Type>, Type, std::vector<Type>> instances;
```

这个存储内容会根据`Type`是否为空(作为类型 Tag)使用,将 Component 示例存储为`CompoentType`或者`std::vector<ComponentType>`.需要注意的是,`instances`是对应稠密集合的,因而覆盖`sparse_set<Entity>`的接口时需要小心处理.

`sparse_set<Entity,Type>`提供了集合的各种操作,譬如调整大小,创建新元素,根据 Entity 访问目标元素等等.由于其基类是`sparse_set<Entity>`,后续我们可以针对不同的 Component 提供统一存储.

## `pool_data`

在`basic_registry<Entity>`中提供了具体的 Component 存储池组件`pool_data`:

```C++
struct pool_data {
    std::unique_ptr<sparse_set<Entity>> pool;
    std::unique_ptr<sparse_set<Entity>> (* clone)(const sparse_set<Entity> &);
    void (* destroy)(basic_registry &, const Entity);
    ENTT_ID_TYPE runtime_type;
};
```

就如之前所说,`sparse_set<Entity,Type>`继承自`sparse_set<Entity>`,这里将所有 Component 存储都定义为`std::unique_ptr<sparse_set<Entity>>`,而 Component 的类型 ID 则记录为`ENTT_ID_TYPE runtime_type`,然后就可以通过比对`runtime_type`这个 Component 类型 ID 来获取对应的存储,将其转换为需要的`sparse_set<Entity,Type>`类型.

由于`sparse_set<Entity>`析构函数并不是虚方法(设计考虑),这里还提供了`destory`来销毁对应 Entity 的 Component 数据,并提供`clone`方法来完成复制动作.

最终在`basic_registry<Entity>`中以如下形式存储了所有 Component:

```C++
std::vector<pool_data> pools;
```

## 获取 Component 存储

在`basic_registry<Entity>`中针对 Component 的操作首先就要获取对应的`pool_data`,以下是其实现:

```C++
template<typename Component>
auto * assure() {
    const auto ctype = type<Component>();
    pool_data *pdata = nullptr;

    if constexpr(is_named_type_v<Component>) {
        const auto it = std::find_if(pools.begin()+skip_family_pools, pools.end(), [ctype](const auto &candidate) {
            return candidate.runtime_type == ctype;
        });

        pdata = (it == pools.cend() ? &pools.emplace_back() : &(*it));
    } else {
        if(!(ctype < skip_family_pools)) {
            pools.reserve(pools.size()+ctype-skip_family_pools+1);

            while(!(ctype < skip_family_pools)) {
                pools.emplace(pools.begin()+(skip_family_pools++), pool_data{});
            }
        }

        pdata = &pools[ctype];
    }

    if(!pdata->pool) {
        pdata->runtime_type = ctype;
        pdata->pool = std::make_unique<pool_type<Component>>();

        pdata->clone = +[](const sparse_set<Entity> &cpool) -> std::unique_ptr<sparse_set<Entity>> {
            if constexpr(std::is_copy_constructible_v<std::decay_t<Component>>) {
                std::unique_ptr<sparse_set<Entity, std::decay_t<Component>>> ptr = std::make_unique<pool_type<Component>>();
                *ptr = static_cast<const sparse_set<Entity, std::decay_t<Component>> &>(cpool);
                return std::move(ptr);
            } else {
                ENTT_ASSERT(false);
                return nullptr;
            }
        };

        pdata->destroy = [](basic_registry &registry, const Entity entt) {
            registry.pool<Component>()->destroy(registry, entt);
        };
    }

    return static_cast<pool_type<Component> *>(pdata->pool.get());
}
```

在 entt 中类型是可以为其提供编译期名称的,具体实现方式参考之前的编译期字符串哈希,因而`pool_data`的创建不太一样:

1. 获取 Component 类型 ID
2. 如果是命名类型,则会从特定位置开始查找,查找不到就追加
3. 如果非命名类型,则会将 ID 范围内的`pool_data`全部创建,然后获取位置
4. 根据情况初始化`pool_data`,创建对应的存储块
5. 将其转换为对应的 Component 存储

之后就可以基于 Component 的存储进行 Component 进行相关操作了,entt 中提供了大量迭代器使其可以按照 STL 容器的方式进行操作.

## 总结

采用稀疏集合,以及类型 ID 生成,综合使用继承等特性,即可实现操作效率很高,内存占用也较小的 Component 存储.这个对于需要处理不同类型的数据,同时要求很高性能的场景,可以考虑使用相同的设计思路.
