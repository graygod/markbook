====
你好
====

:date: 2012-08-32
:title: title
:publish: YES

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
