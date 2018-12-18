# Visual Studio中使用pybind11

pybind11是一个能够无缝衔接`C++`和`Python`的`C++`库.如何更为方便快捷地使用Visual Studio为`C++`代码提供`Python`绑定? 这里展示了之前`VcUser`的解决方案及配置方法来更为方便地使用`pybind11`.

## `pybind11`安装

这里可以使用[vcpkg](https://github.com/Microsoft/vcpkg),从`github`迁出之后只需以下操作:

```CMD
.\bootstrap-vcpkg.bat
.\vcpkg install pybind11 pybind11:x64-windows
```

但是需要注意的是,`vcpkg`上提供的`pybind11`设置了`python`依赖项,安装`pybind11`会安装`cpython`,这个在本机开发时,由于版本并不一样,所以可以将其移除,找到`vcpkg/ports/pybind11/CONTROL`文件,删除文件中的`Build-Depends: python3 (windows)`这行,然后安装`pybind11`即可.

## 准备`Python`

可以在本机上安装好`Python`,`win32`和`x64`本本都可以安装,不过同时在命令行只能运行一个版本.在命令行输入:

```CMD
python --v
```

之类的可以找到对应`Python`安装位置.

## 准备解决方案配置

要生成`Python`扩展需要配置头文件路径、库路径、库依赖,要修改输出扩展名,还需要响应`win32`和`x64`,最重要是能够使用之前的C++库,或者在原有解决方案上使用.

在原有的`VcUser`方案之上修改`template.sln.targets`.为其增加`python`配置:

### 指定`PythonHome`

```XML
<PropertyGroup Label="pybind11_generator">
    <!-- 配置Python所在位置 -->
    <PythonHome>$(LOCALAPPDATA)\Programs\Python\Python37-32\</PythonHome>
    <PythonHome Condition="'$(Platform.ToLower())' == 'x64'">$(LOCALAPPDATA)\Programs\Python\Python36\</PythonHome>
</PropertyGroup>
```

一般安装路径都是这样,可以根据版本做对应修改.

### 修改扩展名

可以根据特定规则来统一调整扩展名,譬如这里如果工程名开头为`Py`则表示其为`Python`扩展.

```XML
<PropertyGroup>
    <TargetName>$(ProjectName)</TargetName>
    <!-- 如果开头为Py且生成结果为动态库,则视为要生成python模块 -->
    <TargetExt Condition=" '$(ProjectName.Substring(0,2))' == 'Py' And '$(ConfigurationType)' == 'DynamicLibrary' ">.pyd</TargetExt>
</PropertyGroup>
```

### 工程配置

统一配置头文件路径、库依赖:

```XML
    <ItemDefinitionGroup>
        <ClCompile>
            <AdditionalIncludeDirectories>%(AdditionalIncludeDirectories);$(PythonHome)include\;$(SolutionDir)..\src\</AdditionalIncludeDirectories>
        </ClCompile>
        <ResourceCompile>
            <AdditionalIncludeDirectories>%(AdditionalIncludeDirectories);$(PythonHome)include\;$(SolutionDir)..\src\</AdditionalIncludeDirectories>
        </ResourceCompile>
        <Link>
            <AdditionalDependencies>%(AdditionalDependencies);$(PythonHome)libs\*.lib;$(OutDir)*.lib</AdditionalDependencies>
            <IgnoreSpecificDefaultLibraries>%(ImportLibrary);%(IgnoreSpecificDefaultLibraries)</IgnoreSpecificDefaultLibraries>
        </Link>
    </ItemDefinitionGroup>
```

## 总结

新建或者使用现有解决方案,将`template.sln.targets`修改为对应解决方案名,这时新建一个动态库,工程名`Py`开头,直接`#include <pybind11/pybind11.h>`,构建出来的就是`Python`模块了.
