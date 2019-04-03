# [使用 Jenkins 及 CMake 进行 C++自动化构建简介](https://thoughts-on-cpp.com/2019/03/27/introduction-into-build-automation-setup-with-jenkins-and-cmake/)

本文章将会基于 Jenkins 及 CMake,提供 C++自动化构建设置的介绍,并满足以下需求:

- 在每次提交时构建一个可随时部署的版本
- 执行所有的测试
- 运行静态代码分析用于追踪代码质量
- 可以很方便地通过自动部署(CD)进行扩展

这里提供了一个[GitHub 仓库](https://github.com/Ben1980/jenkinsexample),包含了必须的资源.我们将聚焦于自动化构建流程的技术部分,这部分是 CI/CD(持续集成/持续部署)流程的必要条件.对于一家公司而言,全面接受 CI/CD 流程背后的理念比利用其中的工具更为必要.不过,至少自动化构建和测试设置是一个良好的开端.

要构建的目标,一个基于 Qt 和 C++的示例桌面端程序,将会使用`Jenkins declarative pipeline`实现.示例程序是使用 CLion 生成的简单 CMake 工程.对于静态代码分析工具,这里使用`cppcheck`.测试框架则选用`Catch2`.

在本文中,我假设你已经熟悉了基本的 Jenkins 设置.如果你不熟悉 Jenkins,可以先通过[jenkins.io](https://jenkins.io/)来了解.

Jenkins 由定义到文件中的声明性管道组成,文件为 Jenkinsfile.这个文件必须位于工程根目录.Jenkins 的声明性管道是基于 Groovy 的领域特定语言(DSL),提供了 f 一种非常有表现力的方式来定义构建流程.尽管这个 DSL 基于 Groovy,非常强大,你实际上只需要编写很少的脚本,但是它的文档很不幸,将基于脚本的管道和其预处理器混淆在一起. 对于我们的示例,可能实现如下:

```jenkins
pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        booleanParam name: 'RUN_TESTS', defaultValue: true, description: 'Run Tests?'
        booleanParam name: 'RUN_ANALYSIS', defaultValue: true, description: 'Run Static Code Analysis?'
        booleanParam name: 'DEPLOY', defaultValue: true, description: 'Deploy Artifacts?'
    }

    stages {
        stage('Build') {
            steps {
                cmake arguments: '-DCMAKE_TOOLCHAIN_FILE=~/Projects/vcpkg/scripts/buildsystems/vcpkg.cmake', installation: 'InSearchPath'
                cmakeBuild buildType: 'Release', cleanBuild: true, installation: 'InSearchPath', steps: [[withCmake: true]]
            }
        }

        stage('Test') {
            when {
                environment name: 'RUN_TESTS', value: 'true'
            }
            steps {
                ctest 'InSearchPath'
            }
        }

        stage('Analyse') {
            when {
                environment name: 'RUN_ANALYSIS', value: 'true'
            }
            steps {
                sh label: '', returnStatus: true, script: 'cppcheck . --xml --language=c++ --suppressions-list=suppressions.txt 2> cppcheck-result.xml'
                publishCppcheck allowNoReport: true, ignoreBlankFiles: true, pattern: '**/cppcheck-result.xml'
            }
        }

        stage('Deploy') {
            when {
                environment name: 'DEPLOY', value: 'true'
            }
            steps {
                sh label: '', returnStatus: true, script: '''cp jenkinsexample ~
                cp test/testPro ~'''
            }
        }
    }
}
```

语法非常直接,一个 Jenkinsfile 总是以管道块声明开始,后面跟随了`agent`的声明.`agent`描述了我们的构建应当运行的环境.在这里,我们希望其在任何环境设置上都能工作,但是它也可以是一个环境标签,或者一个`docker`环境.

使用选项-`options`指令,我们定义了我们希望保留最新的 10 次构建及代码分析结果.通过选项设置我们也可以定义构建超时,构建失败的情况下允许尝试的次数,或者执行构建时向终端输出的时间戳.

参数-`parameters`指令使得我们可以定义各种类型的构建参数,譬如`string`,`text`,`booleanParam`,`choice`,`file`以及`password`.在这里,我们使用`booleanParam`来为用户提供选项定义当用户手动执行工程构建时可以执行的附加阶段内容.

![布尔参数示例](https://thoughtsoncpp.files.wordpress.com/2019/03/jenkinsparameters.png)

虽然 Jenkins 可以进行各种各样强大,有趣的配,对于构建流程来讲最重要的部分是由`stage`指令定义的`stages`段.通过任意数量的阶段,我们可以根据需要自由定义构建过程.甚至是并行阶段,譬如并发执行测试用例和静态代码分析也是可以做到的.

在最初的阶段,`Build`,我们通过 Jenkins 指令来调用其 CMake 插件生成我们的构建设置,并且将定义在`Vcpkg`CMake 文件中的所有必须依赖都准备好.之后,通过`withCmake:true`设置,构建通过`cmake --build .`执行.自定义的工具链也没有问题,这样我们可以分别使用 GCC,Clang 和 Visual Studio 的编译器来定义多个不同的构建设置.

其他阶段,譬如测试-Test,分析-Analyse,部署-Deploy,描述起来也非常直接.它们有一个共同点就是使用了`when`指令,通过这个指令,如果花括号内的条件返回了`true`,我们可以控制是否执行某个阶段.在这里,我们使用最初我们定义的构建参数来运算出结果.乍一看语法可能有点刺激,但毕竟它确实起作用了.

为了让 Jenkins 执行我们的管道定义,我们只需要告诉它从那个仓库拉取即可.这个可以通过工程配置实现.这里你只需要选择`Pipeline script from SCM`选项.如果一切设置正确,你最终就获得了可以平稳运行的自动化构建流程.如果你正确配置了 Jenkins,有静态链接(应该是指 IP 固定)可以链接到互联网,你甚至可以通过`Webhook`连接 Jenkins 到 Github.这意味着一旦有人向仓库提交变动,Github 就会调用构建流程.

![Github与Jenkins](https://thoughtsoncpp.files.wordpress.com/2019/03/jenkinssourcecontrolconnection.png)

最后总结,我想指出这并不是配置自动化构建的最好方式.这只是其中一种方法,这种方法在我的日常工作中工作得很好.几年前我在我们公司介绍了这个改编版本,Jenkins 从那时起为我们服务. Jenkins 声明性管道,在版本仓库上就跟其他代码一样可以进行版本控制,这是一个非常重要的特性.
