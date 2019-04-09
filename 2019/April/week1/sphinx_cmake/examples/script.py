"""这是一个示例脚本."""
import sys


def hello(name):
    """返回问候语."""
    return "你好 {}!".format(name)


if __name__ == "__main__":
    name = sys.argv[1]
    print(hello(name))
