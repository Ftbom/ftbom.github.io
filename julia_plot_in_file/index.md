# Julia脚本文件中使用Plots绘图


![julia.png](https://s2.loli.net/2022/02/28/MAk7Io6NtOiCxuB.png)

Julia是一种高级通用动态编程语言，可以用于数值分析和科学计算等。

Julia语言没有内建的作图能力，作图需要通过安装扩展包来实现，常用的作图包有Gadfly、Plots和PyPlot。

本文介绍如何在Julia脚本文件中使用Plots进行绘图并正常显示绘图结果。

{{< admonition warning "Julia和Plots版本" >}}
Julia v1.7.2

Plots v1.25.11
{{< /admonition >}}

## 在REPL中运行脚本文件

在REPL中，Julia会对每个变量自动调用`display`函数进行显示。在REPL中直接使用`plot`函数可以正常显示绘图的结果。

本文的主要目的是使用脚本文件进行绘图，在REPL中运行脚本文件的命令为：

```julia
include("path/to/script.jl")
```

## 使用`julia path/to/script.jl`运行脚本文件

如果不在REPL中运行脚本文件时，Julia不会自动调用`display`函数。

为了显示绘图结果，需要[在代码中调用`display`函数](https://docs.juliaplots.org/latest/tutorial/#Plotting-in-Scripts)。

但是，使用`julia path/to/script.jl`运行脚本文件时，程序会在文件中所有语句执行完毕后自动退出，这样就看不到绘图结果。

为了防止Julia执行完所有语句后退出，可以在脚本文件的末尾使用`readline`函数。

这种运行方式下需将代码做如下更改：

```julia
plot(x, y)
```

改为

```julia
display(plot(x, y))
...
readline()
```

然后终端运行`julia path/to/script.jl`即可得到绘图结果。

## 使用VScode插件Julia运行脚本文件

使用Julia插件运行代码时，会自动将绘图结果显示在一个新的标签栏中，于是直接使用`plot`函数就可以得到绘图结果。

需要注意的是：**在VScode中不可使用Code Runner插件来运行脚本文件，而要使用Julia插件来运行脚本文件**。
