# VcUser - 如何实现指定规则的资源文件同步

## 目标

应用程序中通常会有资源文件、配置文件等等,通常打包或者运行时需要其与构建结果在相同路径,而且这些文件同样需要被svn、git等源代码管理工具,如果混杂在一起,修改后提交时也要小心。

假设源代码目录结构如下：

```TXT
example.sln
project1
    project1.vcxproj
    resource
        ...
project2
    project2.vcxproj
    resource
        ...
resource
    ...
```

其中`resource`文件夹下的所有文件都需要打包到输出目录来保证构建结果正常运行,而且打包时无需特殊处理.

那么我们将以这个场景实现自动同步resource下文件到输出目录。

## 解决方案

资源文件的同步以下问题：

- 同步时机
- 同步内容
- 如何同步

### 如何处理同步时机

假设要在构建之后进行同步,则可以定义`Target`如下:

```XML
<!-- 复制资源到目标路径 -->
<Target Name="VcUser_sync_resources" AfterTargets="AfterBuild">
</Target>
```

这时`MSBuild`会在执行完构建后触发`VcUser_sync_resources`,VC++工程会提供的一些默认`Target`,而自己声明的`Target`也可以依赖。

### 如何构造同步内容

假设要同步整个目录结构,可以实现如下:

```XML
<PropertyGroup Label="VcUser_resources_location">
    <VcUserSolutionResourcePath>$(SolutionDir)\resource\</VcUserSolutionResourcePath>
    <VcUserProjectResourcePath>$(ProjectDir)\resource\</VcUserProjectResourcePath>
</PropertyGroup>

<ItemGroup>
    <VcUserSolutionItems Include="$(VcUserSolutionResourcePath)\**\*.*" />
    <VcUserProjectItems Include="$(VcUserProjectResourcePath)\**\*.*" />
</ItemGroup>
```

注意使用目录加上`**\*.*`即可得到目录下所有的文件,路径信息作为数组存储,譬如`example.sln`同目录的`resource`下所有文件都保存在`@(VcUserSolutionItems)`之中。

### 如何实现资源同步

`MSBuild`脚本中的`Copy`即是完成文件复制动作,对于上述内容的同步,可以以如下方式实现:

```XML
<Copy SourceFiles="@(VcUserSolutionItems)" DestinationFolder="$(OutDir)\%(RecursiveDir)"  SkipUnchangedFiles="true" />
<Copy SourceFiles="@(VcUserProjectItems)" DestinationFolder="$(OutDir)\%(RecursiveDir)"  SkipUnchangedFiles="true" />
```

## 存在的问题

虽然资源同步时跳过了未变化的文件,但是构建时依然有耗时,我们是针对工程配置的,因而每个工程构建均会执行上述动作,这明显不是必须的;这里需要针对特定工程或者场景来触发对应的同步动作,譬如指定某个工程构建时触发资源同步,控制方式如下：

```XML
<VcUserSyncResEnable>false</VcUserSyncResEnable>
<VcUserSyncResEnable Condition="'$(ProjectName.ToLower())'=='project1'">true</VcUserSyncResEnable>
```

然后使用这个标志来控制`Target-VcUser_sync_resources`使能:

```XML
<Target Name="VcUser_sync_resources" AfterTargets="AfterBuild" Condition="'$(VcUserSyncResEnable)'=='true'">
</Target>
```

不过这种方案会存在需要专门配置的情况,与我们追求的"零配置"有些差距。

## 总结

通过使用MSBuild脚本的一些功能即可实现特定规则下的资源文件同步,来免除资源文件处理的烦扰,而且不污染源代码目录,进行打包时也较为简单。