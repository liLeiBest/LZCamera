//
//  LZCameraMediaVideoPickerViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2020/9/22.
//

#import "LZCameraMediaVideoPickerViewController.h"
#import "LZCameraToolkit.h"
#import "LZCameraVideoEditorViewController.h"
#import <CoreServices/CoreServices.h>

@interface LZCameraMediaVideoPickerViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) UIView *cover;
@property (nonatomic, weak) id sender;

@end

@implementation LZCameraMediaVideoPickerViewController

// MARK: - Initialization
- (instancetype)init {
    if (self = [super init]) {
        
        NSString *mediaType = (NSString *)kUTTypeMovie;
        UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        self.sourceType = sourceType;
        self.mediaTypes = @[mediaType];
        self.allowsEditing = YES;
        self.delegate = self;
        if ([self cameraSupportMedia:mediaType sourceType:sourceType]) {
            
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self albumAuthJudge];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.cover.frame = self.view.bounds;
}

- (void)dealloc {
    LZCameraLog();
}

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

- (UIModalTransitionStyle)modalTransitionStyle {
    return UIModalTransitionStyleCoverVertical;
}

// MARK: - Public
+ (instancetype)instance {
    
    LZCameraMediaVideoPickerViewController *pickCtr = [[self alloc] init];
    return pickCtr;
}

- (void)removeCover {
    [UIView animateWithDuration:0.25 animations:^{
        self.cover.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.cover removeFromSuperview];
    }];
}

// MARK: - Private
- (void)setupUI {
    
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];
    self.cover = view;
}

- (void)albumAuthJudge {
    [LZCameraToolkit photoAuthorizationJudge:^(BOOL authorized, PHAuthorizationStatus status, NSError * _Nullable error) {
        if (YES == authorized) {
            [self removeCover];
        } else {
            
            NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
            NSString *message = [NSString stringWithFormat:@"请在iPhone的“设置-隐私”选项中，允许%@访问您的照片。", appName];
            UIAlertController *alertCtr =
            [UIAlertController alertControllerWithTitle:@"提示"
                                                message:message
                                         preferredStyle:UIAlertControllerStyleAlert];
            [alertCtr addAction:[UIAlertAction actionWithTitle:@"确定"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }]];
            [self presentViewController:alertCtr animated:YES completion:nil];
        }
    }];
}

- (void)alertMessage:(NSString *)message handler:(void (^)(UIAlertAction *action))handler {
    
    UIAlertController *alertCtr =
    [UIAlertController alertControllerWithTitle:@"提示"
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertCtr addAction:[UIAlertAction actionWithTitle:@"确定"
                                                 style:UIAlertActionStyleDefault
                                               handler:handler]];
    [self presentViewController:alertCtr animated:YES completion:nil];
}

- (BOOL)cameraSupportMedia:(NSString*)paramMediaType
                sourceType:(UIImagePickerControllerSourceType)paramSourceType {
    
    __block BOOL result=NO;
    if ([paramMediaType length]==0) {
        NSLog(@"Media type is empty.");
        return NO;
    }
    NSArray*availableMediaTypes=[UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    [availableMediaTypes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *mediaType = (NSString *)obj;
        if ([mediaType isEqualToString:paramMediaType]){
            result = YES;
            *stop= YES;
        }
    }];
    return result;
}

- (void)showVideoEditCtr:(NSURL *)videoURL {
    if (self.pickCompleteCallback) {
        self.pickCompleteCallback(videoURL);
    }
    
    LZCameraVideoEditorViewController *ctr = [LZCameraVideoEditorViewController instance];
    ctr.videoURL = videoURL;
    ctr.videoMaximumDuration = 60.0f;
    ctr.VideoEditCallback = self.editCompleteCallback;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:ctr];
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.presentingViewController presentViewController:nav animated:YES completion:nil];
}

- (void)saveVideoFromAssetURL:(NSURL *)assetURL
                       toURL:(NSURL *)fileURL
           completionCallback:(void (^)(NSError * __nullable error))handler{
    [LZCameraToolkit photoAuthorizationJudge:^(BOOL authorized, PHAuthorizationStatus status, NSError * _Nullable error) {
        if (YES == authorized) {
            
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithALAssetURLs:@[assetURL] options:nil];
            PHAsset *asset = fetchResult.firstObject;
            if (nil == asset) {
                NSError *error = [NSError errorWithDomain:LZCameraErrorDomain code:LZCameraErrorInvalideFileOutputURL userInfo:@{NSLocalizedDescriptionKey : @"Video do not exist!"}];
                if (handler) {
                    handler(error);
                }
                return;
            }
            NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
            PHAssetResource *resource = nil;
            for (PHAssetResource *assetRes in assetResources) {
                if (@available(iOS 9.1, *)) {
                    if (assetRes.type == PHAssetResourceTypePairedVideo
                        || assetRes.type == PHAssetResourceTypeVideo) {
                        resource = assetRes;
                        break;
                    }
                } else {
                    if (assetRes.type == PHAssetResourceTypeVideo) {
                        resource = assetRes;
                        break;
                    }
                }
            }
            [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource toFile:fileURL options:nil completionHandler: ^(NSError * _Nullable error) {
                if (handler) {
                    handler(error);
                }
            }];
        } else {
            if (handler) {
                handler(error);
            }
        }
    }];
}

// MARK: - Delegate
// MARK: <UIImagePickerControllerDelegate>
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSURL *destURL = [LZCameraToolkit generateUniqueAssetFileURL:LZCameraAssetTypeMov];
    
    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    if (videoURL) {
        
        NSError *error = nil;
        NSFileManager *fileM = [NSFileManager defaultManager];
        BOOL success = [fileM copyItemAtURL:videoURL toURL:destURL error:&error];
        BOOL exist = [fileM fileExistsAtPath:destURL.relativePath];
        if (success && exist) {
            [self showVideoEditCtr:destURL];
        } else {
            [self alertMessage:error.localizedDescription handler:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }
    } else {
        
        videoURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        if (nil == videoURL) {
            if (@available(iOS 11, *)) {
                videoURL = [info objectForKey:UIImagePickerControllerPHAsset];
            }
        }
        if (nil != videoURL) {
            [self saveVideoFromAssetURL:videoURL toURL:destURL completionCallback:^(NSError * _Nullable error) {
                if (nil == error) {
                    [self showVideoEditCtr:destURL];
                } else {
                    [self alertMessage:error.localizedDescription handler:^(UIAlertAction *action) {
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }];
                }
            }];
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
