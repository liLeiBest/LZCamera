//
//  LZPermanentThread.h
//  LZDependencyToolkit
//
//  Created by Dear.Q on 2021/4/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__API_AVAILABLE(ios(10.0))
@interface LZPermanentThread : NSObject

// 执行任务
- (void)executeTask:(void (^)(void))task;

/// 停止线程
- (void)stop;

@end

NS_ASSUME_NONNULL_END
