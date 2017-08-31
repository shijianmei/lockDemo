//
//  ViewController.m
//  lockDemo
//
//  Created by Jianmei on 2017/8/31.
//  Copyright © 2017年 Jianmei. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic,assign)int tickets;
@property (nonatomic,strong)dispatch_queue_t  concurrentQueue;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}
#pragma mark -@synchronized 关键字加锁 互斥锁，性能较差不推荐使用
-(void)testSynchronized
{
    self.concurrentQueue = dispatch_queue_create(0, 0);
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
