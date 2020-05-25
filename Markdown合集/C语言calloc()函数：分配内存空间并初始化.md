# C语言calloc()函数：分配内存空间并初始化

头文件：#include <stdlib.h>

calloc() 函数用来动态地分配内存空间并初始化为 0，其原型为：
  void* calloc (size_t num, size_t size);

calloc() 在内存中动态地分配 num 个长度为 size 的连续空间，并将每一个字节都初始化为 0。所以它的结果是分配了 num*size 个字节长度的内存空间，并且每个字节的值都是0。

【返回值】分配成功返回指向该内存的地址，失败则返回 NULL。

如果 size 的值为 0，那么返回值会因标准库实现的不同而不同，可能是 NULL，也可能不是，但返回的指针不应该再次被引用。

注意：函数的返回值类型是 void *，void 并不是说没有返回值或者返回空指针，而是返回的指针类型未知。所以在使用 calloc() 时通常需要进行强制类型转换，将 void 指针转换成我们希望的类型，例如：

```c
char *ptr = (char *)calloc(10, 10);  // 分配100个字节的内存空间
```


calloc() 与 [malloc()](http://c.biancheng.net/cpp/html/137.html) 的一个重要区别是：calloc() 在动态分配完内存后，自动初始化该内存空间为零，而 malloc() 不初始化，里边数据是未知的垃圾数据。下面的两种写法是等价的：

```c
// calloc() 分配内存空间并初始化
char *str1 = (char *)calloc(10, 2);
// malloc() 分配内存空间并用 memset() 初始化
char *str2 = (char *)malloc(20);memset(str2, 0, 20);
```


代码示例：

```c
#include <stdio.h>
#include <stdlib.h>
int main (){    
  int i,n;    
  int * pData;    
  printf ("要输入的数字的数目：");    
  scanf ("%d",&i);    
  pData = (int*) calloc (i,sizeof(int));    
  if (pData==NULL) exit (1);    
  for (n=0;n<i;n++)    
  {        
    printf ("请输入数字 #%d：",n+1);        
    scanf ("%d",&pData[n]);    
  }    
  printf ("你输入的数字为：");    
  for (n=0;n<i;n++) printf ("%d ",pData[n]);       
  free (pData);    
  system("pause");    
  return 0;
}
```

运行结果：
要输入的数字的数目：4
请输入数字 #1：126
请输入数字 #2：343
请输入数字 #3：45
请输入数字 #4：234
你输入的数字为：126 343 45 234

上面的程序会将你输入的数字存储起来，然后输出。因为在程序运行时根据你的需要来动态分配内存，所以每次运行程序你可以输入不同数目的数字。