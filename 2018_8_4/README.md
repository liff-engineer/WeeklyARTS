# Weekly ARTS

- 回溯法的概念及实现“套路”,针对回溯法题目的专项练习
- C++标准提案P0534R3解读
- 如何获取C++类型的字符串表示
- 对Qt等开发工具的一些看法

## Algorithm [回溯法01](Backtracking01.md)

上周做了个8皇后的题目,实现比较糟糕,过程中感受到了回溯法的“魅力”,这次及后续将针对回溯法这种算法来多多练习与总结。

## Reivew [call/cc](P0534R3Review.md)

聊一聊我对C++标准提案`call/cc (call-with-current-continuation`的理解。

## Technique [如何获取C++类型的字符串表示](ExploringCppTypes.md)

C++相比其它语言缺少反射机制,那么需要获取类型对应的字符串表示该如何去做?这里展示了几种方法。

## Share 对开发人员也要讲用户体验

最近要做一些界面相关的工作,用到了Qt,因为习惯用Visual Studio,使用第三方库时就用了[Vcpkg](https://github.com/Microsoft/vcpkg)来管理第三方库,万万没想到灾难开始.....

刚开始`vcpkg install qt5-base`,之后开始用`QGraphicsView`,一切都很美好,不需要操心Qt版本的选择、下载与安装,也不用配置头文件、库路径、`QTDIR`,只需要编码、编译、运行,输出目录就可以直接打包给别人。

当需要使用Qt的信号与槽,一切都变得糟糕起来了,`Vcpkg`只是库管理工具,Qt配套的moc、uic均是独立工具,要整合到VisualStudio中对特定源代码进行moc操作,虽然有[Qt VS Tools](https://doc.qt.io/qtvstools/index.html)来简化操作,但是它不能识别Vcpkg安装出来的Qt,搜索了一下,看到[support for Qt VS Tools?](https://github.com/Microsoft/vcpkg/issues/2643)中的解决方案也不管用,经过半天的摸索,模仿Qt安装版本目录结构,终于将[Qt VS Tools](https://doc.qt.io/qtvstools/index.html)和Vcpkg中的Qt版本配置好了,但是我原先的工程是用Visual Studio创建的,[Qt VS Tools](https://doc.qt.io/qtvstools/index.html)不识别! 幸亏哥们我练过,[How to convert a regular win32 (VC++ vcproj) project to a Qt project?](https://stackoverflow.com/questions/2088315/how-to-convert-a-regular-win32-vc-vcproj-project-to-a-qt-project).

至此,一天已经过去了,不知道中间犯了那些错误,我Visual Studio和Qt都用了数年之久,对MSBuild也是烂熟于胸,Vcpkg实现都分析过,依然碰到这么多困难。

除了埋怨自己为啥"不走寻常路",同时我也对这些开发工具深深地不爽,尤其是Qt,不可否认其优点和便利性,但是moc这种玩意?  你要说C++不争气吧,C++/WinRT可纯粹是标准C++啊,更何况还有项目将moc替换成模板实现的。

我相信我在其上浪费的时间还算少的,而且也解决了碰到的问题,更多的人可能浪费了更多的时间,问题最终也没得到解决;这种非常糟糕的用户体验,如果不是熟悉Qt,我是非常不愿意再使用它.

虽然开发人员要对自己要求高一点,能够手写makefile,解决各种碰到的问题,还要有深入的了解,但是我的看法,没有必要在这些东西上浪费过多时间,这种折腾不是乐趣,就如以前用Andorid手机乐趣在刷机,现在谁还在刷?用苹果不好么? 给开发人员用的工具也要有用户体验的考量,用得爽,让开发人员专注于实现价值。