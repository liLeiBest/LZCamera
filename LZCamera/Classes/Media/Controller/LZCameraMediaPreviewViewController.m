//
//  LZCameraMediaPreviewViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/23.
//

#import "LZCameraMediaPreviewViewController.h"
#import "LZCameraVideoEditorViewController.h"
#import "LZCameraToolkit.h"

@interface LZCameraMediaPreviewViewController ()<UINavigationControllerDelegate, UIVideoEditorControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *editBtn;
@property (weak, nonatomic) IBOutlet UIButton *sureBtn;

/** 预览视频地址 */
@property (copy, nonatomic) NSURL *previewURL;
/** 预览图层 */
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@end

@implementation LZCameraMediaPreviewViewController

// MARK: - Initialization
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.previewImgView.image = self.previewImage;
	[self buildPlayer];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(playerItemDidPlayToEnd:)
	 name:AVPlayerItemDidPlayToEndTimeNotification
	 object:nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(appResignActive)
	 name:UIApplicationWillResignActiveNotification
	 object:nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(appBecomeActive)
	 name:UIApplicationDidBecomeActiveNotification
	 object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[self.playerLayer.player pause];
	[self.playerLayer removeFromSuperlayer];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    LZCameraLog();
}

// MARK: - UI Action
- (IBAction)cancelDidClick:(id)sender {
	
	NSFileManager *fileM = [NSFileManager defaultManager];
	[fileM removeItemAtURL:self.videoURL error:NULL];
	[fileM removeItemAtURL:self.previewURL error:NULL];
	[self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)editDidClick:(id)sender {
	
	LZCameraVideoEditorViewController *ctr = [LZCameraVideoEditorViewController instance];
	ctr.previewImage = self.previewImage;
	ctr.videoURL = self.videoURL;
	ctr.videoMaximumDuration = 60.0f;
	__weak typeof(self) weakSelf = self;
	ctr.VideoEditCallback = ^(NSURL * _Nonnull videoURL, UIImage * _Nonnull previewImage) {
		
		typeof(weakSelf) strongSelf = weakSelf;
		strongSelf.previewURL = videoURL;
		strongSelf.previewImage = previewImage;
	};
	
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:ctr];
	[self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)sureDidClick:(id)sender {
	
	if (self.autoSaveToAlbum) {
		if (self.previewURL) {
			[LZCameraToolkit saveVideoToAblum:self.previewURL completionHandler:^(PHAsset * _Nullable asset, NSError * _Nullable error) {
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
    
    if (!self.playerLayer.player) {
        return;
    }
    [self.playerLayer.player seekToTime:kCMTimeZero];
    [self.playerLayer.player play];
}

- (void)appResignActive {
	[self.playerLayer.player pause];
}

- (void)appBecomeActive {
	[self.playerLayer.player play];
}

// MARK: - Private
- (void)setupUI {
	
	self.previewURL = self.videoURL;
	
	UIImage *cancelImg = [self imageInBundle:@"media_preview_cancel"];
	[self.cancelBtn setImage:cancelImg forState:UIControlStateNormal];
	UIImage *deleteImg = [self imageInBundle:@"media_preview_delete"];
	[self.cancelBtn setImage:deleteImg forState:UIControlStateSelected];
	self.cancelBtn.layer.cornerRadius = 30.0f;
	self.cancelBtn.backgroundColor = [UIColor clearColor];
	
	UIImage *editlImg = [self imageInBundle:@"media_preview_edit"];
	[self.editBtn setImage:editlImg forState:UIControlStateNormal];
	self.editBtn.layer.cornerRadius = 30.0f;
//	self.editBtn.backgroundColor = [UIColor clearColor];
	
	UIImage *surelImg = [self imageInBundle:@"media_preview_done"];
	[self.sureBtn setImage:surelImg forState:UIControlStateNormal];
	self.sureBtn.backgroundColor = [UIColor clearColor];
}

- (void)buildPlayer {
	
	if (self.playerLayer) {
		[self.playerLayer removeFromSuperlayer];
	}
	AVAsset *asset = [AVAsset assetWithURL:self.previewURL];
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
	AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
	self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
	self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
	self.playerLayer.frame = self.view.layer.bounds;
	[self.view.layer insertSublayer:self.playerLayer above:self.previewImgView.layer];
	[self.playerLayer.player play];
}

- (UIImage *)imageInBundle:(NSString *)imageName {
    
    NSBundle *bundle = LZCameraNSBundle(@"LZCameraMedia");
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image;
}

- (void)sureHandlerOnMainThread {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.TapToSureHandler) {
			self.TapToSureHandler(self.previewImage, self.previewURL);
		}
		[self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
	});
}

@end
