# 在Android设备上安装JupyterLab


## JupyterLab简介

[JupyterLab](https://jupyterlab.readthedocs.io/en/stable/)是一个基于Web的集成开发环境。在JupyterLab中可以通过安装kernel来运行各种代码，还可以在代码块之间插入Markdown文本，同时JupyterLab也提供了终端管理的功能。

Android设备易于携带，JupyterLab基于Web易于分享，通过在Android设备上安装JupyterLab，可以获得一个强大又便捷的集成开发环境。

虽然可以通过[Pydroid3](https://play.google.com/store/apps/details?id=ru.iiec.pydroid3)方便地安装JupyterLab，但为了充分使用其强大的功能，推荐使用[Termux](https://termux.com/)或[UserLAnd](https://userland.tech/)来安装JupyterLab。

## 在Termux中安装JupyterLab

Termux是Android系统上的一个高级终端模拟器，可以运行很多Linux系统的软件。通过Termux，在Android系统上可以获得类似于Linux系统的使用体验。Termux的使用教程推荐国光大佬的[Termux 高级终端安装使用配置教程](https://www.sqlsec.com/2018/05/termux.html)。

### Termux初始化

Termux第一次启动时需要联网进行初始化。
>如果初始化失败请尝试使用代理

初始化完成后输入以下代码获取存储空间访问权限：

```bash
termux-setup-storage
```

### 安装Python和各项依赖

安装Python：

```bash
pkg install python
```

使用pkg命令安装rrj包时会先更新软件源再进行安装。

安装所需依赖：

```bash
pkg install clang python fftw libzmq freetype libpng pkg-config libcrypt
```

### 安装JupyterLab并运行

在Termux中安装的Python已经带有pip，通过以下命令安装JupyterLab：

```bash
pip install jupyterlab
```

运行:

```bash
jupyter-lab
```

运行Notebook：

```bash
jupyter notebook
```

## 在UserLAnd中安装JupyterLab

UserLAnd使Linux发行版和Linux软件可以在Android设备上运行，而无需root权限。UserLAnd提供多种Linux发行版和软件供用户安装，推荐安装Ubuntu系统，使用SSH作为连接方式。

### UserLAnd安装Ubuntu

连接上网络后选择Ubuntu系统，设置用户名、密码和VNC密码并选择一种连接方式，然后下载即可。
>如果安装失败请尝试使用代理

### 安装Python3和各项依赖

安装完成后使用选择的连接方式登入系统，进行Python和依赖的安装。

首先更新软件源：

```bash
sudo apt update
```

安装Python3：

```bash
sudo apt install python3
```

安装所需依赖：

```bash
sudo apt install python3-dev python3-pip python3-pyrsistent
```

将JupyterLab的安装目录添加到环境变量：

```
#将username更改为设置的用户名
export PATH=$PATH:/home/username/.local/bin
```

### 安装JupyterLab并运行

安装JupyterLab：

```bash
pip install jupyterlab
```

运行:

```bash
jupyter-lab
```

运行Notebook：

```bash
jupyter notebook
```

## 配置JupyterLab允许其他设备访问

JupyterLab默认不允许其他设备访问，可通过更改配置文件来允许其他设备访问。

查看.jupyter目录下的文件：

```bash
ls ~/.jupyter
```

由于jupyter_notebook_config.json文件的优先级高于其他配置文件，若存在jupyter_notebook_config.json文件则删除此文件：

```bash
rm ~/.jupyter/jupyter_notebook_config.json
```

生成配置文件：

```bash
jupyter notebook --generate-config
```
配置文件名为jupyter_notebook_config.py。

当JupyterLab能被其他设备访问时，最好为JupyterLab设置访问密码。设置密码需要生成密码的散列值，这样即使获取到了散列值，也几乎无法逆向获取到密码。

打开Python交互界面，运行以下代码并按提示输入密码：

```python
from notebook.auth import passwd
passwd()
```

输出结果即为密码的散列值。

打开jupyter_notebook_config.py，对如下选项进行设置：

```python
c.NotebookApp.ip = '*'  # 允许访问JupyterLab的IP，*表示任意IP
c.NotebookApp.password = u'生成的密码散列值'
c.NotebookApp.port = 8888 # 使用的端口，默认8888
c.NotebookApp.token = '' # 不使用token
```

设置好后就可以通过`http://ip:port`访问JupyterLab了。
