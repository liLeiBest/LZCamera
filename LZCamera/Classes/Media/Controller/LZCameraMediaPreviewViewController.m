//
//  LZCameraMediaPreviewViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/23.
//

#import "LZCameraMediaPreviewViewController.h"
#import "LZCameraVideoEditorViewController.h"
#import "LZCameraVideoEditMusicViewController.h"
#import "LZCameraPlayer.h"
#import "LZCameraToolkit.h"

@interface LZCameraMediaPreviewViewController ()<UINavigationControllerDelegate, UIVideoEditorControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *editBtn;
@property (weak, nonatomic) IBOutlet UIButton *sureBtn;

/** 编辑的视频地址，默认等同于 previewVideoURL */
@property (copy, nonatomic) NSURL *editVideoURL;
/** 编辑的图片，默认等同于 previewImage */
@property (strong, nonatomic) UIImage *editImage;
/** 视频播放器 */
@property (strong, nonatomic) LZCameraPlayer *videoPlayer;

@end

@implementation LZCameraMediaPreviewViewController

// MARK: - Initialization
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if (self.editVideoURL) {
		[self buildPlayer];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	if (self.videoPlayer) {
		
		[self.videoPlayer pause];
		[self.videoPlayer.playerLayer removeFromSuperlayer];
		self.videoPlayer = nil;
	}
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	if (self.videoPlayer) {
		self.videoPlayer.playerLayer.frame = self.previewImgView.frame;
	}
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

// MARK: - UI Action
- (IBAction)cancelDidClick:(id)sender {
	
	[LZCameraToolkit deleteFile:self.previewVideoURL];
	[LZCameraToolkit deleteFile:self.editVideoURL];
	[self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)editDidClick:(id)sender {
    if (self.editVideoURL) {
        if (self.autoSaveToAlbum) {
            [LZCameraToolkit saveVideoToAblum:self.editVideoURL completionHandler:^(PHAsset * _Nullable asset, NSError * _Nullable error) {
            }];
        }
        [self showVideoEditCtr];
    } else if (self.editImage) {
        if (self.autoSaveToAlbum) {
            [LZCameraToolkit saveImageToAblum:self.editImage completionHandler:^(PHAsset * _Nullable asset, NSError * _Nullable error) {
                if (self.TapToSureHandler) {
                    self.TapToSureHandler(self.editImage, nil, asset);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:LZCameraObserver_Complete object:nil];
            }];
        }
    }
}

- (IBAction)sureDidClick:(id)sender {
	if (self.editVideoURL) {
		if (self.autoSaveToAlbum) {
			[LZCameraToolkit saveVideoToAblum:self.editVideoURL completionHandler:^(PHAsset * _Nullable asset, NSError * _Nullable error) {
			}];
		}
//        [self showMusicEditCtr];
        [self showVideoEditCtr];
	} else if (self.editImage) {
		if (self.autoSaveToAlbum) {
			[LZCameraToolkit saveImageToAblum:self.editImage completionHandler:^(PHAsset * _Nullable asset, NSError * _Nullable error) {
                if (self.TapToSureHandler) {
                    self.TapToSureHandler(self.editImage, nil, asset);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:LZCameraObserver_Complete object:nil];
			}];
		}
	}
}

// MARK: - Private
- (void)setupUI {
	
	self.editVideoURL = self.previewVideoURL;
	if (self.previewImage) {
		
		self.editImage = self.previewImage;
		self.previewImgView.image = self.editImage;
	}
	self.editBtn.hidden = nil != self.editImage;
	
	UIImage *cancelImg = [self imageInBundle:@"media_preview_cancel"];
	[self.cancelBtn setImage:cancelImg forState:UIControlStateNormal];
	UIImage *deleteImg = [self imageInBundle:@"media_preview_delete"];
	[self.cancelBtn setImage:deleteImg forState:UIControlStateSelected];
	self.cancelBtn.layer.cornerRadius = 30.0f;
	self.cancelBtn.backgroundColor = [UIColor clearColor];
	
	UIImage *editlImg = [self imageInBundle:@"media_preview_edit"];
	[self.editBtn setImage:editlImg forState:UIControlStateNormal];
	self.editBtn.layer.cornerRadius = 30.0f;
	self.editBtn.backgroundColor = [UIColor clearColor];
	self.editBtn.hidden = YES;
	
	UIImage *surelImg = [self imageInBundle:@"media_preview_done"];
	[self.sureBtn setImage:surelImg forState:UIControlStateNormal];
	self.sureBtn.backgroundColor = [UIColor clearColor];
}

- (void)buildPlayer {
	if (self.videoPlayer) {
		
		[self.videoPlayer pause];
		[self.videoPlayer.playerLayer removeFromSuperlayer];
	}
	self.videoPlayer = [LZCameraPlayer playerWithURL:self.editVideoURL];
	self.videoPlayer.playerLayer.frame = self.previewImgView.frame;
	[self.view.layer insertSublayer:self.videoPlayer.playerLayer above:self.previewImgView.layer];
	[self.videoPlayer play];
}

- (UIImage *)imageInBundle:(NSString *)imageName {
    
    NSBundle *bundle = LZCameraNSBundle(@"LZCameraMedia");
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image;
}

- (void)showVideoEditCtr {
    
    LZCameraVideoEditorViewController *ctr = [LZCameraVideoEditorViewController instance];
    ctr.videoURL = self.editVideoURL;
    ctr.videoMaximumDuration = self.maxShortVideoDuration;
    __weak typeof(self) weakSelf = self;
    ctr.VideoEditCallback = ^(NSURL * _Nonnull editedVideoURL) {
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.editVideoURL = editedVideoURL;
        if (strongSelf.TapToSureHandler) {
            strongSelf.TapToSureHandler(nil, strongSelf.editVideoURL, nil);
        }
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:ctr];
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showMusicEditCtr {
    
    LZCameraVideoEditMusicViewController *ctr = [LZCameraVideoEditMusicViewController instance];
    ctr.videoURL = self.editVideoURL;
    ctr.timeRange = kCMTimeRangeZero;
    __weak typeof(self) weakSelf = self;
    ctr.VideoEditCallback = ^(NSURL * _Nonnull editedVideoURL) {
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.editVideoURL = editedVideoURL;
        if (strongSelf.TapToSureHandler) {
            strongSelf.TapToSureHandler(nil, strongSelf.editVideoURL, nil);
        }
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:ctr];
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

@end
