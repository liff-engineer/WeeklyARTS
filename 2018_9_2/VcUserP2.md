# VcUser - 如何实现构建结果配置

## 目标

Visual Studio在默认情况下会将Win32的构建结果定位到解决方案文件夹下,而把x64的构建结果定位到解决方案文件夹下x64子文件夹里,并且将中间文件输出到工程文件同目录,有时生成的结果名也并不是我们想要的。

在一个大型的项目里,有几十上百个工程,如果一个个调整其输出目录,一旦后期有修改,或者不按照规范来,就会让人痛苦不堪;而临时文件生成到工程文件同目录,提交代码时就要小心了.

## 存在的问题及想要的效果

假设我们的源代码目录结构如下:

```TXT
example.sln
project1
    project1.vcxproj
project2
    project2.vcxproj
```

一旦执行构建,就会变成如下结构

```TXT
Debug
Release
x64
    Debug
    Release
example.sln
project1
    Debug
    Release
    project1.vcxproj
project2
    Debug
    Release
    project2.vcxproj
```

那么如果默认要求如下:

```TXT
build
    Win32
        Debug
        Release
    x64
        Debug
        Release
temp
    Win32
        Debug
        Release
    x64
        Debug
        Release
example.sln
project1
    project1.vcxproj
project2
    project2.vcxproj
```

那么如何实现解决方案每个工程均以此结构进行配置?

## 如何实现

- 输出目录定义如下
> $(SolutionDir)build\$(Platform)\$(Configuration)\
- 中间目录定义如下
> $(SolutionDir)temp\$(Platform)\$(Configuration)\$(ProjectName)\

在`.targets`文件中以如下方式定义:

```XML
<PropertyGroup Label="VcUser_output_props">
    <VcUserOutputDirectory>$(SolutionDir)build\$(Platform)\$(Configuration)\</VcUserOutputDirectory>
    <VcUserIntermediateDirectory>$(SolutionDir)temp\$(Platform)\$(Configuration)\$(ProjectName)\</VcUserIntermediateDirectory>
</PropertyGroup>
```

然后调整输出目录和中间目录,在MSBuild & Visual C++里,输出目录为`$(OutDir)`,中间目录为`$(IntDir)`,由于我们的`.targets`文件是后加载的,输出文件不能识别新的配置,需要调整输出文件路径`$(TargetDir)`,以及输出结果`$(TargetPath)`:

```XML
<PropertyGroup>
    <TargetName>$(ProjectName)</TargetName>

    <OutDir>$(VcUserOutputDirectory)</OutDir>
    <IntDir>$(VcUserIntermediateDirectory)</IntDir>

    <TargetDir>$(OutDir)</TargetDir>
    <TargetPath>$(OutDir)$(TargetName)$(TargetExt)</TargetPath>
</PropertyGroup>
``` 

通过增加这些配置,即可达到之前所追求的效果,将输出目录和中间目录重定向到预定位置。
