# ios 中的各种锁

---

### 线程安全

当一个线程访问数据的时候，其他的线程不能对其进行访问，直到该线程访问完毕。即，同一时刻，对同一个数据操作的线程只有一个。只有确保了这样，才能使数据不会被其他线程污染。而线程不安全，则是在同一时刻可以有多个线程对该数据进行访问，从而得不到预期的结果。

比如写文件和读文件，当一个线程在写文件的时候，理论上来说，如果这个时候另一个线程来直接读取的话，那么得到将是不可预期的结果。

为了线程安全，我们可以使用锁的机制来确保，同一时刻只有同一个线程来对同一个数据源进行访问。在开发过程中我们通常使用以下几种锁:

> - @synchronized
> - NSLock
> - NSRecursiveLock
> - NSCondition
> - NSConditionLock
> - pthread_mutex
> - pthread_rwlock
> - dispatch_semaphore
> - OSSpinLock
> - os_unfair_lock



### 总结:
应当针对不同的操作使用不同的锁，而不能一概而论那种锁的加锁解锁速度快。
当进行文件读写的时候，使用 pthread_rwlock 较好，文件读写通常会消耗大量资源，而使用互斥锁同时读文件的时候会阻塞其他读文件线程，而 pthread_rwlock 不会。
当性能要求较高时候，可以使用 pthread_mutex 或者 dispath_semaphore，由于 OSSpinLock 不能很好的保证线程安全，而在只有在 iOS10 中才有 os_unfair_lock ，所以，前两个是比较好的选择。既可以保证速度，又可以保证线程安全。
对于 NSLock 及其子类，速度来说 NSLock < NSCondition < NSRecursiveLock < NSConditionLock 。
实际开发当中:NSLock 是用来控制对方法的访问,synchronized用来控制对成员变量或属性的访问, atomic的本质也是synchronized.






