# LANraragi插件小记


![LANraragi.png](https://s2.loli.net/2023/01/03/8CywF4Z9hmqbJMn.png)

LANraragi提供了丰富的插件和脚本，借助插件能够以多种途径获取漫画的信息，但是这些插件并没有完全满足我的需求。

于是有了这篇文章，记录我的LANraragi插件编写过程。

## 需求

在LANraragi中，漫画的信息被记录成`tags`和`categories`，即标签和种类。

我的需求是能从文件的目录结构提取出漫画的标签和种类，文件的结构如下：

```
category1
  --tag1
      --mangafile1
      --mangafile2
  --tag2
      --mangafile3
category2
  --tag3
      --mangafile4
```

## 折腾结果

LANraragi中并不存在实现上述功能的插件，于是我就参照已有的插件，实现了这些功能。

最终完成了一个脚本和一个插件：

* TagFolder.pm(插件)
>将文件所属的文件夹名作为漫画的tag
* TopfolderCat.pm(脚本)
>将文件所属的顶层文件夹名作为漫画的category

### TagFolder.pm

>参照Filename Parsing v.1.0 by Difegue

<p style="text-align: center;">
    <img src="https://s2.loli.net/2023/01/03/2APOe4tX8qiyKlY.png" alt="tagfolder.png">
</p>

使用说明：
* Plugin Settings设置tag的类别，如图中所示则最终tag效果为`artist: tagname`
* 开启Run Automatically则自动对新添加的漫画运行插件

文件内容：

```perl
package LANraragi::Plugin::Metadata::TagFolder;

use strict;
use warnings;

#Plugins can freely use all Perl packages already installed on the system
#Try however to restrain yourself to the ones already installed for LRR (see tools/cpanfile) to avoid extra installations by the end-user.
use File::Basename;

#You can also use the LRR Internal API when fitting.
use LANraragi::Model::Plugins;
use LANraragi::Utils::Database qw(redis_encode redis_decode);
use LANraragi::Utils::Logging qw(get_logger);

#Meta-information about your plugin.
sub plugin_info {

    return (
        #Standard metadata
        name      => "Use foldername as tag",
        type      => "metadata",
        namespace => "tagfolder",
        author    => "Ftbom",
        version   => "1.0",
        description =>
          "Generate the tag from the folder's name.",
        icon =>
          "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAL1JREFUOI1jZMABpNbH/sclx8DAwPAscDEjNnEMQUIGETIYhUOqYdgMhTPINQzdUEZqGIZsKBM1DEIGTOiuexqwCKdidDl0vtT62P9kuZCJEWuKYWBgYGBgRHbh04BFDNIb4jAUbbSrZTARUkURg6lD10OUC/0PNaMYgs1Skgwk1jCSDCQWoBg46dYmhite0+D8pwGLCMY6uotRDOy8toZBkI2HIhcO/pxCm8KBUkOxFl/kGoq3gCXFYFxVAACeoU/8xSNybwAAAABJRU5ErkJggg==",
        parameters => [ { type => "string", desc => "The category of tag" } ] #plugin设置
    );

}

#Mandatory function to be implemented by your plugin
sub get_tags {

    shift;
    my $lrr_info = shift;    # Global info hash
    my ($category) = @_;    # Plugin parameters

    my $logger = get_logger( "tagfolder", "plugins" );
    my $file   = $lrr_info->{file_path}; #完整文件地址
    my $tagstring;

    # lrr_info's file_path is taken straight from the filesystem, which might not be proper UTF-8.
    # Run a decode to make sure we can derive tags with the proper encoding.
    $file = redis_decode($file);

    # Get the filename from the file_path info field
    my ( $filename, $filepath, $suffix ) = fileparse( $file, qr/\.[^.]*/ );

    $_ = "$filepath"; #获取文件地址
    if (/\/([^\/]+)\/$/)
    {
        $tagstring="$category:$1"; #上级目录作tag名
    }
    $logger->debug( "Sending the following tags to LRR: " . $tagstring );
    return ( tags => $tagstring );

}
1;
```

### TopfolderCat.pm

>参照Subfolders to Categories v.1.0 by Difegue 

<p style="text-align: center;">
    <img src="https://s2.loli.net/2023/01/03/Z96rHIguPKBhnXE.png" alt="TopfolderCat.png">
</p>

使用说明：
* 点击Trigger Script运行脚本
* Plugin Settings设置是否先删除以有的类型

文件内容：

```perl
package LANraragi::Plugin::Scripts::TopfolderCat;

use strict;
use warnings;
use File::Find;
use File::Basename;
use Data::Dumper;

use LANraragi::Utils::Logging qw(get_logger);
use LANraragi::Utils::Generic qw(is_archive);
use LANraragi::Utils::Database qw(compute_id);
use LANraragi::Model::Category;

our $fatherdirname;

#Meta-information about your plugin.
sub plugin_info {

    return (
        #Standard metadata
        name      => "Top Subfolders to Categories",
        type      => "script",
        namespace => "Tfldr2cat",
        author    => "Ftbom",
        version   => "1.0",
        icon =>
          "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAuJJREFUOI3FlE1sVFUUx3/nvVdaSqd0sAmElDYopOWjsKiEnYkLowU2uMGw0ajBhS5oqAtwo3FTaIQNCz7CBldEE01M+AglJMACUyBQrI6iQ2groNNxpjPz5n3MnXddvOnrfACNK09yk/fuved3//933j3wf8Thw6O6q6tHd3X16FOnTusX7ZW7I7H0kuUrV6hCtmHxt7UnOXHiDInEJAAzM49kscMtw2xesWHfKOTGASNa+GnmHfYP7gSgr28TY2PnF4UBWAD88Tlk7kFVyuDbX0ew43vzU/6bnc+12vnqx4OrX//i4gIQXS2uJkZGvqRXD3Q/V9LKXdjmSxcmjq7ahi6vtRazMKAHGua8oolbsHDyFk7iF4r/3IOyGl9QKI1u+vo2kUhMsmZ3T8Pa5c+E5vYYzbFWWkQTW23R+XKc+9/+eKUB+MbBHZWqhpW9MGSjtdDes57OzRtZ2hFD4tshcEAVkHIeVIapse8wDPNQxbKBDuDhxHKODd5myZ44698dBTQgUbEkex0CFzJXIfDC58CDwCP3Z1ZtPpAaD4FWnJIv2Nkm+j85AroE/jRoHwI/SgoBbt27h+54DS3je0VEh7VtimOnm2mKxRcguhpUDXvGUDb9bd3fh14rCtNPWuh9/6s6RfWq6mEetG0le/cb5KPbpajKActwChaIVNR5ddAqeLkCmt9TLjCbzEVFtQDstENTW0c4M58cJbiNsPmxtBs7eQ03p87VANP3J+n94CjiPKj76N4z7M4f6IPKk35YAFMORUCzpRU3/VdoV82BytUm+jMQlEArlBJmEyncORdnroTypxCRt7YMp5IRUBVzv/cPnV0n+VshyH8MgYuycyjHJjPt4GbyONki5VIAItfQnBeTG62YD1458DTF8EJXscSw1lEu4s0m8TJ/k/o5iZuZIygHlb+ZHwzkUoC+2T+cuiNSd08/re1qMjFa25YM5D0xjVtGe8fUhg9/zfMf41+ZdKPYI8TqHgAAAABJRU5ErkJggg==",
        description =>
          "Scan your Content Folder and automatically create Static Categories for each top subfolder.",
        parameters =>
          [ { type => "bool", desc => "Delete all your static categories before creating the ones matching your subfolders" } ]
    );

}

# Mandatory function to be implemented by your script
sub run_script {
    shift;
    my $lrr_info          = shift;
    my ($delete_old_cats) = @_;
    my $logger            = get_logger( "Folder2Category", "plugins" );
    my $userdir           = LANraragi::Model::Config->get_userdir;

    my %subfolders;
    my @created_categories;

    if ($delete_old_cats) {
        $logger->info("Deleting all Static Categories before folder walking as instructed.");

        my @categories = LANraragi::Model::Category->get_category_list;
        for my $category (@categories) {
            if ( %{$category}{"search"} eq "" ) {
                my $cat_id = %{$category}{"id"};
                $logger->debug("Deleting '$cat_id'");
                LANraragi::Model::Category::delete_category($cat_id);
            }
        }
    }

    # Walk through content folder and find all subfolders with files in them
    find(
        {   wanted => sub {
                return if $File::Find::dir eq $userdir;    # Direct children of the content dir are excluded
                if ( is_archive($_) ) {
                    unless ( exists( $subfolders{$fatherdirname} ) ) {
                        $subfolders{$fatherdirname} = [];        # Create array in hash for this folder
                    }
                    push @{ $subfolders{$fatherdirname} }, $_;
                }
                else
                {
                    $fatherdirname = basename($File::Find::dir);
                }
            },
            no_chdir    => 1,
            follow_fast => 1
        },
        $userdir
    );

    $logger->debug( "Find routine results: " . Dumper %subfolders );

    # For each subfolder with file, create a category bearing its name and containing all its files
    for my $folder ( keys %subfolders ) {
        my $catID = LANraragi::Model::Category::create_category( $folder, "", 0, "" );
        push @created_categories, $catID;

        for my $file ( @{ $subfolders{$folder} } ) {
            my $id = compute_id($file) || next;
            LANraragi::Model::Category::add_to_category( $catID, $id );
        }
    }
    #顶级目录名作分类名
    return ( created_categories => \@created_categories );

}

1;
```

## 代码浅析

简单分析一下这两个插件的代码，我并没有系统地学习过Perl语言，分析过程可能存在错误。

`plugin_info`函数返回插件的基本信息；TagFolder是元数据插件，主体内容是`get_tags`函数；TopfolderCat是脚本，主体内容是`run_script`函数。

`plugin_info`函数的parameters返回值定义了插件的设置项，例如：
TagFolder定义插件的设置项是string类型，获取输入字符；TopfolderCat定义插件的设置项是bool类型，获取开关的状态。

在主体函数中可以通过`@_`获取插件的设置值。

### TagFolder.pm分析

TagFolder参照Filename Parsing，对其中关键代码的运行过程进行分析。

首先获取全局信息和插件设置：

```perl
my $lrr_info = shift; #全局信息
my ($category) = @_; #插件设置
```

全局信息中包括文件路径：

```perl
my $file   = $lrr_info->{file_path};
```

然后从文件路径中分离出文件名和文件所在文件夹路径，我们需要的是文件夹路径：

```perl
my ( $filename, $filepath, $suffix ) = fileparse( $file, qr/\.[^.]*/ );
```

从文件夹路径中获取文件夹名，得到tag字符串：

```perl
$_ = "$filepath"; #$_是默认的参数变量
if (/\/([^\/]+)\/$/)
{
    $tagstring="$category:$1"; #$1获取正则表达式匹配的第一项
}
```

最后输出tag信息：

```perl
return ( tags => $tagstring );
```

### TopfolderCat.pm分析

TopfolderCat.pm参照Subfolders to Categories，相较于参考文件改动较小，改动部分为：

```perl
return if $File::Find::dir eq $userdir;    # Direct children of the content dir are excluded
if ( is_archive($_) ) {
    unless ( exists( $subfolders{$fatherdirname} ) ) {
        $subfolders{$fatherdirname} = [];        # Create array in hash for this folder
    }
    push @{ $subfolders{$fatherdirname} }, $_;
}
else
{
    $fatherdirname = basename($File::Find::dir);
}
```

这里假设文件目录结构为：

```
category1
  --tag1
      --mangafile1
      --mangafile2
  --tag2
      --mangafile3
category2
  --tag3
      --mangafile4
```

首先排除漫画目录的直接子文件夹，即categroy1、categroy2等文件夹：

```perl
return if $File::Find::dir eq $userdir;
```

对于其他的文件和文件夹，如果是文件夹，即tag1、tag2等文件夹，则将其父目录的名称赋值给`fatherdirname`。即将categroy1、categroy2等赋值给`fatherdirname`:

```perl
else
{
    $fatherdirname = basename($File::Find::dir);
}
```

如果是文件，若其路径中存在`fatherdirname`，则将其添加到对应数组。例如：mangafile1、mangafile2、mangafile3文件被添加到category1对应的数组：

```perl
if ( is_archive($_) ) {
    unless ( exists( $subfolders{$fatherdirname} ) ) {
        $subfolders{$fatherdirname} = [];        # Create array in hash for this folder
    }
    push @{ $subfolders{$fatherdirname} }, $_;
}
```

最后通过这些数组来创建类别，并将对应漫画添加到类别中：

```perl
for my $folder ( keys %subfolders ) {
    my $catID = LANraragi::Model::Category::create_category( $folder, "", 0, "" );
        push @created_categories, $catID;

        for my $file ( @{ $subfolders{$folder} } ) {
            my $id = compute_id($file) || next;
            LANraragi::Model::Category::add_to_category( $catID, $id );
        }
    }
```
