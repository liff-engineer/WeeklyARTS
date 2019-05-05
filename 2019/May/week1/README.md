# Weekly ARTS

- 什么时候不使用 ECS?
- C++中的修饰器模式
- "算法=逻辑+控制"

## Algorithm [101. Symmetric Tree](https://leetcode.com/problems/symmetric-tree/)

给定二叉树,检查其是否是自身的镜像.

可以理解为给定左右两个树,比较对象为:

- 树自身的值是否相等
- 左树的左子树与右树的右子树是否相等
- 左树的右子树与右树的左子树是否相等

递归比较最为简单直接:

```C++
bool isSymmetric(TreeNode* left,TreeNode* right)
{
    if(left == nullptr && right == nullptr)
        return true;
    if(left != nullptr && right != nullptr)
    {
        if(left->val != right->val)
            return false;

        return (isSymmetric(left->left,right->right)) && (isSymmetric(left->right,right->left));
    }
    return false;
}
bool isSymmetric(TreeNode* root) {
    if(root == nullptr) return true;
    return isSymmetric(root->left,root->right);
}
```

## Review [什么时候不使用 ECS?](when_not_ecs.md)

## Technique [C++中的修饰器模式](decorator.md)

## Share "算法=逻辑+控制"

皓哥在《编程的本质》中提到"Algorithm=Logic+Control",并重点强调了:

> 有效地分离 Logic、Control 和 Data 是写出好程序的关键所在!

我在这里尝试着拿示例来描述自己对于这个的理解.

比如 C++的排序算法,`std::sort`,我们该如何理解其中的逻辑和控制呢?

排序必须要有依据,即数据之间的大小如何判断,在`std::sort`里表现形式就是`Compare`.我们可以有各种各样的排序实现,无论是冒泡排序、归并排序、插入排序等等,也可以是并行执行或者串行执行,但是这个数据之间大小的判断是不变的.这个就是`Logic`.

我们用算法来完成某件事情,可能有各种各样的实现方式,每个开发者选择都会不一样,但是,这件事的目标不会变,问题的本质不会变,即`Logic`不会变,会变化的是`Control`.这个`Logic`可以理解为业务,进行排序操作的目标是使数据变得有序,那么有序就是业务上的定义,何为有序? 你总有个界定标准,譬如值之间哪个大哪个小,这部分内容就是我们根据业务定义的逻辑,无论采用什么方式来实现,都是要基于这个逻辑来做.我们的实现多种多样,逻辑不会变.

又或者说动态规划算法,这个算法的核心在于找到重叠子问题,这部分就是`Logic`所在,隐藏在问题背后的客观规律.而如何围绕这个`Logic`来实现算法,则属于`Control`的部分.

如果以算法都是处理数据的视角来看,我们可以有如下形式:

```txt
y=f(x)
```

其中`x`和`y`是数据,而`f`即逻辑.可以这么理解,无法在该公式里表达的内容就是`Control`.

## TODO

- [Isn't an Entity-Component System terrible for decoupling/information hiding?](https://softwareengineering.stackexchange.com/questions/372527/isnt-an-entity-component-system-terrible-for-decoupling-information-hiding)

- [Entities, components and systems](https://medium.com/ingeniouslysimple/entities-components-and-systems-89c31464240d)
