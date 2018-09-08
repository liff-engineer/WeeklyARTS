# VcUser - 如何实现解决方案级配置

VcUser要实现"零配置",首先需要解决的就是如何扩展Visual Studio的默认配置。

## 能否实现

在Visual Studio中新建C++工程,那么C++标准库的库路径等等就无需配置了,也就是说Visual Studio针对每种工程都会导入默认配置;如果Visual Studio可以导入默认配置,那么只需要调整默认配置,来导入VcUser的配置入口即可.

## 测试示例

在Visual Studio新建example解决方案,然后添加console工程,写个`Hello VcUser`:

```C++
#include <iostream>

int main(int argc, char** argv) {
    std::cout << "Hello VcUser\n";
    return 0;
}
```

要测试的example.sln.targets文件内容为:

```XML
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Target Name="VcUserTester" BeforeTargets="Build">
    <Message Text="Hello VcUser" Importance="high"/>
  </Target>
</Project>
```

这个含义是在`Build`之前执行`Target:VcUserTester`,输出信息`Hello VcUser`.

## 方案1:调整Visual Studio工程默认配置

Visual Studio会导入`${MSBuildLocation}\${MSBuildVersion}\Microsoft.Common.targets\ImportBefore`文件夹下的`targets`文件,在这里判断如果解决方案下存在与解决方案同名但是扩展名为`.targets`的配置- `SolutionImporter.targets`:

```XML
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <Import Project="$(SolutionPath).targets" Condition="Exists('$(SolutionPath).targets')"/>
</Project>
```

当在命令行使用`MSBuild`构造`example.sln`后结果如下:

```TXT
C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example>msbuild example.sln
用于 .NET Framework 的 Microsoft (R) 生成引擎版本 15.8.168+ga8fba1ebd7
版权所有(C) Microsoft Corporation。保留所有权利。

在此解决方案中一次生成一个项目。若要启用并行生成，请添加“/m”开关。
生成启动时间为 2018/9/8 22:56:02。
节点 1 上的项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example.sln”(默认目标)。
ValidateSolutionConfiguration:
  正在生成解决方案配置“Debug|x64”。
项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example.sln”(1)正在节点 1 上生成“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example\example.vcxproj”(2) (默认目标)。
InitializeBuildStatus:
  正在创建“x64\Debug\example.tlog\unsuccessfulbuild”，因为已指定“AlwaysCreate”。
VcpkgTripletSelection:
  Using triplet "x64-windows" from "C:\Repositories\vcpkg\installed\x64-windows\"
ClCompile:
  所有输出均为最新。
Link:
  所有输出均为最新。
  example.vcxproj -> C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\x64\Debug\example.exe
AppLocalFromInstalled:
  C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -noprofile -File "C:\Repositories\vcpkg\scripts\buildsystems\msbuild\applocal.ps1" "C:\Users\Garfield\Documents\Visual Studio
  2017\Projects\example\x64\Debug\example.exe" "C:\Repositories\vcpkg\installed\x64-windows\debug\bin" "x64\Debug\example.tlog\example.write.1u.tlog" "x64\Debug\vcpkg.applocal.log"
FinalizeBuildStatus:
  正在删除文件“x64\Debug\example.tlog\unsuccessfulbuild”。
  正在对“x64\Debug\example.tlog\example.lastbuildstate”执行 Touch 任务。
VcUserTester:
  Hello VcUser
已完成生成项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example\example.vcxproj”(默认目标)的操作。

已完成生成项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example.sln”(默认目标)的操作。


已成功生成。
    0 个警告
    0 个错误

已用时间 00:00:00.53
```

在Visual Studio中构建example后结果如下:

```TXT
1>------ 已启动全部重新生成: 项目: example, 配置: Debug Win32 ------
1>main.cpp
1>example.vcxproj -> C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\Debug\example.exe
1>Hello VcUser
========== 全部重新生成: 成功 1 个，失败 0 个，跳过 0 个 ==========
```

可以看到这个方案是可行的,比较遗憾的是这种方法是未公开的,影响未知,而且需要以管理员权限复制`SolutionImporter.targets`到系统路径下。

## 方案2: 导入解决方案级配置

在解决方案所在目录提供`after.example.sln.targets`即可导入,将之前的`example.sln.targets`文件名修改为`after.example.sln.targets`,MSBuild即可识别,以下是命令行构建example.sln的输出:

```TXT
C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example>msbuild example.sln
用于 .NET Framework 的 Microsoft (R) 生成引擎版本 15.8.168+ga8fba1ebd7
版权所有(C) Microsoft Corporation。保留所有权利。

在此解决方案中一次生成一个项目。若要启用并行生成，请添加“/m”开关。
生成启动时间为 2018/9/8 23:04:46。
节点 1 上的项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example.sln”(默认目标)。
ValidateSolutionConfiguration:
  正在生成解决方案配置“Debug|x64”。
VcUserTester:
  Hello VcUser
项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example.sln”(1)正在节点 1 上生成“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example\example.vcxproj”(2) (默认目标)。
InitializeBuildStatus:
  正在创建“x64\Debug\example.tlog\unsuccessfulbuild”，因为已指定“AlwaysCreate”。
VcpkgTripletSelection:
  Using triplet "x64-windows" from "C:\Repositories\vcpkg\installed\x64-windows\"
ClCompile:
  所有输出均为最新。
Link:
  所有输出均为最新。
  example.vcxproj -> C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\x64\Debug\example.exe
AppLocalFromInstalled:
  C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -noprofile -File "C:\Repositories\vcpkg\scripts\buildsystems\msbuild\applocal.ps1" "C:\Users\Garfield\Documents\Visual Studio
  2017\Projects\example\x64\Debug\example.exe" "C:\Repositories\vcpkg\installed\x64-windows\debug\bin" "x64\Debug\example.tlog\example.write.1u.tlog" "x64\Debug\vcpkg.applocal.log"
FinalizeBuildStatus:
  正在删除文件“x64\Debug\example.tlog\unsuccessfulbuild”。
  正在对“x64\Debug\example.tlog\example.lastbuildstate”执行 Touch 任务。
已完成生成项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example\example.vcxproj”(默认目标)的操作。

已完成生成项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example.sln”(默认目标)的操作。


已成功生成。
    0 个警告
    0 个错误

已用时间 00:00:00.58
```

而如果在Visual Studio中构建example,输出如下：

```TXT
1>------ 已启动生成: 项目: example, 配置: Debug Win32 ------
1>main.cpp
1>example.vcxproj -> C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\Debug\example.exe
========== 生成: 成功 1 个，失败 0 个，最新 0 个，跳过 0 个 ==========
```

这种解决方案只能解决命令行使用MSBuild构造,而正常的Visual Studio构造则不能使用;另外这种操作只在Visual Studio 2015之后支持。

## 方案3: [Directory.Build.targets](https://docs.microsoft.com/en-us/visualstudio/msbuild/customize-your-build?view=vs-2017)

将`example.sln.targets`文件修改为`Directory.Build.targets`后,重新在命令行执行MSBuild构造,输出如下:

```TXT
C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example>msbuild example.sln
用于 .NET Framework 的 Microsoft (R) 生成引擎版本 15.8.168+ga8fba1ebd7
版权所有(C) Microsoft Corporation。保留所有权利。

在此解决方案中一次生成一个项目。若要启用并行生成，请添加“/m”开关。
生成启动时间为 2018/9/8 23:10:26。
节点 1 上的项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example.sln”(默认目标)。
ValidateSolutionConfiguration:
  正在生成解决方案配置“Debug|x64”。
项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example.sln”(1)正在节点 1 上生成“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example\example.vcxproj”(2) (默认目标)。
InitializeBuildStatus:
  正在创建“x64\Debug\example.tlog\unsuccessfulbuild”，因为已指定“AlwaysCreate”。
VcpkgTripletSelection:
  Using triplet "x64-windows" from "C:\Repositories\vcpkg\installed\x64-windows\"
ClCompile:
  所有输出均为最新。
Link:
  所有输出均为最新。
  example.vcxproj -> C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\x64\Debug\example.exe
AppLocalFromInstalled:
  C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -noprofile -File "C:\Repositories\vcpkg\scripts\buildsystems\msbuild\applocal.ps1" "C:\Users\Garfield\Documents\Visual Studio
  2017\Projects\example\x64\Debug\example.exe" "C:\Repositories\vcpkg\installed\x64-windows\debug\bin" "x64\Debug\example.tlog\example.write.1u.tlog" "x64\Debug\vcpkg.applocal.log"
FinalizeBuildStatus:
  正在删除文件“x64\Debug\example.tlog\unsuccessfulbuild”。
  正在对“x64\Debug\example.tlog\example.lastbuildstate”执行 Touch 任务。
VcUserTester:
  Hello VcUser
已完成生成项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example\example.vcxproj”(默认目标)的操作。

已完成生成项目“C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\example.sln”(默认目标)的操作。


已成功生成。
    0 个警告
    0 个错误

已用时间 00:00:00.61
```

通过Visual Studio来构建example输出如下:

```TXT
1>------ 已启动生成: 项目: example, 配置: Debug Win32 ------
1>main.cpp
1>example.vcxproj -> C:\Users\Garfield\Documents\Visual Studio 2017\Projects\example\Debug\example.exe
1>Hello VcUser
========== 生成: 成功 1 个，失败 0 个，最新 0 个，跳过 0 个 ==========
```

这种方案是可行的,不过可惜的是只能在MSBuild 15及以上版本运行,而且要求文件名必须为`Directory.Build.targets`.

## 对比

方案2是不可取的,方案3无法在低版本的Visual Studio上运行,因而采用方案1是目前最恰当的方案,但是其也有缺点,如果想要采用这种方式,必须首先将`SolutionImporter.targets`复制到指定目录。

## 解决方案

提供`VcUserRegister.targets`,内容如下:

```XML
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <Import Project="$(SolutionPath).targets" Condition="Exists('$(SolutionPath).targets')"/>
</Project>
```

提供`template.sln.targets`,内容如下:

```XML
<?xml version="1.0" encoding="utf-8" ?>
<Project  ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <PropertyGroup>
    <!-- 该文件位于.sln同级目录,需要将VcUserRootPath指定到VcUser内容目录 -->
        <VcUserRootPath Condition="'$(VcUserRootPath)' == ''">$(MSBuildThisFileDirectory)\VcUser</VcUserRootPath>
    </PropertyGroup>
    <Import  Condition="'$(VcUserRootPath)' != '' and Exists('$(VcUserRootPath).targets')" Project="$(VcUserRootPath).targets"/>
</Project>
```

将`VcUser`实现置于源代码目录的相对位置,然后修改`temnplate.sln.targets`执向`VcUser`目录,来导入`VcUser.targets`这个解决方案级配置。

下一篇将讲解如何写`VcUser.targets`来修改构建结果相关信息(构建结果名、输出路径等)。