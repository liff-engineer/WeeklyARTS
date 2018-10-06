# [JSON for Modern C++](https://github.com/nlohmann/json)

C++的json库有几十种,nolhmann的json库不是其中效率最高的,但是依我浅薄的认知,应该算是最好用的,下面就来聊一聊如何使用这个库。

## 要求及安装

要使用`JSON for Modern C++`,以下称为`nlohmann-json`,编译器必须支持C++11标准;

`nlohmann-json`可以作为单个头文件库使用,而最简单的方式是使用包管理器,譬如在Windows上使用[vcpkg](https://github.com/Microsoft/vcpkg/),仅需要以下指令即可:

```CMD
.\vcpkg.exe install nlohmann-json nlohmann-json:x64-windows
```

## 创建json

譬如要创建如下json文件:

```json
{
  "pi": 3.141,
  "happy": true,
  "name": "Niels",
  "nothing": null,
  "answer": {
    "everything": 42
  },
  "list": [1, 0, 2],
  "object": {
    "currency": "USD",
    "value": 42.99
  }
}
```

### 常规方式

采用声明`json`对象一点点填充的方式如下:

```C++
#include <nlohmann/json.hpp>

// for convenience
using json = nlohmann::json;


void example(){
    json j;
    j["pi"] = 3.141;
    j["happy"] = true;
    j["name"] = "Niels";
    j["nothing"] = nullptr;
    j["answer"]["everything"] = 42;
    j["list"] = { 1, 0, 2 };
    j["object"] = { {"currency", "USD"}, {"value", 42.99} };
}
```

可以看到,针对object形式的json,可以当作map来操作,对于json支持的number、string、boolean等值可以直接赋值,同样也支持STL容器及初始化列表。

### 直接声明

也可以直接书写出整个json对象:

```C++
json j2 = {
  {"pi", 3.141},
  {"happy", true},
  {"name", "Niels"},
  {"nothing", nullptr},
  {"answer", {
    {"everything", 42}
  }},
  {"list", {1, 0, 2}},
  {"object", {
    {"currency", "USD"},
    {"value", 42.99}
  }}
};
```

`nlohmann-json`的初始化列表支持基本上可以让开发者以类似json文件的样式书写。

### 显式创建

有时需要明确创建出json-array或者json-object,则可以这样写:

```C++
json empty_array_explicit = json::array();
json empty_object_implicit = json({});
json empty_object_explicit = json::object();
json array_not_object = json::array({ {"currency", "USD"}, {"value", 42.99} });
```

通过明确地创建`json::array`或者`json::object`来强制`nlohmann-json`生成想要的结构。

### 字面量创建

也可以通过字面量形式创建出对应的json对象:

```C++
json j = "{ \"happy\": true, \"pi\": 3.141 }"_json;
//或者
auto j2 = R"(
  {
    "happy": true,
    "pi": 3.141
  }
)"_json;
```

利用C++11的用户自定义字面量,即可直接声明对应内容的json对象。

### STL容器无缝支持

任何STL序列容器,例如`std::array`、`std::vector`、`std::deque`、`std::list`、`std::forward_list`等,内部存储的值如果可以转换成json值,则可以直接用来创建出json-array,而类似的情况,`std::set`、`std::unordered_set`等也可直接转换成json-array,其中值顺序与容器内部顺序一致,例如:

```C++
std::vector<int> c_vector {1, 2, 3, 4};
json j_vec(c_vector);
// [1, 2, 3, 4]

std::deque<double> c_deque {1.2, 2.3, 3.4, 5.6};
json j_deque(c_deque);
// [1.2, 2.3, 3.4, 5.6]

std::list<bool> c_list {true, true, false, true};
json j_list(c_list);
// [true, true, false, true]

std::forward_list<int64_t> c_flist {12345678909876, 23456789098765, 34567890987654, 45678909876543};
json j_flist(c_flist);
// [12345678909876, 23456789098765, 34567890987654, 45678909876543]

std::array<unsigned long, 4> c_array {{1, 2, 3, 4}};
json j_array(c_array);
// [1, 2, 3, 4]

std::set<std::string> c_set {"one", "two", "three", "four", "one"};
json j_set(c_set); // only one entry for "one" is used
// ["four", "one", "three", "two"]

std::unordered_set<std::string> c_uset {"one", "two", "three", "four", "one"};
json j_uset(c_uset); // only one entry for "one" is used
// maybe ["two", "three", "four", "one"]

std::multiset<std::string> c_mset {"one", "two", "one", "four"};
json j_mset(c_mset); // both entries for "one" are used
// maybe ["one", "two", "one", "four"]

std::unordered_multiset<std::string> c_umset {"one", "two", "one", "four"};
json j_umset(c_umset); // both entries for "one" are used
// maybe ["one", "two", "one", "four"]
```

而任何STL关联键值容器,例如`std::map`、`std::unordered_map`等,内部存储的值如果可以转换成json值,则容器可以直接转换成json-object,例如:

```C++
std::map<std::string, int> c_map { {"one", 1}, {"two", 2}, {"three", 3} };
json j_map(c_map);
// {"one": 1, "three": 3, "two": 2 }

std::unordered_map<const char*, double> c_umap { {"one", 1.2}, {"two", 2.3}, {"three", 3.4} };
json j_umap(c_umap);
// {"one": 1.2, "two": 2.3, "three": 3.4}

std::multimap<std::string, bool> c_mmap { {"one", true}, {"two", true}, {"three", false}, {"three", true} };
json j_mmap(c_mmap); // only one entry for key "three" is used
// maybe {"one": true, "two": true, "three": true}

std::unordered_multimap<std::string, bool> c_ummap { {"one", true}, {"two", true}, {"three", false}, {"three", true} };
json j_ummap(c_ummap); // only one entry for key "three" is used
// maybe {"one": true, "two": true, "three": true}
```

### 输出

得到对应的json对象后,即可获取其字符串表示或者存储到文件等流中,获取字符串表示方式如下:

```C++
std::string s = j.dump();
```

输出到流也非常简单,譬如以下输出到文件流:

```C++
std::ofstream o("pretty.json");
o << std::setw(4) << j << std::endl;
```

## 解析json

除了之前提到的可以用`_json`这种自定义字面量直接将字符串解析成json对象,也可以使用`json::parse()`接口来解析字符串为json对象:

```C++
auto j3 = json::parse("{ \"happy\": true, \"pi\": 3.141 }");
```

从流中加载json对象也与输出到流类似,例如:

```C++
std::ifstream i("file.json");
json j;
i >> j;
```

当然也可以从数据缓存中读取并解析,譬如:

```C++
std::vector<std::uint8_t> v = {'t', 'r', 'u', 'e'};
json j = json::parse(v.begin(), v.end());

//或者直接传递容器
std::vector<std::uint8_t> v = {'t', 'r', 'u', 'e'};
json j = json::parse(v);
```

## 访问json

解析完成之后,就需要对json对象进行访问来获取其中的内容,`nlohmann-json`提供的方式也有很多。

### 获取json值信息

```C++
j.size();     // 3 entries
j.empty();    // false
j.type();     // json::value_t::array
j.clear();    // the array is empty again

// convenience type checkers
j.is_null();
j.is_boolean();
j.is_number();
j.is_object();
j.is_array();
j.is_string();
```

### 隐式获取json值

需要将json值转换成字符串、浮点数等值时,可以使用隐式转化的书写方式获取,例如:

```C++
std::string s1 = "Hello, world!";
json js = s1;
std::string s2 = js;

// Booleans
bool b1 = true;
json jb = b1;
bool b2 = jb;

// numbers
int i = 42;
json jn = i;
double f = jn;
```

`nlohmann-json`可以根据`=`号左侧的值类型来实现自动转换。

### 显式获取json值

有时需要明确指定要获取的值类型,则可以采用`get<T>()`接口:

```C++
std::string vs = js.get<std::string>();
bool vb = jb.get<bool>();
int vi = jn.get<int>();
```

### 遍历数组或者对象

`nlohmann-json`提供了类似STL容器的访问接口,可以直接将其当作STL容器使用,譬如当作json数组的操作方式:

```C++
json j;
j.push_back("foo");
j.push_back(1);
j.push_back(true);

// also use emplace_back
j.emplace_back(1.78);

// iterate the array
for (json::iterator it = j.begin(); it != j.end(); ++it) {
  std::cout << *it << '\n';
}

// range-based for
for (auto& element : j) {
  std::cout << element << '\n';
}
```

而针对json对象的操作方式也跟map差不多:

```C++
// create an object
json o;
o["foo"] = 23;
o["bar"] = false;
o["baz"] = 3.141;

// also use emplace
o.emplace("weather", "sunny");

// special iterator member functions for objects
for (json::iterator it = o.begin(); it != o.end(); ++it) {
  std::cout << it.key() << " : " << it.value() << "\n";
}

// find an entry
if (o.find("foo") != o.end()) {
  // there is an entry with key "foo"
}

// or simpler using count()
int foo_present = o.count("foo"); // 1
int fob_present = o.count("fob"); // 0

// delete an entry
o.erase("foo");
```

值得注意的是C++11的range-for无法用到json对象上,智能用在json数组上。

## 扩展

很多时候不仅仅是基本的json值和STL容器需要转换,我们也希望自定义的类型可以当作字符串等标量进行操作,这时可以利用`nlohmann-json`的扩展机制.

譬如针对自定义的结构体:

```C++
namespace ns {
    // a simple struct to model a person
    struct person {
        std::string name;
        std::string address;
        int age;
    };
}
```

如何实现这样的操作?

```C++
// create a person
ns::person p {"Ned Flanders", "744 Evergreen Terrace", 60};

// conversion: person -> json
json j = p;

std::cout << j << std::endl;
// {"address":"744 Evergreen Terrace","age":60,"name":"Ned Flanders"}

// conversion: json -> person
ns::person p2 = j;

// that's it
assert(p == p2);
```

仅仅需要为自定义类型实现两个函数,`to_json`和`from_json`,例如:

```C++
using nlohmann::json;

namespace ns {
    void to_json(json& j, const person& p) {
        j = json{{"name", p.name}, {"address", p.address}, {"age", p.age}};
    }

    void from_json(const json& j, person& p) {
        j.at("name").get_to(p.name);
        j.at("address").get_to(p.address);
        j.at("age").get_to(p.age);
    }
} // namespace ns
```

## 总结

可以看到,`nlohmann-json`如其所说:`JSON as first-class data type`,在操作json的过程中确实非常好用,与STL容器的整合,自定义类型扩展的支持,包括创建、访问方式,都简洁易用,值得拥有。
