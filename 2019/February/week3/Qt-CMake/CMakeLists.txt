cmake_minimum_required(VERSION 3.13.2)

##从环境变量QTDIR加载Qt
list(APPEND CMAKE_PREFIX_PATH $ENV{QTDIR})
##从路径加载Qt
#list(APPEND CMAKE_PREFIX_PATH  "C:/Qt/5.6.3/msvc2015_64")

project(QtVsCMake)

##查找Qt5,必须包含组件Widgets
find_package(Qt5 COMPONENTS Widgets REQUIRED)

##添加应用程序
add_executable(example)

##如果是MSVC则指定应用程序为GUI
if(MSVC)
    set_target_properties(example PROPERTIES 
        WIN32_EXECUTABLE ON
    )
endif()

##example目标自动处理MOC
set_target_properties(example PROPERTIES
    AUTOMOC ON
)

##由于有moc,则需要将moc生成目录也添加到include路径
set(CMAKE_INCLUDE_CURRENT_DIR ON)

##为目标配置源文件
set(PROJECT_SOURCES 
    main.cpp 
    MainWindow.cpp
)

target_sources(example
    PRIVATE ${PROJECT_SOURCES}
)

##为目标配置库依赖
target_link_libraries(example 
    PRIVATE Qt5::Widgets
)