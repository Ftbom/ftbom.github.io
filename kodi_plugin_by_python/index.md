# 基于Python的Kodi插件开发基础


<div style="text-align: center;">
    <img src="/blog_images/kodi_python.png" alt="kodi_python.png">
</div>

Kodi的插件可以与Kodi的GUI进行交互，提供额外的功能，可以分为`repository`、`plugin`、`script`、`skin`和`resource`5类。Kodi的插件可以使用Python或C++进行开发，这里介绍使用Python开发`plugin`类型插件的基础知识。

## 插件命名规则

插件命名规则为：`<addon-type>[.<media-type>].<your-plugin-name>`
* addon-type：插件类型
* media-type：插件提供的媒体类型
* your-plugin-name：插件名称

命名示例：plugin.video.videoscrapers

## 插件文件结构

Kodi中每个插件都有一个独立的文件夹，在这个文件夹包含插件代码、资源文件和插件信息文件，这个文件夹的名称应该和插件名相同。插件的文件结构一般如下：

```
addon.py
addon.xml
LICENSE.txt
resources/
  settings.xml
  language/
  lib/
  data/
  media/
  fanart.jpg (can be placed anywhere in the addon directory)
  icon.png (can be placed anywhere in the addon directory)
  banner.jpg (optional - can be placed anywhere in the addon directory)
  clearlogo.png (optional - can be placed anywhere in the addon directory)
  screenshot-1.jpg (optional - can be placed anywhere in the addon directory)
  screenshot-2.jpg (optional - can be placed anywhere in the addon directory)
  screenshot-3.jpg (optional - can be placed anywhere in the addon directory)
  screenshot-4.jpg (optional - can be placed anywhere in the addon directory)
```

* addon.py
  >插件的程序入口
* addon.xml
  >定义插件信息及依赖项等
* resources
  >包含资源文件和代码
* resources/settings.xml
  >包含插件的设置项
* resources/lib
  >一般包含插件的代码

### addon.xml

addon.xml文件示例如下：

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<addon id="plugin.video.videoscrapers" name="Video Scrapers" version="1.2.2" provider-name="Ftbom">
  <requires>
    <import addon="xbmc.python" version="3.0.0"/>
    <import addon="script.module.requests" version="2.12.4"/>
    <import addon="script.module.beautifulsoup4" version="4.3.2"/>
    <import addon="script.module.resolveurl" version="5.0.00"/>
    <import addon="script.module.cloudscraper" version="1.2.60"/>
  </requires>
  <extension point="xbmc.python.pluginsource" library="addon.py">
    <provides>video</provides>
  </extension>
  <extension point="xbmc.addon.metadata">
    <platform>all</platform>
    <summary lang="en">Video Scrapers</summary>
    <summary lang="zh_CN">视频聚合</summary>
    <description lang="en">Support scrape videos from multiple websites by simple plugins</description>
    <description lang="zh_CN">通过插件从多个网站爬取视频</description>
    <license>GNU GPLv2</license>
    <email>lz490070@gmail.com</email>
    <assets>
        <icon>resources/icon.png</icon>
        <fanart>resources/fanart.png</fanart>
    </assets>
  </extension>
</addon>
```

* addon
  >id：插件名
  >name：在Kodi中的显示名称
  >version：版本号
  >provider-name：作者名称
* requires定义插件依赖项
  >格式：`<import addon="xbmc.python" version="3.0.0"/>`
* extension > `point="xbmc.python.pluginsource"`
  >library：代码入口的文件名
  >`<provides>video</provides>`：插件提供的媒体类型
* extension > `point="xbmc.addon.metadata"`：定义插件信息
  >platform：适用平台
  >summary：插件简介，通过lang设置对应语言
  >description：插件介绍，通过lang设置对应语言
  >license：插件授权
  >email：作者邮箱
  >assets：定义插件图标、背景图和截图

### settings.xml

在settings.xml中可定义插件的设置项，包括设置项类型、id、显示名称、默认值

支持的[设置项类型](https://kodi.wiki/view/Add-on_settings#Elements)有：

* 分隔符
* 文本输入框
* 数字输入
* 时间和日期输入框
* 开关
* 选择框
* 滑块
* 滑动转盘
* 文件等浏览框
* 可执行按钮

示例如下：

```xml
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<settings>
    <category label="Scrape Web API">
        <setting id="scrapingant" type="text" label="Scrapingant API" default=""/>
        <setting id="scrapingbee" type="text" label="Scrapingbee API" default=""/>
        <setting id="zenscrape" type="text" label="Zenscrape API" default=""/>
        <setting id="scraperapi" type="text" label="Scraperapi API" default=""/>
        <setting id="api-select" type="select" label="选择API" values="scrapingant|scrapingbee|zenscrape|scraperapi" />
    </category>
    <category label="樱花动漫">
        <setting id="yhdm" type="bool" label="启用" default="true"/>
        <setting id="yhdm-url" type="text" label="域名" default="http://www.yinghuacd.com"/>
    </category>
</settings>
```

## 程序代码编写

在代码开发时，可以安装[Kodistubs](https://github.com/romanvm/Kodistubs)来辅助开发，提供代码提示。

Kodi中通过url来调用本插件和其他插件的功能，url的一般格式为：`plugin_baseurl?action=list_sources&xxx=xxx`
* plugin_baseurl用于指定插件
* url的params用于指定调用的函数和传递给函数的参数

### 文本格式化

Kodi显示的字符支持格式化，通过在字符串的前后添加字符块来实现[文本格式化](https://kodi.wiki/view/Label_Formatting)

### 可播放链接

Kodi可以在播放链接中添加headers等信息，格式如下：

`http[s]://[username[:password]@]host[:port]/directory/file?a=b&c=d|option1=value1&option2=value2`

### 插件初始化

在代码中通过sys来接收Kodi传递给插件的参数，参数包括三部分：
* `__url__`
  >插件对应的基础url，`__url__ = sys.argv[0]`
* `__handle__`
  >插件的handle，`__handle__ = int(sys.argv[1])`
* `__param__`
  >插件的params，`__param__ = sys.argv[2]`

插件初始化的代码一般为：

```python
import sys
import xbmcplugin

#插件信息
__url__ = sys.argv[0]
__handle__ = int(sys.argv[1])

xbmcplugin.setContent(__handle__, 'movies') #设置插件内容的类型
```

### 处理params

在插件的入口代码中需要处理接收到的params，来执行相应的功能：

```python
from urllib.parse import parse_qsl, quote, unquote

def routes(paramString):
    params = dict(parse_qsl(paramString[1 :]))
    if params:
        action = params['action']
        if action == 'list_indexs': #列出类别
            list_indexs(params['source'])
        elif action == 'list_videos': #列出指定类别下条目
            list_videos(params['source'], params['id'], int(params['page']))
        elif action == 'list_plays': #列出集
            list_plays(params['source'], params['id'])
        elif action == 'list_sources': #列出播放链接
            list_sources(params['source'], params['id'], params['title'], unquote(params['cover']), unquote(params['description']))
        elif action == 'list_search_results': #列出搜索结果
            if 'query' in params:
                list_search_results(params['query'], params['source'], int(params['page'])) #用于加载下一页
            else:
                list_search_results(None, params['source'], int(params['page'])) #用于键盘输入搜索
        elif action == 'add_favorite':
            add_favorite(params['data'])
        elif action == 'list_favorite':
            list_favorite()
        elif action == 'remove_favorite':
            remove_favorite(params['data'])
    else :
        mainMenu()
```

### 添加列表

在Kodi中添加列表项的代码示例如下：

```python
import xbmcgui
import xbmcplugin

def mainMenu():
    menuItems = []
    item = xbmcgui.ListItem(label = "[COLOR red]Test[/COLOR]")
    url = f'{__url__}?action=xxx' #action url
    menuItems.append((url, item, True))
    xbmcplugin.addDirectoryItems(__handle__, menuItems, len(menuItems)) #添加条目
    xbmcplugin.addSortMethod(__handle__, xbmcplugin.SORT_METHOD_NONE) #不排序
    xbmcplugin.endOfDirectory(__handle__) #添加结束
```
>* `xbmcgui.ListItem(label = "[COLOR red]Test[/COLOR]")`：列表项，通过label定义显示字符
>* `menuItems.append((url, item, True))`：添加列表项，包含列表项对应url，列表项以及是否是文件夹
>* `xbmcplugin.addDirectoryItems(__handle__, menuItems, len(menuItems))`：添加列表项列表
>* `xbmcplugin.addSortMethod(__handle__, xbmcplugin.SORT_METHOD_NONE)`：设置排序方式
>* `xbmcplugin.endOfDirectory(__handle__)`：结束

设置列表项的封面等：

```python
menuItem.setArt({'poster': cover_url}) #设置封面
menuItem.setInfo('video', {'plot': description}) #设置详情
```

添加列表项的右键菜单：

```python
menuItem.addContextMenuItems([("Test", f'RunPlugin({plugin_url})')])
```

添加可播放列表项：

```python
menuItem.setArt({'poster': cover_url})
menuItem.setInfo('video', {'genre': genre, 'plot': description})
menuItems.append((play_url, menuItem, False))
```
>* genre设置视频种类
>* play_url为可播放的视频链接
