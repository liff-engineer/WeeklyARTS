# Weekly ARTS

- entt 中 Component 的存储实现

## Algorithm [128. Longest Consecutive Sequence](https://leetcode.com/problems/longest-consecutive-sequence/)

题目要求给定未排序的整数数组,求出最长连续整数序列的长度.并且算法复杂度在`O(n)`.例如`nums={100,4,200,1,3,2}`,其中最长连续整数序列为`1,2,3,4`,即结果为`4`.

这种题目的解决思路是`Union-Find`.这里我们以`unordered_map<int,int> m`来存储元素以及对应的序列长度.则可以得出以下四种情况:

1. `m[v-1]`和`m[v+1]`都不存在,那么`m[v]`只能为`1`
2. 只有`m[v-1]`存在,则`m[v]=m[v-1]+1`,而序列左侧边界`m[v-m[v-1]`需要同步更新,即`m[v-m[v-1]]=m[v]`.
3. 只有`m[v+1]`存在,则`m[v]=m[v+1]+1`,而序列右侧边界`m[v+m[v+1]`需要同步更新,即`m[v+m[v+1]=m[v]`
4. 如果都存在,则`m[v]=m[v-1]+m[v+1]+1`,序列两侧边界均需要扩展.

根据上述情况,实现如下:

```C++
int longestConsecutive(vector<int>& nums) {
    std::unordered_map<int,int> m;
    auto result = 0;
    for(auto v:nums){
        //已经被设置过值,无需计算
        if(m[v])
            continue;
        auto p = m[v-1];//前一个值
        auto n = m[v+1];//后一个值
        if(p+n ==0) //前后都没有值
        {
            m[v]=1;
        }
        else if(p>0 && n > 0)//前后都有值
        {
            //连接起来
            m[v]=p+n+1;
            //左边界
            m[v-p]=m[v];
            //右边界
            m[v+n]=m[v];
        }
        else if(p > 0) //前一个有值
        {
            m[v]=p+1;
            //左边界
            m[v-p]=m[v];
        }
        else if(n > 0) //后一个有值
        {
            m[v]=n+1;
            m[v+n]=m[v];
        }
        result = std::max(result,m[v]);
    }
    return result;
}
```

可以将以上四种情况全部合并,得到实现为:

```C++
int longestConsecutive(vector<int>& nums) {
    std::unordered_map<int,int> m;
    auto result = 0;
    for(auto v:nums){
        //已经被设置过值,无需计算
        if(m[v])
            continue;
        result=std::max(result,m[v]=m[v-m[v-1]]=m[v+m[v+1]]=m[v-1]+m[v+1]+1);
    }
    return result;
}
```

## Review

## Technique [entt 中 Component 的存储实现](entt_component_storage.md)

## Share
