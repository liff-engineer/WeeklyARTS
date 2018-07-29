# Weekly ARTS

## Algorithm [652. Find Duplicate Subtrees](https://leetcode.com/problems/find-duplicate-subtrees/description/)

### 问题描述

从一个二叉树中找出来重复的子树,要求值及结构重复.

### 处理思路

这个要查找重复的子树,肯定要对子树进行比对,如果拿出所有的子树进行比对肯定在算法层面上不现实;

如果将子树能够在遍历过程中转换成某种特征,那么只需要遍历时比对并记录相同特征的子树root即可;

可以参考树的序列化操作,将树转换成字符串标识,遍历过程将字符串和对应的子树记录下来,最后统计出所有重复的字符及子树,即可得到要求的结果。

### 第一次尝试

刚开始的实现思路是遍历是从顶向下,需要根据子树遍历链修改所有的字符串表示:

```C++
void  serialize(TreeNode* root,std::vector<TreeNode*> stack, std::unordered_map<TreeNode*, std::string>& identifys)
{
    if (root == nullptr) {
        for (auto node : stack) {
            identifys[node].append("\n");//NULL标识
        }
        return;
    }

    stack.push_back(root);
    std::string result = std::to_string(root->val) + "\n";
    for (auto node : stack) {
        identifys[node].append(result);
    }

    serialize(root->left, stack, identifys);
    serialize(root->right, stack, identifys);
}

vector<TreeNode*> findDuplicateSubtrees(TreeNode* root) {
    std::unordered_map<TreeNode*, std::string> identifys;
    std::vector<TreeNode*> stack;
    serialize(root, stack, identifys);

    std::unordered_map<std::string, std::vector<TreeNode*>> items;
    for (auto identify : identifys) {
        items[identify.second].push_back(identify.first);
    }

    std::vector<TreeNode*> results;
    for (auto item : items) {
        if (item.second.size() < 2)
            continue;
        results.push_back(item.second.front());
    }
    return results;
}
```

### 使用hash的方式

采用上述方式面临的问题是大批量的字符串操作,可能这样会引起性能问题,因而调整成过程中记录hash值：

```C++
template<class T>
inline void hash_combine(std::size_t& seed, const T& v) {
    std::hash<T> hasher;
    seed ^= hasher(v) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
}

void  serialize(TreeNode* root, std::vector<TreeNode*> stack, std::unordered_map<TreeNode*, std::size_t>& identifys)
{
    if (root == nullptr) {
        for (auto node : stack) {
            hash_combine(identifys[node], std::numeric_limits<int>::min());
        }
        return;
    }

    stack.push_back(root);
    for (auto node : stack) {
        hash_combine(identifys[node], root->val);
    }

    serialize(root->left, stack, identifys);
    serialize(root->right, stack, identifys);
}


vector<TreeNode*> findDuplicateSubtrees(TreeNode* root) {
    std::unordered_map<TreeNode*, std::size_t> identifys;
    std::vector<TreeNode*> stack;
    serialize(root, stack, identifys);

    std::unordered_map<std::size_t, std::vector<TreeNode*>> items;
    for (auto identify : identifys) {
        items[identify.second].push_back(identify.first);
    }

    std::vector<TreeNode*> results;
    for (auto item : items) {
        if (item.second.size() < 2)
            continue;
        results.push_back(item.second.front());
    }
    return results;
}
```

### 正确的解决方法

虽然思路上面没有问题,但是在实现方法上是有问题的,虽然实现上采用了递归方式,但是并没有抓住递归的精髓：递归是从顶向下然后再返回顶,也就是说能够从低到顶返回子树的字符串表示,过程中并不需要记录`stack`和遍历需改父节点的字符串表示。

## Reivew [模板元编程:迭代比递归要好](TMP_Iteration.md)

C++11引入的可变参数模板使得模板元编程从表达方式到性能都有所改变,文中以类型filter为例,来对其实现进行解析,让我们感受到元编程的魅力。

## Technique [关乎性能的std::string_view](string_view.md)

无论是历史原因还是性能考量,在C++中字符串的表达和处理都相对非常多样化,这也导致字符串在接口层面和使用时情况复杂,C++17引入了`std::string_view`来试图解决性能和接口层次的问题,C++中的字符串处理相对会简化许多。

## Share 你愿意与人多沟通么

这周四在slack的*#cpp*里聊了聊C++20的`contracts`,讲了讲它的目的、方法和影响,群组里十几号人,最后只有1个人简单的聊了一句,我对此有些困惑:如果是有人跟我将有个特别好的东西,我多少会去了解了解,也希望能有人一起探讨一下,为什么最终是这样的效果?

凡事先反思下自己,什么情况下我不愿意与人沟通?

- 聊的东西没有意义、价值
- 不感兴趣或者跟自己没有关系
- 手头有更重要的事情要做
- 已经非常了解,没有再讨论的价值
- 不愿意与人沟通

我个人大部分情况下是不愿意与人沟通的,有种自视甚高的意思在,不知道这是不是做技术的特点。

最近忙装修,跟装修公司的设计师聊,跟朋友聊,基本上每次都能得到一些新的想法或者说之前没有想到的问题,受益良多。

所以我对沟通的看法也一点点发生变化,不排斥与人沟通,在部分情况下积极主动一些是没有什么坏处的。