# Weekly ARTS

面向数据设计以及 ECS 主题

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

## Review

## Technique

## Share

## TODO
