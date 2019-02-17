# Weekly ARTS

- Qt 与 CMake

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

## Share

## TODO

- [cxx-pflR1 The Pitchfork Layout (PFL)](https://api.csswg.org/bikeshed/?force=1&url=https://raw.githubusercontent.com/vector-of-bool/pitchfork/develop/data/spec.bs)
