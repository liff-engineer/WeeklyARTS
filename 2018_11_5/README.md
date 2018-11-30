# Weekly ARTS

## Algorithm

## Review

状态机这种东西还是得好好琢磨琢磨
[[Boost].SML: C++14 State Machine Library](https://github.com/boost-experimental/sml)

## Technique

C++17 fold expression的应用一则,需要学习学习这个特性.

```C++
#include <cstdlib>
#include <type_traits>

template<typename T, typename... Ts>
constexpr size_t get_index_in_pack() {
    // Iterate through the parameter pack until we find a matching type,
    // incrementing idx for each non-match. Short-circuiting of operator ||
    // on !++idx (always false) takes care of aborting iteration at the right
    // point
    size_t idx = 0;
    (void)((std::is_same_v<T, Ts> ? true : !++idx) || ...);
    return idx;
}

static_assert(get_index_in_pack<char,   char, size_t, int>() == 0);
static_assert(get_index_in_pack<size_t, char, size_t, int>() == 1);
static_assert(get_index_in_pack<int,    char, size_t, int>() == 2);
```

## Share

pybind11

## TODO

- [Copy semantics and resource management in C++](https://www.deleaker.com/blog/2018/11/20/copy-semantics-and-resource-management-in-cpp/)
- [Tiny cheatsheets for C++11/14/17](https://www.walletfox.com/course/cheatsheets_cpp.php)
- [A zero cost abstraction?](https://joshpeterson.github.io/a-zero-cost-abstraction)
- [CppCon 2018: Modern C++ Design](https://abseil.io/blog/20181129-moderncpp)
