# Algorithm [16. 3Sum Closest](https://leetcode.com/problems/3sum-closest/description/)

## 问题描述

有一个整数数组`nums`,以及一个整数`target`,从整数数组中找出三个整数,其和与`target`最为接近,返回其和。

## 无脑解法

三层循环求和,记录与目标最接近的和

```C++
int threeSumClosest(vector<int>& nums, int target) {
    int result = std::numeric_limits<int>::max();
    int size = nums.size();
    for (int i = 0; i < size-2; i++) {
        for (int j = i+1; j < size - 1; j++) {
            for (int k = j+1; k < size; k++) {
                auto sum = nums[i] + nums[j] + nums[k];
                auto dv = sum - target;
                if (std::fabs(dv) < std::fabs(result)) {
                    result = dv;
                }
            }
        }
    }
    return (target + result);
}
```

## 排序后查找

上面的解法复杂度为n^3,因为要循环3遍才能得到结果,所以我想到通过排序,然后使用二分查找法来降低最内层循环次数：

```C++
//从小到大,二分法查找
int binary_search(std::vector<int>& nums, int low, int high, int target) {
    int mid = (low + high) / 2;
    //无法再细分,就返回当前索引
    if (mid == low || mid == high) return mid;
    auto v = nums[mid];
    if (v > target) {
        return binary_search(nums, low, mid, target);
    }
    return binary_search(nums, mid, high, target);
}
int threeSumClosest(vector<int>& nums, int target) {
    std::sort(std::begin(nums), std::end(nums));

    int size = nums.size();
    int result = std::numeric_limits<int>::max();
    for (int i = 0; i < size - 2; i++) {
        for (int j = i + 1; j < size - 1; j++) {
            int tv = target - nums[i] - nums[j];
            int idx = binary_search(nums, j + 1, size - 1, tv);
            //当前值,及左右两个值
            if (idx > (j + 1)) {
                int dv = tv - nums[idx - 1];
                if (std::fabs(dv) < std::fabs(result)) {
                    result = dv;
                }
            }
            {
                int dv = tv - nums[idx];
                if (std::fabs(dv) < std::fabs(result)) {
                    result = dv;
                }
            }

            if (idx < size - 1) {
                int dv = tv - nums[idx + 1];
                if (std::fabs(dv) < std::fabs(result)) {
                    result = dv;
                }
            }
        }
    }
    return (target - result);
}
```

结果还是不太理想,毕竟外部有两层循环,复杂度为n^2,即使二分查找为log n,如何将三层循环缩减为二层循环?

## 排序后两端查找

虽然明白要减少循环次数,但是一时想不明白如何减少,查阅`Discuss`后才明白：
>
> 设置起始和结束两个游标,利用已排序特性,将求出的和与目标对比,如果比目标小则起始游标后移,否则结束游标前移
>
这样内层的两层循环被缩减为一层：

```C++
int threeSumClosest(vector<int>& nums, int target) {
    std::sort(std::begin(nums), std::end(nums));

    int result = std::numeric_limits<int>::max();
    int size = nums.size();
    for (int i = 0; i < size - 2; i++) {
        int begin = i + 1;
        int end = size - 1;
        while (begin < end) {
            int sum = nums[i] + nums[begin] + nums[end];
            if (sum > target) {
                end--;
            }
            else {
                begin++;
            }
            if (std::fabs(sum - target) < std::fabs(result - target)) {
                result = sum;
            }
        }
    }
    return result;
}
```

## 后记

这个题目考察的内容也比较简单,就是如何减小循环次数,需要借用已排序特性来恰当地将两层循环展开成一层;还是理解得不太透彻,不清楚如何展开。
