# 如何理解Linux中的OOM(Out Of Memory Killer)机制？



Linux用户内存都是读写时分配，所以系统发现需要内存基本上都是发生在handle_mm_fault()的时候（其他特殊流程类似，这里忽略），handle_mm_fault()要为缺的页分配内存，就会调alloc_pages()系列函数，从而调prepare_alloc_pages()，进而进入__alloc_pages_direct_reclaim()，这里已经把可以清到磁盘上的缓冲都清了一次了。这样之后还是分配不到内存，就只好进入OMM Killer了（pagefault_out_of_memory()）。



到了这种状态，系统中的内存只有可能被正在运行的进程和内核占据了，大家都不让，系统就只有死。内核是官家，进程是商家，官家不能杀，只好杀商家，商家杀一个也是杀，杀十个也是杀，那就杀个最胖的，少拉点仇恨。也就只能这样了，换你，你能怎么选？



所以啊，这些个胖商家都不得不希望国家安定，民族富强，否则死的都是胖子。



至于OOM Killer这种叫法，一听就是自由软件的人想出来的，Linux很早的时候根本就没有什么OOM Killer，只有OOM（很接近OOP：）），OOP完就大家一起死翘翘。至于Unix这种打领带上班的，人家修养高，怎么可能OOP嘛，人家都是打电话给客户，用浓重的伦敦腔说“Dear Sir，你的，内存，大大地，不够了，你想怎么处理？”，然后很专业地，让你自己来杀进程或者热插内存。否则怎么好意思卖你几百万一台啊？

---



刚好最近遇到了几次OOM的问题。

Linux的OOM机制的存在跟它的overcommit特性有关。

所谓overcommit就是操作系统分配给进程的总内存大小超过了实际可用的内存，这样做的原因是进程实际上使用的内存往往比申请的内存要少。比如有个进程申请了1G的内存，但实际上它只在一小段时间里加载了大量数据，需要使用较大的内存，而在运行过程的其他大部分时间里只用了100M的内存。这样其实有900多M的内存在大部分时间里是闲置的，完全可以分给其他进程，overcommit的机制就能充分利用这些闲置的内存。

overcommit相关内容可以看下这里：[理解Linux的memory overcommit](https://link.zhihu.com/?target=http%3A//linuxperf.com/%3Fp%3D102)

Unix/Linux的内存分配策略是lazy的，申请的时候不会分配物理内存，只有在使用的时候才分配，为了尽可能地提高内存地利用效率，系统大部分情况下都会“答应”申请内存的要求。因为overcommit的存在，系统没办法在进程运行的时候就预判内存是否会耗尽，只有在真正分配内存的时候才会发觉：诶，内存不够了？这时候为了防止系统崩溃，只好用OOM killer牺牲掉一个或者几个进程了。相比系统崩溃，这种做法更可以接受一点。

个人理解OOM和overcommit算是一种trade-off，这种机制让系统尽可能地利用了物理内存，代价就是在某些情况下需要牺牲一些“无辜”的进程。在大部分情况下这种机制还是挺好用的，只要物理内存没被耗光就不会有什么问题。





Memory Overcommit的意思是操作系统承诺给进程的内存大小超过了实际可用的内存。一个保守的操作系统不会允许memory overcommit，有多少就分配多少，再申请就没有了，这其实有些浪费内存，因为进程实际使用到的内存往往比申请的内存要少，比如某个进程malloc()了200MB内存，但实际上只用到了100MB，按照UNIX/Linux的算法，物理内存页的分配发生在使用的瞬间，而不是在申请的瞬间，也就是说未用到的100MB内存根本就没有分配，这100MB内存就闲置了。下面这个概念很重要，是理解memory overcommit的关键：commit(或overcommit)针对的是内存申请，内存申请不等于内存分配，内存只在实际用到的时候才分配。

Linux是允许memory overcommit的，只要你来申请内存我就给你，寄希望于进程实际上用不到那么多内存，但万一用到那么多了呢？那就会发生类似“银行挤兑”的危机，现金(内存)不足了。Linux设计了一个OOM killer机制(OOM = out-of-memory)来处理这种危机：挑选一个进程出来杀死，以腾出部分内存，如果还不够就继续杀…也可通过设置内核参数 vm.panic_on_oom 使得发生OOM时自动重启系统。这都是有风险的机制，重启有可能造成业务中断，杀死进程也有可能导致业务中断，我自己的这个小网站就碰到过这种问题，[参见前文](http://linuxperf.com/?p=94)。所以Linux 2.6之后允许通过内核参数 vm.overcommit_memory 禁止memory overcommit。

内核参数 vm.overcommit_memory 接受三种取值：

- 0 – Heuristic overcommit handling. 这是缺省值，它允许overcommit，但过于明目张胆的overcommit会被拒绝，比如malloc一次性申请的内存大小就超过了系统总内存。Heuristic的意思是“试探式的”，内核利用某种算法（对该算法的详细解释请看文末）猜测你的内存申请是否合理，它认为不合理就会拒绝overcommit。
- 1 – Always overcommit. 允许overcommit，对内存申请来者不拒。
- 2 – Don’t overcommit. 禁止overcommit。

关于禁止overcommit (vm.overcommit_memory=2) ，需要知道的是，怎样才算是overcommit呢？kernel设有一个阈值，申请的内存总数超过这个阈值就算overcommit，在/proc/meminfo中可以看到这个阈值的大小：

```
# grep -i commit /proc/meminfo
CommitLimit:     5967744 kB
Committed_AS:    5363236 kB
```

CommitLimit 就是overcommit的阈值，申请的内存总数超过CommitLimit的话就算是overcommit。
这个阈值是如何计算出来的呢？它既不是物理内存的大小，也不是free memory的大小，它是通过内核参数vm.overcommit_ratio或vm.overcommit_kbytes间接设置的，公式如下：
【CommitLimit = (Physical RAM * vm.overcommit_ratio / 100) + Swap】

注：
vm.overcommit_ratio 是内核参数，缺省值是50，表示物理内存的50%。如果你不想使用比率，也可以直接指定内存的字节数大小，通过另一个内核参数 vm.overcommit_kbytes 即可；
如果使用了huge pages，那么需要从物理内存中减去，公式变成：
CommitLimit = ([total RAM] – [total huge TLB RAM]) * vm.overcommit_ratio / 100 + swap
参见https://access.redhat.com/solutions/665023

/proc/meminfo中的 Committed_AS 表示所有进程已经申请的内存总大小，（注意是已经申请的，不是已经分配的），如果 Committed_AS 超过 CommitLimit 就表示发生了 overcommit，超出越多表示 overcommit 越严重。Committed_AS 的含义换一种说法就是，如果要绝对保证不发生OOM (out of memory) 需要多少物理内存。

*“sar -r”是查看内存使用状况的常用工具，它的输出结果中有两个与overcommit有关，kbcommit 和 %commit：*
*kbcommit对应/proc/meminfo中的 Committed_AS；*
*%commit的计算公式并没有采用 CommitLimit作分母，而是Committed_AS/(MemTotal+SwapTotal)，意思是_内存申请_占_物理内存与交换区之和_的百分比。*

| 1234 | $ sar -r  05:00:01 PM kbmemfree kbmemused %memused kbbuffers kbcached kbcommit  %commit kbactive  kbinact  kbdirty05:10:01 PM  160576  3648460   95.78     0  1846212  4939368   62.74  1390292  1854880     4 |
| ---- | ------------------------------------------------------------ |
|      |                                                              |



###### 附：对Heuristic overcommit算法的解释

内核参数 vm.overcommit_memory 的值0，1，2对应的源代码如下，其中heuristic overcommit对应的是OVERCOMMIT_GUESS：

| 12345 | 源文件：source/include/linux/mman.h #define OVERCOMMIT_GUESS        0#define OVERCOMMIT_ALWAYS        1#define OVERCOMMIT_NEVER        2 |
| ----- | ------------------------------------------------------------ |
|       |                                                              |

Heuristic overcommit算法在以下函数中实现，基本上可以这么理解：
单次申请的内存大小不能超过 【free memory + free swap + pagecache的大小 + SLAB中可回收的部分】，否则本次申请就会失败。

```c
源文件：source/mm/mmap.c 以RHEL内核2.6.32-642为例
 
0120 /*
0121  * Check that a process has enough memory to allocate a new virtual
0122  * mapping. 0 means there is enough memory for the allocation to
0123  * succeed and -ENOMEM implies there is not.
0124  *
0125  * We currently support three overcommit policies, which are set via the
0126  * vm.overcommit_memory sysctl.  See Documentation/vm/overcommit-accounting
0127  *
0128  * Strict overcommit modes added 2002 Feb 26 by Alan Cox.
0129  * Additional code 2002 Jul 20 by Robert Love.
0130  *
0131  * cap_sys_admin is 1 if the process has admin privileges, 0 otherwise.
0132  *
0133  * Note this is a helper function intended to be used by LSMs which
0134  * wish to use this logic.
0135  */
0136 int __vm_enough_memory(struct mm_struct *mm, long pages, int cap_sys_admin)
0137 {
0138         unsigned long free, allowed;
0139 
0140         vm_acct_memory(pages);
0141 
0142         /*
0143          * Sometimes we want to use more memory than we have
0144          */
0145         if (sysctl_overcommit_memory == OVERCOMMIT_ALWAYS)
0146                 return 0;
0147 
0148         if (sysctl_overcommit_memory == OVERCOMMIT_GUESS) { //Heuristic overcommit算法开始
0149                 unsigned long n;
0150 
0151                 free = global_page_state(NR_FILE_PAGES); //pagecache汇总的页面数量
0152                 free += get_nr_swap_pages(); //free swap的页面数
0153 
0154                 /*
0155                  * Any slabs which are created with the
0156                  * SLAB_RECLAIM_ACCOUNT flag claim to have contents
0157                  * which are reclaimable, under pressure.  The dentry
0158                  * cache and most inode caches should fall into this
0159                  */
0160                 free += global_page_state(NR_SLAB_RECLAIMABLE); //SLAB可回收的页面数
0161 
0162                 /*
0163                  * Reserve some for root
0164                  */
0165                 if (!cap_sys_admin)
0166                         free -= sysctl_admin_reserve_kbytes >> (PAGE_SHIFT - 10); //给root用户保留的页面数
0167 
0168                 if (free > pages)
0169                         return 0;
0170 
0171                 /*
0172                  * nr_free_pages() is very expensive on large systems,
0173                  * only call if we're about to fail.
0174                  */
0175                 n = nr_free_pages(); //当前free memory页面数
0176 
0177                 /*
0178                  * Leave reserved pages. The pages are not for anonymous pages.
0179                  */
0180                 if (n <= totalreserve_pages)
0181                         goto error;
0182                 else
0183                         n -= totalreserve_pages;
0184 
0185                 /*
0186                  * Leave the last 3% for root
0187                  */
0188                 if (!cap_sys_admin)
0189                         n -= n / 32;
0190                 free += n;
0191 
0192                 if (free > pages)
0193                         return 0;
0194 
0195                 goto error;
0196         }
0197 
0198         allowed = vm_commit_limit();
0199         /*
0200          * Reserve some for root
0201          */
0202         if (!cap_sys_admin)
0203                 allowed -= sysctl_admin_reserve_kbytes >> (PAGE_SHIFT - 10);
0204 
0205         /* Don't let a single process grow too big:
0206            leave 3% of the size of this process for other processes */
0207         if (mm)
0208                 allowed -= mm->total_vm / 32;
0209 
0210         if (percpu_counter_read_positive(&vm_committed_as) < allowed)
0211                 return 0;
0212 error:
0213         vm_unacct_memory(pages);
0214 
0215         return -ENOMEM;
0216 }
```

 

参考：
https://www.kernel.org/doc/Documentation/vm/overcommit-accounting
https://www.win.tue.nl/~aeb/linux/lk/lk-9.html
https://www.kernel.org/doc/Documentation/sysctl/vm.txt
http://lwn.net/Articles/28345/