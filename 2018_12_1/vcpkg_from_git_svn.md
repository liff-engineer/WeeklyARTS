# 如何扩展vcpkg的示例-从svn迁出代码构造包

vcpkg包管理器极大地缓解了第三方库依赖的问题,不过真正使用起来并不是那么容易,譬如我就碰到了问题,需要从svn仓库迁出代码构造成包,然后供其它项目使用.而使用vcpkg为某个包实现`port`虽然不是很难,问题是没有从`svn`迁出的功能支持啊!

那么该怎么办?回到以前的老路,一点点配置么? NO! 我们可以自己扩展vcpkg,使其支持这种场景下的包构建.

## 可行性

vcpkg对于git的支持很强,但是没有见到有svn的,你可以使用git迁出代码,也可以下载发布包,那么使用svn怎么迁出代码?

幸亏git可以直接迁出svn代码.使用`git svn clone url [project]`即可从svn代码仓库迁出代码.

如果代码在git上,可以在`port`上使用`vcpkg_from_git`命令从对应的git代码仓库迁出代码并解压到特定目录供后续包构建动作.

## `vcpkg_from_git`实现分析

`vcpkg_from_git`函数是`cmake`脚本函数,其实现在`vcpkg\scripts\cmake`目录之下,并注册到`vcpkg_common_functions.cmake`中,如果`port`里使用了`include(vcpkg_common_functions)`,那么`vcpkg\scripts\cmake`目录下所有`cmake`脚本函数都可用.

`vcpkg_from_git`函数定义为接收单个参数`OUT_SOURCE_PATH`、`URL`、`REF`、`SHA512`,同时可以在其上应用多个`patchs`,即为多参数`PATCHES`,然后将参数解析到`_vdud`上.

```CMAKE
function(vcpkg_from_git)
  set(oneValueArgs OUT_SOURCE_PATH URL REF SHA512)
  set(multipleValuesArgs PATCHES)
  cmake_parse_arguments(_vdud "" "${oneValueArgs}" "${multipleValuesArgs}" ${ARGN})
}
```

之后是对输入参数的校验.

当参数校验完成后定义了迁出代码的打包路径及名称,因为要对文件通过`SHA512`进行校验,从而判定是否需要重新迁出代码.

```CMAKE
  # using .tar.gz instead of .zip because the hash of the latter is affected by timezone.
  string(REPLACE "/" "-" SANITIZED_REF "${_vdud_REF}")
  set(TEMP_ARCHIVE "${DOWNLOADS}/temp/${PORT}-${SANITIZED_REF}.tar.gz")
  set(ARCHIVE "${DOWNLOADS}/${PORT}-${SANITIZED_REF}.tar.gz")
  set(TEMP_SOURCE_PATH "${CURRENT_BUILDTREES_DIR}/src/${SANITIZED_REF}")
```

在其后定义的`test_hash`函数就是用来验证迁出代码包的`SHA512`值,确保其为对应的内容.

```CMAKE
  function(test_hash FILE_PATH FILE_KIND CUSTOM_ERROR_ADVICE)
    file(SHA512 ${FILE_PATH} FILE_HASH)
    if(NOT FILE_HASH STREQUAL _vdud_SHA512)
        message(FATAL_ERROR
            "\nFile does not have expected hash:\n"
            "        File path: [ ${FILE_PATH} ]\n"
            "    Expected hash: [ ${_vdud_SHA512} ]\n"
            "      Actual hash: [ ${FILE_HASH} ]\n"
            "${CUSTOM_ERROR_ADVICE}\n")
    endif()
  endfunction()
```

当找不到已迁出的代码包时,开始查找`git`并执行代码迁出动作,过程包含初始化、迁出代码、打包代码等过程:

```CMAKE
  if(NOT EXISTS "${ARCHIVE}")
    if(_VCPKG_NO_DOWNLOADS)
        message(FATAL_ERROR "Downloads are disabled, but '${ARCHIVE}' does not exist.")
    endif()
    message(STATUS "Fetching ${_vdud_URL}...")
    find_program(GIT NAMES git git.cmd)
    # Note: git init is safe to run multiple times
    vcpkg_execute_required_process(
      COMMAND ${GIT} init git-tmp
      WORKING_DIRECTORY ${DOWNLOADS}
      LOGNAME git-init
    )
    vcpkg_execute_required_process(
      COMMAND ${GIT} fetch ${_vdud_URL} ${_vdud_REF} --depth 1 -n
      WORKING_DIRECTORY ${DOWNLOADS}/git-tmp
      LOGNAME git-fetch
    )
    file(MAKE_DIRECTORY "${DOWNLOADS}/temp")
    vcpkg_execute_required_process(
      COMMAND ${GIT} archive FETCH_HEAD -o "${TEMP_ARCHIVE}"
      WORKING_DIRECTORY ${DOWNLOADS}/git-tmp
      LOGNAME git-archive
    )
    test_hash("${TEMP_ARCHIVE}" "downloaded repo" "")
    get_filename_component(downloaded_file_dir "${ARCHIVE}" DIRECTORY)
    file(MAKE_DIRECTORY "${downloaded_file_dir}")
    file(RENAME "${TEMP_ARCHIVE}" "${ARCHIVE}")
```

如果已有缓存好的代码包,则验证`SHA512`：

```CMAKE
  else()
    message(STATUS "Using cached ${ARCHIVE}")
    test_hash("${ARCHIVE}" "cached file" "Please delete the file and retry if this file should be downloaded again.")
  endif()
```

然后是解压代码包：

```CMAKE
  vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    REF "${SANITIZED_REF}"
    PATCHES ${_vdud_PATCHES}
    NO_REMOVE_ONE_LEVEL
  )
```

这样就完成了从git代码仓库迁出特定的代码包全部过程.

## 如何实现`vcpkg_from_git_svn.cmake`

可以看到如果要实现从svn代码仓库迁出,只需要将git迁出指令替换成对应的svn迁出之类即可.

```CMAKE
#迁出代码
vcpkg_execute_required_process(
    COMMAND ${GIT} svn clone -r ${_vdud_REF} ${_vdud_URL}  ${PORT}
    WORKING_DIRECTORY ${DOWNLOADS}/git-tmp
    LOGNAME git-svn-clone
)

#打包代码
vcpkg_execute_required_process(
    COMMAND ${GIT} archive -o "${TEMP_ARCHIVE}" HEAD
    WORKING_DIRECTORY ${DOWNLOADS}/git-tmp/${PORT}
    LOGNAME git-archive
)
```

基本上踢掉这两个操作即可.

## 遇到的问题

vcpkg为了避免依赖,将所有依赖到的工具都使用了便携版本,譬如windows上git使用的是`minigit`,这就导致了`git svn`指令不能识别,但是全功能的git又没有便携包,那么可以借用电脑上安装的git,首先就需要移除便携git包,在`script\vcpkgTools.xml`中定义了各种系统各个工具的配置:

```XML
<tool name="git" os="windows">
    <version>2.19.1</version>
    <exeRelativePath>cmd\git.exe</exeRelativePath>
    <url>https://github.com/git-for-windows/git/releases/download/v2.19.1.windows.1/MinGit-2.19.1-32-bit.zip</url>
    <sha512>8a6d2caae2cbaacee073a641cda21465a749325c0af620dabd0e5521c84c92c8d747caa468b111d2ec52b99aee2ee3e6ec41a0a07a8fff582f4c8da568ea329e</sha512>
    <archiveName>MinGit-2.19.1-32-bit.zip</archiveName>
</tool>
```

如果要使用电脑上的git,则需要将其置空:

```XML
<tool name="git" os="windows">
    <version>2.16.0</version>
    <exeRelativePath></exeRelativePath>
    <url></url>
    <sha512></sha512>
    <archiveName></archiveName>
</tool>
```

这样vcpkg就不会自动下载便携版git,然后修改CMAKE脚本中的git命令查找方式,从环境变量中查找：

```CMAKE
find_program(GIT NAMES git ${PATH})
```

这样就可以使用git从svn迁出代码了.但是还有一个问题,代码打包时报空对象.

为什么会有这个问题?由于git打包代码并不是将现有代码仓库全部打包,而是打包更改对象,之前从svn仓库迁出来,代码没有任何调整,自然没有要打包的内容.这时使用`rebase`就可以了:

```CMAKE
#REBASE一下才可以ARCHIVE
vcpkg_execute_required_process(
    COMMAND ${GIT} svn rebase
    WORKING_DIRECTORY ${DOWNLOADS}/git-tmp/${PORT}
    LOGNAME git-rebase
)
```

## 总结

之前碰到cmake都是敬而远之,因为感觉这玩意实在太糟糕了,但是很不幸C++的世界里这个简直是现实标准,还好从cmake3.x版本开始发生了改变,现在有种提法叫`Modern CMake`,按照目前的趋势,以后`cmake`可能要在C++项目构建中占据统治地位了,需要多了解了解.