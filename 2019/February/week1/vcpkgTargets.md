# CMake 快捷使用 vcpkg 库管理器

在 MSVC 中使用 vcpkg 能够达到免配置的效果,但是如果你用 CMake,实际上体验并不好,在 vcpkg 官方文档上[Installing and Using Packages Example: SQLite](https://github.com/Microsoft/vcpkg/blob/master/docs/examples/installing-and-using-packages.md)展示了如何在 CMake 中使用通过 vcpkg 安装的第三方库.

针对`Sqlite3`使用起来非常简单且`CMake`:

```CMAKE
# CMakeLists.txt
cmake_minimum_required(VERSION 3.0)
project(test)

find_package(Sqlite3 REQUIRED)

add_executable(main main.cpp)
target_link_libraries(main sqlite3)
```

但是这个有限制,必须要求通过 vcpkg 安装的第三方库是支持 CMake 整合的,通常意味着这个第三方库的构建时就用的 CMake,否则就无法通过上述方式简单地使用.

这时候就需要通过`find_path`和`find_library`来使用,以下是使用`catch`库的示例:

```CMAKE
# To find and use catch
find_path(CATCH_INCLUDE_DIR catch.hpp)
include_directories(${CATCH_INCLUDE_DIR})

# To find and use azure-storage-cpp
find_path(WASTORAGE_INCLUDE_DIR was/blob.h)
find_library(WASTORAGE_LIBRARY wastorage)
include_directories(${WASTORAGE_INCLUDE_DIR})
link_libraries(${WASTORAGE_LIBRARY})

# Note that we recommend using the target-specific directives for a cleaner cmake:
#     target_include_directories(main ${LIBRARY})
#     target_link_libraries(main PRIVATE ${LIBRARY})
```

这一点儿也不`Modern CMake`,体验也不好,那么能不能达到与使用 Visual Studio 一样的体验呢?

基于 vcpkg 自身的机制,可以将 vcpkg 整个库作为一个第三方库来使用,也就是说使用类似`find_library`的方法,将 vcpkg 包装成一个第三方库,使得可以以如下方式使用所有安装到 vcpkg 的库:

```CMAKE
#导入vcpkg-targets.cmake
include(vcpkg-targets)

#配置目标依赖于vcpkg
target_link_libraries(target PRIVATE vcpkg)
```

`vcpkg-targets.cmake`实现如下:

```CMAKE
if(_VCPKG_INSTALLED_DIR)
    if(EXISTS "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}")
        set(VCPKG_FOUND TRUE)
        set(VCPKG_INCLUDE_DIR  "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/include")
        file(GLOB VCPKG_LIBRARYS_DEBUG "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib/*.lib")
        file(GLOB VCPKG_LIBRARYS_RELEASE "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib/*.lib")
    endif()
endif()

if(VCPKG_FOUND  AND NOT TARGET vcpkg)
    add_library(vcpkg INTERFACE IMPORTED)
    target_include_directories(vcpkg INTERFACE ${VCPKG_INCLUDE_DIR})
    target_link_libraries(vcpkg INTERFACE
        $<$<CONFIG:Debug>:${VCPKG_LIBRARYS_DEBUG}>
        $<$<CONFIG:Release>:${VCPKG_LIBRARYS_RELEASE}>
        )
endif()
```

注意,我们根据 vcpkg 自身机制,找到了特定场景下的头文件路径和库依赖,并区分出 debug 和 release 版本,然后将其配置到目标`vcpkg`上,从而使编写 CMakeLists.txt 使可以通过依赖于这个目标从而自动配置好头文件和库依赖.但是这个可能仅限于在 Windows 上使用.

虽然通过这种方式可以简化配置,我依然建议通过`Modern CMake`的方式配置具体的库依赖,如果将自己的库进行发布时,优先选择使用`CMake`而不是`MSBuild`.
