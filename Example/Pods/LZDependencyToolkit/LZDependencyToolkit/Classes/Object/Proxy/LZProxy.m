//
//  LZProxy.m
//  LZDependencyToolkit
//
//  Created by Dear.Q on 2021/4/26.
//

#import "LZProxy.h"

@implementation LZProxy

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}

// MARK: - Public
+ (instancetype)proxyWithTarget:(id)target {
    
    LZProxy *proxy = [LZProxy alloc];
    proxy.target = target;
    return proxy;
}

@end
