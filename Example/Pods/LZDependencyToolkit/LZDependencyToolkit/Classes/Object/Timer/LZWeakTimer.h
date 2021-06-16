//
//  LZWeakTimer.h
//  LZDependencyToolkit
//
//  Created by Dear.Q on 2019/6/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LZTimeEventHandler)(void);

@interface LZWeakTimer : NSObject

/**
 允许的误差
 */
@property (atomic, assign) NSTimeInterval tolerance;


/// 实例-对象方法，start 秒后开始
/// @param start 开始时间
/// @param interval 时间间隔
/// @param repeats 是否重复
/// @param queue 执行队列
/// @param handler 回调
- (instancetype)initWithStart:(NSTimeInterval)start
                     interval:(NSTimeInterval)interval
                      repeats:(BOOL)repeats
                        queue:(dispatch_queue_t)queue
                 eventHandler:(LZTimeEventHandler)handler;

/// 实例-类方法，start 秒后开始
/// @param start 开始时间
/// @param interval 时间间隔
/// @param repeats 是否重复
/// @param queue 执行队列
/// @param handler 回调
+ (instancetype)scheduledTimerWithStart:(NSTimeInterval)start
                               interval:(NSTimeInterval)interval
                                repeats:(BOOL)repeats
                                  queue:(dispatch_queue_t)queue
                           eventHandler:(LZTimeEventHandler)handler;

/// 实例-对象方法，timeInterval 秒后开始
/// @param interval 时间间隔
/// @param repeats 是否重复
/// @param queue 执行队列
/// @param handler 回调
- (instancetype)initWithInterval:(NSTimeInterval)interval
                         repeats:(BOOL)repeats
                           queue:(dispatch_queue_t)queue
                    eventHandler:(LZTimeEventHandler)handler;

/// 实例-类方法，timeInterval 秒后开始
/// @param interval 时间间隔
/// @param repeats 是否重复
/// @param queue 执行队列
/// @param handler 回调
+ (instancetype)scheduledTimerWithInterval:(NSTimeInterval)interval
                                   repeats:(BOOL)repeats
                                     queue:(dispatch_queue_t)queue
                              eventHandler:(LZTimeEventHandler)handler;

/// 启动定时器
- (void)schedule;


/// 立即触发定时方法
- (void)fire;

/// 取消定时器
- (void)invalidate;


// MARK: - Deprecated
- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval
                             repeats:(BOOL)repeats
                       dispatchQueue:(dispatch_queue_t)dispatchQueue
                        eventHandler:(LZTimeEventHandler)eventHandler;
+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                       repeats:(BOOL)repeats
                                 dispatchQueue:(dispatch_queue_t)dispatchQueue
                                  eventHandler:(LZTimeEventHandler)eventHandler;

@end

NS_ASSUME_NONNULL_END
