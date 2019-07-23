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

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@property (copy) AVAudioSessionCategory audioSesstionCategory;

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

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[self.player pause];
	[self.playerLayer removeFromSuperlayer];
	self.playerItem = nil;
	self.player = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    LZCameraLog();
	AVAudioSession *session = [AVAudioSession sharedInstance];
	[session setCategory:self.audioSesstionCategory error:nil];
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
	
	LZCameraVideoEditorViewController *ctr = [LZCameraVideoEditorViewController instance];
	ctr.previewImage = self.previewImage;
	ctr.videoURL = self.videoURL;
	ctr.videoMaximumDuration = 60.0f;
	__weak typeof(self) weakSelf = self;
	ctr.VideoClipCallback = ^(NSURL * _Nonnull videoUrl) {
		
		typeof(weakSelf) strongSelf = weakSelf;
		strongSelf.videoURL = videoUrl;
		AVAsset *asset = [AVAsset assetWithURL:videoUrl];
		strongSelf.playerItem = [AVPlayerItem playerItemWithAsset:asset];
		strongSelf.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
		[strongSelf.player play];
	};
	[self presentViewController:ctr animated:YES completion:nil];
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

// MARK: - Private
- (void)setupUI {
	
	AVAudioSession *session = [AVAudioSession sharedInstance];
	self.audioSesstionCategory = session.category;
	[session setActive:YES error:nil];
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	[session setCategory:AVAudioSessionCategoryPlayback error:nil];
	
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
