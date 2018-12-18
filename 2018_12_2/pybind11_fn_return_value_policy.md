# [pybind11函数返回值策略](https://pybind11.readthedocs.io/en/master/advanced/functions.html#return-value-policies)

`pybind11`为`C++`和`Python`之间提供了无缝的衔接体验.但是有一些语言机制上的不同使得在使用`pybind11`时需要特别小心,譬如函数的返回值策略.

`Python`和`C++`在内存管理和对象生命周期管理上有根本性的不同.当为函数创建绑定时,如果函数返回值不是平凡类型,这将会导致一些问题.仅仅是通过类型信息,无法决定`Python`端应该接管返回值并最终释放其资源,还是说这些应该由`C++`端来处理.因而`pybind11`提供了一些`返回值策略`注解,来传递给`module::def()`和`class_::def()`函数.默认的策略为`return_value_policy::automatic`.

返回值策略需要根据场景去分析.譬如以下示例:

```C++
/* 函数声明 */
Data *get_data() { return _data; /* 指针指向静态数据 */ }
...

/* Binding code */
m.def("get_data", &get_data); // <-- 当从Python端调用时会崩溃
```

这个是怎么回事?当`get_data`被`Python`端调用时,返回值(C++类型)必须包裹成`Python`类型.这种情况下,根据默认的返回值策略(return_value_policy::automatic),`pybind11`决定要获取`_data`数据的所有权.

当`Python`的垃圾收集器最终删除`Python`包裹时,`pybind11`就会试图删除对应的C++实例,这时,整个程序就会崩溃,或者产生一些静默的错误.

在上述实例中,应当指定`return_value_policy::reference`策略,使得全局数据实例只是被引用,而不触发任何所有权转移:

```C++
m.def("get_data", &get_data, return_value_policy::reference);
```

反过来说,这个策略在大多数情况下不是正确的策略,因为忽略所有权会到导致资源泄漏.作为使用`pybind11`的开发人员,必须熟悉不同的返回值策略,在哪种情况下应该使用哪个.

- `return_value_policy::take_ownership`

引用已有对象并接管所有权.当对象引用计数到0时,`Python`将会调用其析构函数和删除操作.当数据不是动态申请或者`C++`端做了同样的动作就会导致为定义行为.

- `return_value_policy::copy`

为返回对象创建一份新的副本,这个副本将会被`Python`端所拥有,这个策略是相对安全的,因为两个实例的生命周期相互独立.

- `return_value_policy::move`

使用`std::move`将返回值转移到新实例,该实例会被`Python`端所拥有.这个策略是相对安全的,因为两个实例的生命周期相互独立.

- `return_value_policy::reference`

返回现存对象的引用,但是不接管所有权.`C++`端负责管理对象生命周期,当其不再被使用时释放掉.但是需要注意当`C++`端删除掉对象,而`Python`端依然引用是会出现未定义行为.

- `return_value_policy::reference_internal`

表示返回值的生命周期和父对象的生命周期是绑定的,父对象是隐含的`this`或者调用方法/属性时的`self`参数.这个是属性`getter`的默认策略.

- `return_value_policy::automatic`

默认策略.当返回值是指针时,该策略会转换成`return_value_policy::take_ownership`,当返回值是右值引用时,为`return_value_policy::move`,当返回值是左值引用是为`return_value_policy::copy`.

- `return_value_policy::automatic_reference`

与上一个一致,但是当返回值是指针时使用`return_value_policy::reference`.当从`C++`端调用`Python`函数时这个时函数参数的默认转换策略.你应该不需要使用它.

返回值策略也可以被应用到属性上:

```C++
class_<MyClass>(m, "MyClass")
    .def_property("data", &MyClass::getData, &MyClass::setData,
                  py::return_value_policy::copy);
```

技术上讲,上述代码应用策略到`getter`和`setter`函数,但是`setter`函数不在乎返回值策略.作为替代写法,可以使用`cpp_function`来传递相应的参数:

```C++
class_<MyClass>(m, "MyClass")
    .def_property("data"
        py::cpp_function(&MyClass::getData, py::return_value_policy::copy),
        py::cpp_function(&MyClass::setData)
    );
```