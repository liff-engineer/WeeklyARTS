# Windows 上 利用 CMake 实现部署

在 Windows 上开发者一般选择 Visual Studio 进行开发,也就是说会通过 CMake 生成解决方案,然后再用 Visual Studio 进行开发,这样就面临一个问题,我们在 Visual Studio 中进行调试运行,会要求所依赖的动态库以及数据在能够查找到的位置,一般针对 Qt 是通过`QTDIR`环境变量,针对其他就是采用的输出到同一目录的方式.

那么使用 CMake 能不能为我们自动完成这个步骤?

## 解决方案下所有工程构建结果都输出到相同目录

这个相对比较简单,只需要调整`CMAKE_RUNTIME_OUTPUT_DIRECTORY`变量即可.譬如你希望输出目录格式为`${PLATFORM}/${CONFIG}`,那么实现方式如下:

```cmake
if(CMAKE_SIZEOF_VOID_P EQUAL 4)
    set(PROJECT_PLATFORM "Win32")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(PROJECT_PLATFORM "x64")
endif()

##将动态库输出路径定位到特定路径,供调试时使用(否则依赖的库分布在各个文件夹)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${PROJECT_PLATFORM}/$<CONFIG>")
```

使用上述操作之后,输出结果就会被聚合,而不会出现分散到各个文件夹中的问题.

## 自动部署依赖的动态库

使用`dumpbin`能够查到应用程序/动态链接库所依赖的动态链接库,`CMake`虽然提供了相关支持,但是文档语焉不详,搞不清楚到底如何使用,幸好`vcpkg`中提供了对应的功能实现,其原理如下:

- 运行`dumpbin`获取到动态链接库依赖列表
- 针对依赖根据可用路径查询是否存在
- 查询到依赖复制到目标路径后,切换查询目标继续查询

我这里将其改写为支持多路径查询,实现`deploy_library.ps1`如下:

```powershell
[cmdletbinding()]
param([string]$targetBinary, [string]$installedDirsHint, [string]$tlogFile, [string]$copiedFilesLog)

##动态库所在路径数组
$binaryDirs = $installedDirsHint.Split(";")

##全局缓存,避免重复查询
$g_searched = @{ }

# Ensure we create the copied files log, even if we don't end up copying any files
if ($copiedFilesLog) {
    Set-Content -Path $copiedFilesLog -Value "" -Encoding Ascii
}

##从可用路径中查询动态库
function findBinaryDir([string]$target) {
    return $binaryDirs | Where-Object { Test-Path "$_\$target" } | Select-Object -First 1
}

##复制动态库到目标路径
function deployBinary([string]$targetBinaryDir, [string]$sourceDir, [string]$targetBinaryName) {
    if (Test-Path "$targetBinaryDir\$targetBinaryName") {
        Write-Verbose " ${targetBinaryName}:already present"
    }
    else {
        Write-Verbose " ${targetBinaryName}:Copying $sourceDir\$targetBinaryName"
        Copy-Item "$sourceDir\$targetBinaryName" $targetBinaryDir
    }

    if ($copiedFilesLog) { Add-Content $copiedFilesLog "$targetBinaryDir\$targetBinaryName" }
    if ($tlogFile) { Add-Content $tlogFile "$targetBinaryDir\$targetBinaryName" }
}

Write-Verbose "Resolving base path $targetBinary..."
try {
    $baseBinaryPath = Resolve-Path $targetBinary -erroraction stop
    $baseTargetBinaryDir = Split-Path $baseBinaryPath -parent
}
catch [System.Management.Automation.ItemNotFoundException] {
    return
}

##递归查询目标的依赖,以及依赖的依赖
function resolve([string]$targetBinary) {
    Write-Verbose "Resolving $targetBinary"
    try {
        $targetBinaryPath = Resolve-Path $targetBinary -erroraction stop
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        return
    }

    $targetBinaryPath = Split-Path $targetBinaryPath -parent

    $a = $(dumpbin /DEPENDENTS $targetBinary | ? { $_ -match "^    [^ ].*\.(dll|tx)" } | % { $_ -replace "^    ", "" })
    $a | % {
        if ([string]::IsNullOrEmpty($_)) {
            return
        }
        if ($g_searched.ContainsKey($_)) {
            Write-Verbose "  ${_}: previously searched - Skip"
            return
        }
        $g_searched.Set_Item($_, $true)

        $binaryDir = findBinaryDir($_)
        if ($binaryDir) {
            deployBinary $baseTargetBinaryDir $binaryDir "$_"
            resolve "$targetBinaryPath\$_"
        }
        else {
            Write-Verbose "${_}:${_} not found."
        }
    }
    Write-Verbose "Done Resolving $targetBinary."
}

resolve($targetBinary)
Write-Verbose $($g_searched | Out-String)
```

然后在 CMake 中提供`custom_target`或者为具体的`target`添加`custom_command`.在这里我提供了如下实现,来支持为特定目标自动部署依赖的动态链接库:

```cmake
set(__deploy_library__path ${CMAKE_CURRENT_LIST_DIR})

##自动部署依赖的动态库
function(deploy_library)
    set(options GLOBAL)
    set(oneValueArgs TARGET)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(Gen "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    get_target_property(__target_type ${Gen_TARGET} TYPE)
    if(NOT __target_type STREQUAL "EXECUTABLE" AND NOT __target_type STREQUAL "SHARED_LIBRARY")
        message(FATAL_ERROR  "deploy used for dynamic library or exe")
        return()
    endif()

    set(__target "deploy_library_${Gen_TARGET}")
    if(TARGET ${__target})
        return()
    endif()

    set(__library_dirs)
    foreach(__library ${Gen_TARGETS})
        list(APPEND __library_dirs  $<TARGET_FILE_DIR:${__library}> )
    endforeach()

    add_custom_target(${__target} ALL
        powershell -noprofile  -executionpolicy Bypass -file  ${__deploy_library__path}/deploy_library.ps1
        -targetBinary $<TARGET_FILE:${Gen_TARGET}>
        -installedDirsHint "${__library_dirs}"
        -OutVariable out
        COMMENT "deploy runtime library dependencies"
    )
    set_target_properties(${__target}  PROPERTIES FOLDER "deploy")
endfunction()
```

`TARGET`就是我们要为其部署依赖的目标,而`TARGETS`则是其依赖的`target`,主要作用是给出动态链接库可能存在的路径.实现步骤如下:

1. 检查目标类型
2. 去重
3. 生成路径列表
4. 创建自定义`target`
5. 指定`target`所属文件夹(Visual Studio 中会被分类)

使用方式如下:

```cmake
deploy(
    TARGET your_target_name
    TARGETS "Qt5::Core;Package::Library;..."
)
```

这样就会在`Qt5::Core`以及`Package::Library`所在路径中寻找`your_target_name`递归依赖的所有动态库.

## 部署 Visual C++运行时

CMake 提供了安装 Visual C++运行时的脚本,在 Windows 上正确的方式应该是安装包添加安装运行时的步骤.不过这里有可能你希望构建结果可以直接打包给别人使用,这就需要将 Visual C++运行时也复制到输出目录.我们可以根据 CMake 已实现的脚本来做这件事情:

```cmake
##部署MSVC的CRT
function(deploy_crt)
    set(options GLOBAL)
    set(oneValueArgs TARGET)
    cmake_parse_arguments(Gen "${options}" "${oneValueArgs}" "" ${ARGN})

    if(Gen_GLOBAL)
        set(__target deploy_msvc_crt)
    else()
        set(__target "deploy_msvc_crt_${Gen_TARGET}")
    endif()

    if(TARGET ${__target})
        return()
    endif()

    include (InstallRequiredSystemLibraries)
    if(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS)
        list(GET CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS 0 __file)
        get_filename_component(MSVC_CRT_PATH ${__file} DIRECTORY)
        #message(STATUS "MSVC CRT PATH: ${MSVC_CRT_PATH}")
        add_custom_target(${__target} ALL
            ${CMAKE_COMMAND} -E copy_directory
            "${MSVC_CRT_PATH}"
            $<TARGET_FILE_DIR:${Gen_TARGET}>
            COMMENT "deploy msvc crt dependencies"
        )
        set_target_properties(${__target} PROPERTIES FOLDER "deploy")
    endif()
endfunction()
```

实现方式如下:

1. 添加`InstallRequiredSystemLibraries`
2. 运行时库及路径存放在`CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS`中
3. 取出路径,并复制整个路径的内容到目标路径

## Qt 的插件及运行时资源

之前的`deploy_library`只是解决了动态链接库的问题,但是一些 Qt 的动态加载插件及运行时资源是无法处理的,这里可以借助于 Qt 提供的`windeployqt`工具来完成:

```cmake
##部署Qt插件
function(deploy_qt_plugins)
    set(options GLOBAL WebEngine)
    set(oneValueArgs TARGET)
    set(multiValueArgs PLUGINS)
    cmake_parse_arguments(Gen "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    ##分为全局部署及特定部署
    if(Gen_GLOBAL)
        set(__target deploy_qt_plugins)
    else()
        set(__target "deploy_qt_plugins_${Gen_TARGET}")
    endif()

    if(TARGET ${__target})
        return()
    endif()

    find_package(Qt5 COMPONENTS Core CONFIG)

    if(NOT _qt5_install_prefix)
        return()
    endif()

    ##message(STATUS "Qt cmake模块位于:${_qt5_install_prefix}")

    ##_qt5_install_prefix基本上在lib/cmake位置,需要定位到bin路径下面找到部署程序
    find_program(__qt5_deploy windeployqt PATHS "${_qt5_install_prefix}/../../bin")

    add_custom_target(${__target} ALL)
    set_target_properties(${__target}  PROPERTIES FOLDER "deploy")

    set(qt_plugins "")
    foreach(__plugin ${Gen_PLUGINS})
        string(APPEND qt_plugins " -${__plugin}")
    endforeach()

    ##部署Qt运行时及插件
    separate_arguments(qt_plugins_list WINDOWS_COMMAND ${qt_plugins})
    add_custom_command(TARGET ${__target} POST_BUILD
        COMMAND ${__qt5_deploy} $<TARGET_FILE:${Gen_TARGET}> ${qt_plugins_list}
        COMMENT "deploy Qt runtime dependencies"
        COMMAND ${CMAKE_COMMAND} -E copy  "$<TARGET_FILE:Qt5::Core>" "$<TARGET_FILE_DIR:${Gen_TARGET}>/$<TARGET_FILE_NAME:Qt5::Core>"
        COMMENT "recover Qt5Core"
    )

    ##Qt如果部署包含Qt WebEngine的应用,需要处理无法自动部署的资源
    if(Gen_WebEngine)
        add_custom_command(TARGET ${__target} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${_qt5_install_prefix}/../../resources/"  ##拷贝 resources 目录下内容
            "$<TARGET_FILE_DIR:${Gen_TARGET}>"
            COMMENT "deploy Qt WebEngine resources"

            COMMAND ${CMAKE_COMMAND} -E copy
            "${_qt5_install_prefix}/../../bin/$<IF:$<CONFIG:DEBUG>,QtWebEngineProcessd.exe,QtWebEngineProcess.exe>"
            "$<TARGET_FILE_DIR:${Gen_TARGET}>/$<IF:$<CONFIG:DEBUG>,QtWebEngineProcessd.exe,QtWebEngineProcess.exe>"
            COMMENT "deploy Qt WebEngine process"
        )
    endif()
endfunction()
```

需要注意的是,我们在调用完`windeployqt`后立即恢复了`Qt5::Core`,原因在于`windeployqt`会为`Qt5::Core`打 patch,无法阻止,因而选择将其恢复.

如果需要部署特定插件,譬如`sql`以及`printsuppport`,则将其置于`PLUGINS`里即可.

使用方式如下:

```cmake
deploy_qt_plugins(
    Global WebEngine
    TARGET your_target_name
    PLUGINS "sql;printsuport"
)
```

## 其他资源

有一些第三方库在使用是也需要提供相应的资源部署脚本,我们可以按照同样的方法实现.

## 整合思路

我们最终可以将所有碎片拼成整体,合并到一个实现之中,通过选项来控制各个部分的部署,譬如:

```cmake
function(deploy)
    set(options GLOBAL GlobalQtPlugins Qt QtDeploy PACKAGE_NAME)
    set(oneValueArgs TARGET)
    set(multiValueArgs QtPlugins)
    cmake_parse_arguments(Gen "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    ##实现
}
```

在需要进行部署的目标上添加:

```cmake
deploy(
    QtDeploy Qt PACKAGE_NAME
    TARGET your_target_name
    QtPlugins "sql"
)
```

这样就可以将整个运行时环境准备好,输出目录也可以直接打包在别的电脑上运行.
