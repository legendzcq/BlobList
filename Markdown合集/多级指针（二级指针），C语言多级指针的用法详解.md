多级指针就是指针的指针的指针...，实际上也没那么复杂，非常简单。本节来看看如何理解多级指针。

假如定义了一个二级指针：

```c
int **q;
```

q 的前面有两个`*`，这个该如何理解呢？与一级指针的理解是一样的。

`int**q` 可以把它分为两部分看，即` int*` 和` (*q)`，后面` (*q)` 中的`*`表示 `q` 是一个指针变量，前面的 `int*` 表示指针变量` q` 只能存放` int*` 型变量的地址。对于二级指针甚至多级指针，我们都可以把它拆成两部分。首先不管是多少级的指针变量，它都是一个指针变量，指针变量就是一个`*`，其余的`*`表示的是这个指针变量只能存放什么类型变量的地址。比如`int****a；`表示指针变量 `a` 只能存放` int***` 型变量的地址。

下面来举一个例子。假如定义了一个指针变量 `p` 指向一个` int` 型变量：

```c
int i = 10;int *p = &i;
```

前面讲过，指针变量的“基类型”用来指定该指针变量可以指向的变量的类型，即该指针变量只能存放什么类型变量的地址。所以 `int*p` 表示` p` 指向的是 `int` 型变量，里面只能存放` int` 型变量的地址。虽然 `p` 是指针变量，但只要是变量就有地址，就可以定义一个指针变量存放它：

```c
int **q = &p;
```

为什么存放 `&p` 要两个`*`呢？因为指针变量` p` 的基类型为` int` 型，所以` &p` 的基类型为` int*`型 。所以如果要定义一个能指向 `int*` 型变量的指针变量，有两个要求：首先它要是指针变量，即一个`*`；其次，该指针变量指向的是` int*` 型的数据，或者说存放的是` int*` 型变量的地址，所以就是 `int**`。

以上就是为什么需要两个`*`的原因。两`*`表示二级指针，就是指针的指针。二级指针需要两个`*`才能指向最终的内存单元，即` **q==i`。变量` q `中存放变量` *q` 的地址，变量` *q `中存放变量` **q` 的地址，变量` **q `中存放i的内容，即` 10`。或者说：`q `指向` *q`，`*q` 指向` **q`，`**q` 中存放i的内容，即` 10`。

同样，虽然` q `存放的是指针变量` p` 的地址，但它也有地址。所以也可以定义一个指针变量，里面存放` q `的地址：

```c
int ***r = &q;
```

`int***r` 就等价于` int***r`，所以` r `的基类型就是` int**` 型。而` q` 的基类型是` int*` 型，所以` &q `的基类型是` int**` 型。所以` r `有三个`*`才能指向` q `的地址。三个`*`表示三级指针，即指针的指针的指针。三级指针需要三个`*`才能指向最终的内存单元，即` ***r==i`。

下面来写一个程序：

```c
# include <stdio.h>
int main(void)
{
  int i = 10;
  int *p = &i;
  int **q = &p;
  int ***r = &q;
  printf("i = %d\n", ***r);
  
  return 0;
}

输出结果是：i = 10
```

这就是多级指针，也很简单，一定要弄清楚。

