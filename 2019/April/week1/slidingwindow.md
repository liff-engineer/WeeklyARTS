# [480. Sliding Window Median](https://leetcode.com/problems/sliding-window-median/)

题目要求计算滑动窗口形式的中位数.中位数指的是有序整数序列的中间值.如果序列为偶数,是没有中位数的,那么这个中位数可以取两个中间值的平均值.

给定数组`nums`,这里有一个大小为`k`的滑动窗口,滑动窗口从数组的左侧移动到右侧,每次移动一个位置.你只能看到在滑动窗口的`k`个数,而你的任务就是找到其中位数数组.

## 解决思路

在了解什么是滑动窗口后,我的解决方法如下:

1. 获取滑动窗口
2. 排序并获取中位数
3. 用新值替换旧值

因为不知道如何在保持滑动窗口有序的状况下替换旧值,这里就先糙快猛了.

## 初步实现

```C++
vector<double> medianSlidingWindow(vector<int>& nums, int k) {
    std::vector<double> results;
    std::vector<int> windows(nums.begin(), nums.begin() + k);
    std::sort(windows.begin(), windows.end());

    std::function<double()> fetch = [&]() -> double { return windows.at(k / 2); };
    if (k % 2 == 0)
        fetch = [&]() -> double { return (windows.at(k / 2 - 1)*1.0 + windows.at(k / 2)*1.0) / 2.0; };

    results.push_back(fetch());
    for (auto i = 0; i < static_cast<int>(nums.size()) - k; i++)
    {
        //修改上一次的元素
        auto it = std::find(windows.begin(), windows.end(), nums[i]);
        *it = nums[i + k];
        std::sort(windows.begin(), windows.end());
        results.push_back(fetch());
    }
    return results;
}
```

在处理完各种边边角角的状况后,错误是处理完了,但是运行时直接超时,头疼.

## 调整思路

上述实现,在替换旧值得过程中,会进行查找和排序动作.如果采用有序容器,则会使排序动作的耗时大大降低,但是我找不到什么方式可以在采用有序容器的状态下能够简单地获取中位数.

在`Discuss`中有用优先级队列来实现的,但是思路比较难懂,而且 C++中无对应实现.而另外一个 C++的实现思路很有趣,使用`multiset`来作为有序容器存储滑动窗口,同时使用迭代器来很方便地获取中位数.

`set`与`multiset`保存了键,并根据键进行排序,内部用`map`实现,只要迭代器不被移除,过程中一致保持有效.正好我们要获取中位数,在新值替换旧值得过程中,可以移动中位数的迭代器来保证后续可以很方便地获取中位数.

## 具体实现

```C++
vector<double> medianSlidingWindow(vector<int>& nums, int k) {
    std::vector<double> results;
    std::multiset<int> window(nums.begin(), nums.begin() + k);
    auto mid = std::next(window.begin(), k / 2);
    for (auto i = k;; i++)
    {
        results.push_back(
            (static_cast<double>(*mid) + *std::prev(mid, 1 - k % 2)) / 2);

        if (i == nums.size())
            return results;

        window.insert(nums[i]);
        if (nums[i] < *mid)
            mid--;
        if (nums[i - k] <= *mid)
            mid++;
        window.erase(window.lower_bound(nums[i - k]));
    }
    return results;
}
```

这里利用了 C++中迭代器的特性来快速获取中位数,又利用了中位数以及`set`的特征,根据新值和旧值与中位数的比较,来移动迭代器.其行为如下：

- 我们知道`set`默认从小到大排序
- 如果新值小于中位数,则增加新值之后,中位数可能会变小,需要向前移动
- 如果旧值小于中位数,则替换掉旧值之后,中位数可能会变大,需要向后移动
- 在新值替换旧值得过程中,`set`会自动排序,而我们记录的中位数可以根据其特性进行上述动作,从而避免查找

在之前我都尽可能避免直接操作迭代器,因为迭代器面临失效的可能性,上述实现也让我开了眼,之前对迭代器的理解还是太肤浅.

## 总结

滑动窗口在实时数据处理方面大有用处,可以好好学习学习.
