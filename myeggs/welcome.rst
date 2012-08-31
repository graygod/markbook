====
欢迎
====

:author: amoblin
:date: 2012-08-31
:title: 欢迎页
:publish: YES

STEP 1
=======

通过任何方法在当前目录添加文件夹，MarkBook会同步显示。

添加后缀为rst的restructureText文件，MarkBook会显示对应的HTML页面。

双击rst文件可使用编辑器打开rst文件。

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
