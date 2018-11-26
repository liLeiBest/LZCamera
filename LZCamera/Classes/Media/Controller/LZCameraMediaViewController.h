//
//  LZCameraMediaViewController.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/22.
//

#import <UIKit/UIKit.h>
#import "LZCameraMediaDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraMediaViewController : UIViewController

/** 捕捉模式，默认是 LZCameraCaptureModelStillImageAndShortVideo */
@property (assign, nonatomic) LZCameraCaptureModel captureModel;
/** 短时间持续时间 */
@property (assign, nonatomic) NSInteger maxDuration;


/**
 实例

 @return LZCameraMediaViewController
 */
+ (instancetype)instance;

@end

NS_ASSUME_NONNULL_END
