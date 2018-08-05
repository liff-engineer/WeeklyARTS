# [238. Product of Array Except Self](https://leetcode.com/problems/product-of-array-except-self/description/)

这个题目非常有意思,我在做的过程中暴露了自己思维的盲点:如何在过程中记录足够的信息,最终拼出想要的结果?

## 问题描述

给定一组大于1的整数,生成一组整数,要求在位置`i`处的整数是其它所有整数的乘积,要求不能用除法且复杂度为O(n).

## 用除法的解决办法

用除法的话解决起来非常简单,第一次循环取得所有整数的乘积,然后第二次循环除去相应位置的值即可:

```C++
//如果使用乘法来做 复杂度 2n
std::vector<int> results(nums.size(), 1);
int tmp=1;

//第一次循环得到总的乘积
for (int i = 0; i < nums.size(); i++) {
    tmp *= nums[i];
}

//第二次循环做除法得到具体值
for (int i = 0; i < nums.size(); i++) {
    results[i] = tmp / nums[i];
}
return results;
```

## 不用除法如何解?

这个题目有意思的地方在于解决这个题目,思路是非常明确的,如果你之前没有类似的经验,可能挠破头皮也很难解决!

不用除法且复杂度为O(n),就决定了你只能使用有限的循环次数,从左到右一次、从右到左一次,这两次就要把所需信息全部记录下来,或者说得到结果。

假设数组是`a,b,c,d,e`,那么想要的结果是`b*c*d*e,a*c*d*e,a*b*d*e,a*b*c*e,a*b*c*d`,从左到右的循环能够拿到什么?:`a,a*b,a*b*c,a*b*c*d,a*b*c*d*e`

现在,根据第一次循环能够获得的结果和预期结果比较,还需要什么信息?:`b*c*d*e,c*d*e,d*e,e,1`。

这时可以看到,所需要的信息从右向左即可得到.

## 解决方案

假设数组是`a,b,c,d,e`,可以通过两次不同方向的循环得到充足的信息:

|循环 |a     | b | c | d | e |
|:--:  |:--:     |:--:|:--:|:--:|:--:|
|从左到右|1   | `1*a` | `1*a*b` | `1*a*b*c` | `1*a*b*c*d`|
|从右到左|`b*c*d*e*1` | `c*d*e*1` | `d*e*1` | `e*1` | `1`|

实现如下:

```C++
//假设a,b,c,d,e,f
//第一次正向循环:1        ,      a,a*b  ,a*b*c,a*b*c*d,a*b*c*d*e
//第二次反向循环:b*c*d*e*f,c*d*e*f,d*e*f,e*f  ,f      ,1

std::vector<int> results(nums.size(),1);             
for (int i = 1; i < nums.size(); i++) {
    results[i] = results[i - 1] * nums[i - 1];
}
int right = 1;
for (int i = nums.size()-1; i >= 0; i--) {
    results[i] *= right;
    right *= nums[i];
}
return results;
````

## 后记

这个题目从上周开始做,没有做出来,这周依然没有做出来,无奈看了下`Discuss`;实际上复盘一下,并不是说没有过类似的经验就想不到,而是没有恰当的解题方法.

这种限定比较明显的题目,完全可以从已知条件和预期结果,以及可采用的方式推算出如何解决,深感基础不行,是时候再读读初中水平的《怎样解题》了。