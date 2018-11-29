//
//  LZCameraCodeViewController.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/29.
//

#import "LZCameraController.h"

/** 机器码捕捉回调 */
typedef void(^LZCameraDetectMachineCodeHandler)(NSArray<NSString *> *codeArray, NSError *error, void(^CompleteHandler)(void));

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraCodeViewController : UIViewController

/**
 实例
 
 @return LZCameraCodeViewController
 */
+ (instancetype)instance;

/**
 机器码检测

 @param codeTypes 机器码类型
 @param completionHandler 完成回调
 */
- (void)detectCodeTyps:(NSArray<AVMetadataObjectType> *)codeTypes
     completionHandler:(LZCameraDetectMachineCodeHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
