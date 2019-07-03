# [Python 中的修饰器](https://hackernoon.com/decorators-in-python-8fd0dce93c08)

在这篇文章中,我们将会了解到:

1. 什么是修饰器?
2. 修饰器如何工作?
3. 如何在 Python 中定义自己的修饰器?

为了理解 Python 中的修饰器,我们需要知道 Python 中的函数是什么.

在 Python 中,所有东西都是对象.Python 中的函数是头等对象,这意味着它们可以通过变量引用,添加到列表中,作为参数传递给其他函数等.

## 函数可以通过变量引用

Python 中的基本函数示例如下:

```python
def say_hello():
  print("Hello")

# say_hello() Output: Hello
```

我们可以声明另一个变量`say_hello2`来引用`say_hello`函数:

```python
say_hello2 = say_hello

say_hello2() # Output: Hello

# Check if say_hello and say_hello2 are same
print(say_hello2 is say_hello) # Output: True which means they point at the same location
```

在上述示例中,`say_hello2`和`say_hello`指向相同的函数定义,两个执行会生成相同的结果.

## 函数可以作为参数传递给其他函数

```python
def say_hello(say_hi_func):
  print("Hello")

  say_hi_func()

def say_hi():
  print("Hi")

say_hello(say_hi)

#Output:
  # Hello
  # Hi
```

函数是对象,它们自然可以作为参数传递给其他函数.在上述示例中,我们可以将`say_hi`作为参数传递给`say_hello`.`say_hi`通过变量`say_hi_func`被引用.在`say_hello`中,`say_hi_func`被调用然后打印`Hi`.

## 函数可以在其他函数中定义

```python
def say_hello():
  print("Hello")

  def say_hi():
    print("Hi")

  say_hi()

say_hello()
# Output: Hello
#         Hi

# say_hi not available outside the scope of say_hello
say_hi() # Gives error
```

在上述示例中,`say_hi`被定义在`say_hello`函数内部.这在 python 中是有效的.当我们调用`say_hello`时,`say_hi`的定义在`say_hello`函数中得到,然后在`say_hello`函数中调用.

如果我们尝试在`say_hello`函数外部调用`say_hi`,Python 将会报错,因为`say_hi`在`say_hello`函数外部不存在.

## 函数可以返回其他函数的引用

```python
def say_hello():
  print("Hello")

  def say_hi():
    print("Hi")

  return say_hi

# Prints Hello and returns say_hi function which gets stored in variable say_hi_func
say_hi_func = say_hello()

# As say_hi function is refered by say_hi_func variable so calling say_hi_func will call say_hi.
# It will print Hi
say_hi_func()
```

在上述示例中,`say_hello`函数返回`say_hi`函数的引用.返回的函数引用赋值给`say_hi_func`.因而`say_hi_func`也会开始指向`say_hi`函数.

另一个带函数参数的示例:

```python
def say_hello(hello_var):
  print(hello_var)

  def say_hi(hi_var):
    print(hello_var + " " + hi_var)

  return say_hi

# Print Hello and returns say_hi function which gets stored in say_hi_func variable
say_hi_func = say_hello("Hello")

# Call say_hi function and print "Hello Hi"
say_hi_func("Hi")
```

变量`hello_var`即使在`say_hello`函数外也可以访问,因为`say_hi`函数被定义在`say_hello`函数内部,所以它可以访问`say_hello`函数的所有变量.这个被称为闭包.

理解了函数后,让我们看一看修饰器.

---

## 修饰器

修饰器是可调用对象,用来修改函数或者类.

可调用对象是指那些能够接收一些参数然后返回对象的对象.*函数*和*类*就是 Python 中的可调用对象实例.

函数修饰器是这样的函数,它接收函数引用作为参数,然后添加包装,返回带包装的函数作为新函数.

让我们看个示例:

```python
import inspect

# Accepts function as a parameter
def decorator_func(some_func):

  # define another wrapper function which modifies some_func
  def wrapper_func():
    print("Wrapper function started")

    some_func()

    print("Wrapper function ended")

  # Wrapper function add something to the passed function and decorator returns the wrapper function
  return wrapper_func

def say_hello():
  print ("Hello")

say_hello = decorator_func(say_hello)

# This function prints the definition of function stored in say_hello
# variable.Here, we can see that our say_hello function has been wrapped
# inside wrapper_func()
print inspect.getsource(say_hello)

# Output:
'''
  def wrapper_func():
    print("Wrapper function started")

    some_func()

    print("Wrapper function ended")
'''

# When we call say_hello function, we are actually calling wrapper_func
# say_hello() is same as wrapper_func()
say_hello()

# Output:
#  Wrapper function started
#  Hello
#  Wrapper function ended
```

在上述示例中,`decorator_func`这个修饰函数接收`some_func`这个函数对象作为参数.它定义了个`wrapper_func`调用`some_func`,同时也会指向一些自己的代码.

这个`wrapper_func`被我们的修饰函数返回并存储到`say_hello`变量中.因而,`say_hello`目前引用到`wrapper_func`,`wrapper_func`调用作为参数传递的函数同时也会有一些额外的代码.换句话说,修饰函数修改了我们的`say_hello`函数,并向其添加了一些额外代码.这就是修饰器.输出是修改版的`say_hello`函数并带有附加的`print`声明.

## Python 修饰器语法

```python
@decorator_func
def say_hell():
    print 'Hello'
```

上述声明等价于:

```python
def say_hello():
    print 'Hello'
say_hello = deocrator_func(say_hello)
```

这里,`decorator_func`将会在`say_hello`函数的定义添加一些代码,然后返回修改版的函数或者包装函数.

## 带参数函数与修饰器

考虑以下带参数函数和修饰器的示例:

```python
import inspect

def decorator_func(say_hello_func):
  def wrapper_func(hello_var, world_var):
    hello = "Hello, "
    world = "World"

    if not hello_var:
      hello_var = hello

    if not world_var:
      world_var = world

    return say_hello_func(hello_var, world_var)

  return wrapper_func

@decorator_func
def say_hello(hello_var, world_var):
  print hello_var + " " + world_var


print inspect.getsource(say_hello)
# Output
'''
  def wrapper_func(hello_var, world_var):
    hello = "Hello, "
    world = "World"

    if not hello_var:
      hello_var = hello

    if not world_var:
      world_var = world

    return say_hello_func(hello_var, world_var)
'''

# Decorator equivalent code is
'''
say_hello = decorator_func(say_hello)  # Output is wrapper_func which accepts two parameters
'''

# This statement is equivalent to wrapper_func("Hello", "")
# Hence number of parameter to the main function and wrapper_func must be same
# In this case 2
say_hello("Hello", "")
```

这里,我们定义了个`say_hello`函数,带有两个参数,以及`@decorator_func`.`decorator_func`内部函数,例如`wrapper_func`,必须接收和`say_hello`一样个数的参数.

这里,`@decorator_func`检验传递的参数是否为空.如果是,它会以默认参数调用`say_hello`.

## 传递参数给修饰函数

为了给修饰函数传递参数,我们可以为修饰器书写包装函数,包装函数在内部定义修饰函数.例如:

```python
import inspect

def decorator_wrapper(parameter):
    print parameter

    def decorator(func):
        def wrapper(message):
            print "Wrapper start"
            func(message)
            print "Wrapper end"

        return wrapper

    return decorator


# Here, instead of having the decorator function object as in prevision cases,
# we are executing the decorator_wrapper function using the round brackets which returns the
# decorator function. So ultimately the code changes to
'''
decorator = decorator_wrapper("Decorator paramerter")
@decorator
def say_hello(message):
    print message
'''
@decorator_wrapper("Decorator parameter")
def say_hello(message):
    print message


print inspect.getsource(say_hello)
'''
    def wrapper(message):
        print "Wrapper start"
        func(message)
        print "Wrapper end"
'''

say_hello("Hello, world")
```
