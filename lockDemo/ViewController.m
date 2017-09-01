//
//  ViewController.m
//  lockDemo
//
//  Created by Jianmei on 2017/8/31.
//  Copyright © 2017年 Jianmei. All rights reserved.
//

#import "ViewController.h"
#include<pthread.h>
#import <libkern/OSAtomic.h>

@interface ViewController ()
@property (nonatomic,assign)int tickets;
@property (nonatomic,strong)dispatch_queue_t  concurrentQueue;
@property (nonatomic,strong)NSLock * mutexLock;
@property (nonatomic,strong)NSRecursiveLock * rsLock;//递归锁
@property(nonatomic,assign)OSSpinLock  pinLock;//自旋锁
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self testSemaphore];
}

- (void)dealloc{
//    pthread_mutex_destroy(&mutex);  //释放该锁的数据结构
}

-(dispatch_queue_t)concurrentQueue
{
    if (!_concurrentQueue) {
        _concurrentQueue =dispatch_queue_create(0, 0);
    }
    return _concurrentQueue;
}
#pragma mark -@synchronized 关键字加锁 互斥锁，性能较差不推荐使用
-(void)testSynchronized
{
    //设置票的数量为5
    _tickets = 5;
    
    //线程1
    dispatch_async(self.concurrentQueue, ^{
        [self saleTickets];
    });
    
    //线程2
    dispatch_async(self.concurrentQueue, ^{
        [self saleTickets];
    });
    

}

- (void)saleTickets
{
    while (1) {
        @synchronized(self) {
            [NSThread sleepForTimeInterval:1];
            if (_tickets > 0) {
                _tickets--;
                NSLog(@"剩余票数= %d, Thread:%@",_tickets,[NSThread currentThread]);
            } else {
                NSLog(@"票卖完了  Thread:%@",[NSThread currentThread]);
                break;
            }
        }
    }
}


#pragma mark - NSLock 互斥锁 不能多次调用 lock方法,会造成死锁
/*
 NSLock类还增加了tryLock和lockBeforeDate:方法。
 tryLock试图获取一个锁，但是如果锁不可用的时候，它不会阻塞线程，相反，它只是返回NO。
 lockBeforeDate:方法试图获取一个锁，但是如果锁没有在规定的时间内被获得，它会让线程从阻塞状态变为非阻塞状态（或者返回NO）。
 
 */
- (void)test_NSLock

{
    //设置票的数量为5
    _tickets = 5;
    
    //创建锁
    _mutexLock = [[NSLock alloc] init];
    
    //线程1
    dispatch_async(self.concurrentQueue, ^{
        [self saleTickets2];
    });
    
    //线程2
    dispatch_async(self.concurrentQueue, ^{
        [self saleTickets2];
    });
    
    
}
- (void)saleTickets2
{
    
    while (1) {
        [NSThread sleepForTimeInterval:1];
        //加锁
        [_mutexLock lock];
        if (_tickets > 0) {
            _tickets--;
            NSLog(@"剩余票数= %d, Thread:%@",_tickets,[NSThread currentThread]);
        } else {
            NSLog(@"票卖完了  Thread:%@",[NSThread currentThread]);
            break;
        }
        //解锁
        [_mutexLock unlock];
    }
}

#pragma mark -nslock死锁
/**
 使用锁最容易犯的一个错误就是在递归或循环中造成死锁
 递归block中，锁会被多次的lock，所以自己也被阻塞了
 */
-(void)testDeadLock
{
    //创建锁
    _mutexLock = [[NSLock alloc]init];
    
    //线程1
    dispatch_async(self.concurrentQueue, ^{
        static void(^TestMethod)(int);
        TestMethod = ^(int value)
        {
            [_mutexLock lock];
            if (value > 0)
            {
                [NSThread sleepForTimeInterval:1];
                NSLog(@"剩余票数= %d, Thread:%@",value,[NSThread currentThread]);

                TestMethod(value--);
                
            }
            [_mutexLock unlock];
        };
        
        TestMethod(5);
    });
    
  
}

#pragma mark - NSRecursiveLock 递归锁
/**
 NSRecursiveLock类定义的锁可以在同一线程多次lock，而不会造成死锁。
 递归锁会跟踪它被多少次lock。每次成功的lock都必须平衡调用unlock操作。
 只有所有的锁住和解锁操作都平衡的时候，锁才真正被释放给其他线程获得
 */
-(void)testNSRecursiveLock
{
    //创建锁
    _rsLock = [[NSRecursiveLock alloc] init];
    
    //线程1
    dispatch_async(self.concurrentQueue, ^{
        static void(^TestMethod)(int);
        TestMethod = ^(int value)
        {
            [_rsLock lock];
            if (value > 0)
            {
                [NSThread sleepForTimeInterval:1];
                NSLog(@"剩余票数= %d, Thread:%@",value,[NSThread currentThread]);

                TestMethod(value-1);

            }
            [_rsLock unlock];
        };
        
        TestMethod(5);
    });
    
  
}
#pragma mark - NSConditionLock 条件锁
-(void)testNSConditionLock
{
    //主线程中
    NSConditionLock* lock = [[NSConditionLock alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSUInteger i=0; i<3; i++) {
            sleep(2);
            if (i == 2) {
                [lock lock];
                [lock unlockWithCondition:i];
            }
            
        }
    });
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        [lock lockWhenCondition:2];
        NSLog(@"thread2");

        [lock unlock];
    });
 
}

#pragma mark - pthread_mutex POSIX是Unix/Linux平台上提供的一套条件互斥锁的API。
-(void)testPthread_mutex
{
    __block pthread_mutex_t mutex;
    pthread_mutex_init(&mutex, NULL);
    
    
  
    //线程1
    dispatch_async(self.concurrentQueue, ^{
        pthread_mutex_lock(&mutex);
        NSLog(@"任务1");
        sleep(2);
        pthread_mutex_unlock(&mutex);
    });
    
    //线程2
    dispatch_async(self.concurrentQueue, ^{
        sleep(1);
        pthread_mutex_lock(&mutex);
        NSLog(@"任务2");
        pthread_mutex_unlock(&mutex);
    });
   
   
}

#pragma mark pthread_rwlock 读写锁
//略

#pragma mark - dispatch_semaphore 信号量实现加锁
-(void)testSemaphore
{
    // 创建信号量
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"任务1");
        sleep(10);
        dispatch_semaphore_signal(semaphore);
    });
    
    //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"任务2");
        dispatch_semaphore_signal(semaphore);
    });
    
   
}

#pragma mark - OSSpinLock 存在优先级翻转问题

-(void)testOSSpinLock
{
    //设置票的数量为5
    _tickets = 5;
    //创建锁
     _pinLock = OS_SPINLOCK_INIT;
    //线程1
    dispatch_async(self.concurrentQueue, ^{
        [self saleTickets];
    });
    //线程2
    dispatch_async(self.concurrentQueue, ^{
        [self saleTickets];
    });
    
  
}
- (void)saleTickets3 {
    
    while (1) {
        [NSThread sleepForTimeInterval:1];
        //加锁
        OSSpinLockLock(&_pinLock);
        
        if (_tickets > 0) {
            _tickets--;
            NSLog(@"剩余票数= %d, Thread:%@",_tickets,[NSThread currentThread]);
            
        } else {
            NSLog(@"票卖完了  Thread:%@",[NSThread currentThread]);
            break;
        }
        //解锁
        OSSpinLockUnlock(&_pinLock);
    }
    
}

#pragma mark - os_unfair_lock
/*
 自旋锁已经不在安全，然后苹果又整出来个 os_unfair_lock_t
 
 这个锁解决了优先级反转问题。
 
 os_unfair_lock_t unfairLock;
 unfairLock = &(OS_UNFAIR_LOCK_INIT);
 os_unfair_lock_lock(unfairLock);
 os_unfair_lock_unlock(unfairLock);
 
 */
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
