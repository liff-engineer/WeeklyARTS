# Weekly ARTS

- Qt 与 CMake
- C++已经保证向后兼容了,你们却还过得如此艰难

## Algorithm [599. Minimum Index Sum of Two Lists](https://leetcode.com/problems/minimum-index-sum-of-two-lists/)

本周轻松一下,做一个`easy`的题目.

假设有两个字符串数组,找出其中相同的字符串,要求这些字符串的索引之和最小.

解决思路如下:

1. 使用`map`记录字符串及其索引的映射
2. 遍历第二个数组,从`map`查找是否有相同的,求出索引之和
3. 如果索引之和比之前的小,则重新记录
4. 如果索引之和与之前的相同,则追加

实现如下:

```C++
vector<string> findRestaurant(vector<string>& list1, vector<string>& list2) {
    std::map<std::string,std::size_t> map;
    for(auto i = 0ul;i<list1.size();i++){
        map[list1[i]]=i;
    }

    std::size_t sum = 2000;//题目称每个数组不大于1000,则索引之和小于2000
    std::vector<std::string> results;
    for(auto i = 0ul;i<list2.size();i++){
        auto it = map.find(list2[i]);
        if( it != map.end())
        {
            auto v = i+it->second;
            if(v == sum){
                results.push_back(it->first);
            }
            else if(v < sum){
                results.clear();
                results.push_back(it->first);
                sum = v;
            }
        }
    }
    return results;
}
```

提交之后发现属于效率较低的,难不成不能利用`map`? 那试试`unordered_map`吧:

```C++
    std::unordered_map<std::string,std::size_t> map;
    for(auto i = 0ul;i<list1.size();i++){
        map[list1[i]]=i;
    }

    std::size_t sum = 2000;//题目称每个数组不大于1000,则索引之和小于2000
    std::vector<std::string> results;
    for(auto i = 0ul;i<list2.size();i++){
        auto it = map.find(list2[i]);
        if( it != map.end())
        {
            auto v = i+it->second;
            if(v == sum){
                results.push_back(it->first);
            }
            else if(v < sum){
                results.clear();
                results.push_back(it->first);
                sum = v;
            }
        }
    }
    return results;
}
```

跑出来的结果处于百分之九十多的层次.这就能理解了为什么建议如果不在乎顺序,在`map`,`set`,`unordered_map`,`unordered_set`这些容器中优选选择`unordered_xx`等使用哈希实现的容器了.

## Review

## Technique [Qt 与 CMake](QtVsCMake.md)

## Share C++已经保证向后兼容了,你们却还过得如此艰难

据说公司升级编译器和 Qt 版本在平台层面搞了一年时间,直至今年才可以在产品中使用.

不能理解,完全不能理解...

C++不是 Python,没有 Python 2.x 和 Python 3.x 这种不兼容的分叉.C++保证后向兼容, 代码都不用改,是什么阻止了你们升级编译器?

我探索了一下,问题可能出在两个方面:

1. 分支/版本管理
2. 构建流程

升级了编译器,要建立新的分支,涉及到各种依赖,需要同步处理,如果第三方依赖没有良好的管理方式,可能无法轻易切换.针对版本管理如果没有良好的实践,可能也算是一团乱麻吧.

构建流程也是问题,据我所知,提供 UI 公共组件的团队使用的是 Qt Creator,使用 QMake 来构建;其它大部分团队使用 Visual Studio,使用 MSBuild 来构建.而针对库依赖的管理采用的是相对目录.部分团队有意识地在使用 Conan 进行库依赖管理.

我一直在使用 Visual Studio,之前比较倾向于使用 vcpkg 做库依赖管理.而最近了解到"Modern CMake"后,我对这些事情的看法有所改变.

无论你有多讨厌"CMake",它作为 C++在构建方面的"事实标准",都应该去了解,去应用,而不是随心所欲,走向分裂.

之前有谈到 vcpkg 和 conan 的设计哲学方面的分歧.在这个应用场景下,我欣赏 vcpkg,我认为这才是解决之道.vcpkg 作为库管理工具,如果你使用 CMake 作为构建脚本,是可以完全以 CMake 的方式来使用的,只需要修改一下 CMake 的`CMAKE_TOOLCHAIN_FILE`,然后`find_package`即可.而 conan 采用的却是侵入式的做法,其设计哲学会导致分裂.

另外我们应当为项目提供 CMake 构建,从而避免与特定的开发环境进行绑定,要知道 Visual Studio 的工程文件会绑定构建工具集和平台,其对 Qt 的支持也是很糟糕(这个也不能算 VS 的问题).Qt 已经废弃了 qbs,之后会将精力集中在 CMake 和 QMake 之上.Visual Studio 目前可以直接支持 CMake 工程.

如果采用"Modern CMake"的方式,并约定项目的布局,在开发流程上走向统一,我不认为升级编译器以及第三方库依赖有多艰难.就像大家都在说 C++越来越复杂,在我看来,从常规角度来讲,C++反而是简单化了,就看你愿不愿意走向"Modern C++"了.

## TODO

- [cxx-pflR1 The Pitchfork Layout (PFL)](https://api.csswg.org/bikeshed/?force=1&url=https://raw.githubusercontent.com/vector-of-bool/pitchfork/develop/data/spec.bs)
