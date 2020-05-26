# coding=utf8
import collections
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor, as_completed, wait
import threading
from threading import Lock, RLock, Condition
import time


# 共享变量(非线程安全)

# urls = []
#
# def put():
#     global urls
#     urls.append('www.baidu.com')
#
# def get():
#     global urls
#     url = urls.pop()
#     print(url)
#
# thread1 = threading.Thread(target=put)
# thread2 = threading.Thread(target=get)
#
# thread1.start()
# thread2.start()
# thread1.join()
# thread2.join()


# total = 0
#
# def add():
#     global total
#     for _ in range(1000000):
#         total += 1
#
# def desc():
#     global total
#     for _ in range(1000000):
#         total -= 1
#
#
# thread1 = threading.Thread(target=add)
# thread2 = threading.Thread(target=desc)
# thread1.start()
# thread2.start()
# thread1.join()
# thread2.join()
# print(total)


#互斥锁
# total = 0
# lock = RLock()
#
# def add():
#     global total
#     for _ in range(1000000):
#         lock.acquire()
#
#         total += 1
#         print(total)
#         lock.release()
#
# def desc():
#     global total
#     for _ in range(1000000):
#         lock.acquire()
#         total -= 1
#         print(total)
#         lock.release()
#
#
# thread1 = threading.Thread(target=add)
# thread2 = threading.Thread(target=desc)
# thread1.start()
# thread2.start()
# thread1.join()
# thread2.join()
# print(total)


# 信号量

# class Crawler(object):
#     sem = threading.Semaphore(3)
#
#     def getHtml(self):
#         time.sleep(1)
#         print("get html text success")
#         self.sem.release()
#
#     def start(self):
#         for _ in range(10):
#             self.sem.acquire()
#             thread = threading.Thread(target=self.getHtml)
#             thread.start()
#             thread.join()
#
# Crawler().start()

# 多进程/进程池

# import os
#
# msg = "multiprocess test"
# pid = os.fork()
#
# if pid == 0:
#     print(msg)
#     print('我是子进程，我的 pid 是 {}, 我爸的 pid 是 {}'.format(os.getpid(), os.getppid()))
# else:
#     print(msg)
#     print('我是父进程，我的 pid 是 {}'.format(os.getpid()))
#
# import multiprocessing
#
# def get_html(n):
#     time.sleep(n)
#     print("sub_process success")
#     return n
#
# pool = multiprocessing.Pool(multiprocessing.cpu_count())
# for result in pool.imap_unordered(get_html, [1, 5, 3]):
#     print("{} sleep success".format(result))


# 消息队列/ 管道

from multiprocessing import Process, Queue, Pool, Manager, Pipe

def producer(queue):
    local_time = time.strftime('%H:%M:%S', time.localtime())
    queue.put(local_time)
    time.sleep(2)

def consumer(queue):
    print(queue.get())

queue = Manager().Queue(10)
pool = Pool(2)
pool.apply_async(producer, args=(queue, ))
pool.apply_async(consumer, args=(queue, ))
pool.close()
pool.join()

#
# from multiprocessing import Process, Queue, Pool, Manager, Pipe
#
# def producer(pipe):
#     local_time = time.strftime('%H:%M:%S', time.localtime())
#     pipe.send(local_time)
#     time.sleep(2)
#
# def consumer(pipe):
#     print(pipe.recv())
#
#
# recive_pipe, send_pipe = Pipe()
#
# my_producer = Process(target=producer, args=(send_pipe, ))
# my_consumer = Process(target=consumer, args=(recive_pipe, ))
#
# my_producer.start()
# my_consumer.start()
# my_producer.join()
# my_consumer.join()
