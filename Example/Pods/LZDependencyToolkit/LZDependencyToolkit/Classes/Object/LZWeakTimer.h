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
 实例

 @param timeInterval 时间间隔
 @param repeats 是否重复
 @param dispatchQueue 执行队列
 @param eventHandler 回调
 @return LZWeakTimer
 */
- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval
							 repeats:(BOOL)repeats
					   dispatchQueue:(dispatch_queue_t)dispatchQueue
						eventHandler:(LZTimeEventHandler)eventHandler;

/**
 实例

 @param timeInterval 时间间隔
 @param repeats 是否重复
 @param dispatchQueue 执行队列
 @param eventHandler 回调
 @return LZWeakTimer
 */
+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
									   repeats:(BOOL)repeats
								 dispatchQueue:(dispatch_queue_t)dispatchQueue
								  eventHandler:(LZTimeEventHandler)eventHandler;


/**
 允许的误差
 */
@property (atomic, assign) NSTimeInterval tolerance;

/**
 启动定时器
 */
- (void)schedule;

/**
 立即触发定时方法
 */
- (void)fire;

/**
 取消定时器
 */
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
