//
//  LZCameraMediaPreviewViewController.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraMediaPreviewViewController : UIViewController

@property (strong, nonatomic) UIImage *previewImage;
@property (strong, nonatomic) NSURL *videoURL;
@property (copy, nonatomic) void(^TapToSureHandler)(void);
@property (strong, nonatomic) UIViewController *target;

@end

NS_ASSUME_NONNULL_END
