====
欢迎
====

:author: amoblin
:date: 2012-08-31
:title: 欢迎页
:publish: YES

MarkBook是什么？
================

MarkBook是用来管理markup文件的，目前仅支持RestructuredText文件，后续会加入MarkDown支持。

通过像类似EverNote的界面来管理，组织markup文件，实时更新显示html输出页面。

自动发布博客到Octopress站点。

使用MarkBook
=============

管理笔记
--------

MarkBook的文档路径为~/MarkBook/notes，在notes目录下创建目录或以rst为后缀的文件，MarkBook界面边栏会同步显示。

点击边栏里的rst文件，右边会显示对应的HTML输出内容。

双击边栏里的rst文件，这时系统默认编辑器会打开此rst文件，修改完毕，保存，MarkBook会更新HTML输出。

若要修改rst文件的默认打开方式，请选中一个rst文件，右键，选择“显示简介”，找到"打开方式"，选择您喜爱的编辑器，比如MacVim，TextMate等，然后点击 "全部更改..."，这样下次双击MarkBook边栏中的rst文件，就会用您选择的编辑器打开了。

导入jekyll/Octopress博客
-------------------------

File -> Import Notes...，选择jekyll或Octopress博客的_posts目录，即可将该目录下的博客文章导入到MarkBook中管理。

自带语法高亮
------------

下面是c代码样例：

.. code-block:: c

    #include <stdio.h>

    int main() {
        char* a[3];
        int i;

        a[0] = "你好";
        a[1] = "hello";
        a[2] = "world!";

        printf("a's address is: %p\n", a);
        for(i=0; i<3; i++) {
            printf("%p: %s\n", a[i], a[i]);
        }
    }

TODO
====

Git版本控制
------------

像Xcode一样显示文件状态，同时添加git pull，git push按钮。

发布到博客
----------

如果在rst文件内定义了如下内容：

.. code-block:: rst

    .. |date| date:: 2012-08-31
    .. title:: first-blog
    .. publish: YES

就会在 ~/octopress/source/_posts/目录下创建 2012-08-31-first-blog.rst的博客文件，publish为NO时删除上述文件。

