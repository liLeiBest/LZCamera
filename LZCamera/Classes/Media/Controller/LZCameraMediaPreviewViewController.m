//
//  LZCameraMediaPreviewViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/23.
//

#import "LZCameraMediaPreviewViewController.h"
#import "LZCameraToolkit.h"
#import <AVFoundation/AVFoundation.h>

@interface LZCameraMediaPreviewViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *editBtn;
@property (weak, nonatomic) IBOutlet UIButton *sureBtn;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@end

@implementation LZCameraMediaPreviewViewController

// MARK: - Initialization
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *cancelImg = [self imageInBundle:@"media_preview_cancel"];
    [self.cancelBtn setImage:cancelImg forState:UIControlStateNormal];
	UIImage *deleteImg = [self imageInBundle:@"media_preview_delete"];
	[self.cancelBtn setImage:deleteImg forState:UIControlStateSelected];
    self.cancelBtn.layer.cornerRadius = 30.0f;
    UIImage *editlImg = [self imageInBundle:@"media_preview_edit"];
    [self.editBtn setImage:editlImg forState:UIControlStateNormal];
    self.editBtn.layer.cornerRadius = 30.0f;
    UIImage *surelImg = [self imageInBundle:@"media_preview_done"];
    [self.sureBtn setImage:surelImg forState:UIControlStateNormal];
    self.sureBtn.backgroundColor = [UIColor clearColor];
    
    self.previewImgView.image = self.previewImage;
    if (self.videoURL) {
        
        AVAsset *asset = [AVAsset assetWithURL:self.videoURL];
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
		self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.playerLayer.frame = self.view.layer.bounds;
        [self.view.layer insertSublayer:self.playerLayer above:self.previewImgView.layer];
        [self.player play];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(playerItemDidPlayToEnd:)
         name:AVPlayerItemDidPlayToEndTimeNotification
         object:nil];
    }
}

- (void)dealloc {
    LZCameraLog();
}

// MARK: - UI Action
- (IBAction)cancelDidClick:(id)sender {
	
	[self dismissViewControllerAnimated:NO completion:nil];
	if (self.videoURL) {
		
		NSFileManager *fileM = [NSFileManager defaultManager];
		[fileM removeItemAtURL:self.videoURL error:NULL];
	}
}

- (IBAction)editDidClick:(id)sender {
    
}

- (IBAction)sureDidClick:(id)sender {
	
	if (self.autoSaveToAlbum) {
		
		if (self.videoURL) {
			[LZCameraToolkit saveVideoToAblum:self.videoURL completionHandler:^(PHAsset * _Nullable asset, NSError * _Nullable error) {
				[self sureHandlerOnMainThread];
			}];
		} else if (self.previewImage) {
			[LZCameraToolkit saveImageToAblum:self.previewImage completionHandler:^(PHAsset * _Nullable asset, NSError * _Nullable error) {
				[self sureHandlerOnMainThread];
			}];
		}
	} else {
		[self sureHandlerOnMainThread];
	}
}

// MARK: - Observer
- (void)playerItemDidPlayToEnd:(NSNotification *)notification {
    
    if (!self.player) {
        return;
    }
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}

// MARK: - Private
/**
 加载图片资源
 
 @param imageName NSString
 @return UIImage
 */
- (UIImage *)imageInBundle:(NSString *)imageName {
    
    NSBundle *bundle = LZCameraNSBundle(@"LZCameraMedia");
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image;
}

/**
 保证主线程回调
 */
- (void)sureHandlerOnMainThread {
	
	if (NO == [NSThread isMainThread]) {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.TapToSureHandler) {
				self.TapToSureHandler();
			}
			[self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
		});
	} else {
		if (self.TapToSureHandler) {
			self.TapToSureHandler();
		}
		[self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
	}
}


@end
