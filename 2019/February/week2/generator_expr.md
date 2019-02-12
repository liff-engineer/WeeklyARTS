# [CMake Generator expressions](https://cmake.org/cmake/help/latest/manual/cmake-generator-expressions.7.html)

在使用 MSVC 构造附带调试信息的版本时,如果需要进行性能分析,需要为链接器配置`/PROFILE`选项.那么在`CMake`中该如何配置呢?

这时候就需要使用`CMake`的`Generator`表达式了:

```CMAKE
if (MSVC)
  target_link_options(my_target PRIVATE $<$<CONFIG:RELWITHDEBINFO>:/PROFILE>)
endif()
```

`Generator`表达式形式为`$<...>`.以下是几种表达式:

## 布尔`Generator`表达式

布尔表达式计算结果要么是`0`要么是`1`.经常用来构造条件`Generator`表达式.可用的布尔表达式如下:

### 逻辑操作

- `$<BOOL:string>`
  将`string`转换为`0`或`1`.规则参照`if`命令.
- `$<AND:conditions>`
  `conditions`是由逗号分隔开的布尔表达式.当所有条件都为`1`时结果为`1`
- `$<OR:conditions>`
  `conditions`是由逗号分隔开的布尔表达式.当任意条件为`1`时结果为`1`
- `$<NOT:condition>`
  取反操作

### 字符串比较

- `$<STREQUAL:string1,string2>`:大小写敏感的字符串比较
- `$<EQUAL:value1,valu2>`:数值比较
- `$<IN_LIST:string,list>`
- `$<VERSION_LESS>:v1,v2`
- `$<VERSION_GREATER>:v1,v2`
- `$<VERSION_EQUAL>:v1,v2`
- `$<VERSION_LESS_EQUAL>:v1,v2`
- `$<VERSION_GREATER_EQUAL>:v1,v2`

### 变量查询

- `$<TARGET_EXISTS:target>`
- `$<CONFIG:cfg>`
- `$<PLATFORM_ID:platform_id>`
- `$<CXX_COMPILER_ID>:compiler_id`
- `$<CXX_COMPILER_VERSION>:version`
- `$<COMPILE_FREATURES:features>`

## 字符串值生成表达式

表达式会被展开成字符串,例如:

```CMAKE
include_directories(/usr/include/$<CXX_COMPILER_ID>/)
```

### 转义字符

- `$<ANGLE-R>`:`>`
- `$<COMMA>`:`,`
- `$<SEMICOLON>`:`;`

### 条件表达式

- `$<condition:true_string>`:当条件为`1`时结果为`true_string`,否则为空
- `$<IF:condition,true_string,false_string>`

### 字符串转换

- `$<JOIN:list,string>`:列表合并
- `$<LOWER_CASE:string>`
- `$<UPPER_CASE:string>`
- `$<GENEX_EVAL:expr>`:`expr`作为表达式运算

### 变量查询

- `$<CONFIG>`:配置名
- `$<PLATFORM_ID>`
- `$<CXX_COMPILER_ID>`
- `$<CXX_COMPILER_VERSION>`

### 目标依赖查询

- `$<TARGET_NAME_IF_EXISTS:tgt>`
- `$<TARGET_FILE:tgt>`
- `$<TARGET_FILE_NAME:tgt>`
- `$<TARGET_PROPERTY:prop>`
