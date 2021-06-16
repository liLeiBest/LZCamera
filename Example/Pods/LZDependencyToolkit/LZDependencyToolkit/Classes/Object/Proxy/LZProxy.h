//
//  LZProxy.h
//  LZDependencyToolkit
//
//  Created by Dear.Q on 2021/4/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZProxy : NSProxy

// 目标类
@property (nonatomic, weak) id target;

/// 构造方法
/// @param target 目标类
+ (instancetype)proxyWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
