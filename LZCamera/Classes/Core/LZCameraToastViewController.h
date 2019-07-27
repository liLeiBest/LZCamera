//
//  LZCameraToastViewController.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define LZCameraToast [LZCameraToastViewController instance]

@interface LZCameraToastViewController : UIViewController

/**
 实例

 @return LZCameraToastViewController
 */
+ (instancetype)instance;

/**
 显示提示信息

 @param message 提示内容
 */
- (void)showMessage:(NSString *)message;

/**
 延迟隐藏

 @param delay 延迟时间
 @param handler <#handler description#>
 */
- (void)hideAfterDelay:(CGFloat)delay completionHandler:(void (^)(void))handler;

@end

NS_ASSUME_NONNULL_END
