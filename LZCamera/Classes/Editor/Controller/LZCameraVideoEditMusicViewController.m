//
//  LZCameraVideoEditMusicViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/25.
//

#import "LZCameraVideoEditMusicViewController.h"
#import "LZCameraEditorVideoMusicContainerView.h"
#import "LZCameraToastViewController.h"
#import "LZCameraPlayer.h"
#import "LZCameraToolkit.h"

/** 背景音音量 */
static CGFloat BGMVolume = 0.5f;
@interface LZCameraVideoEditMusicViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@property (weak, nonatomic) IBOutlet LZCameraEditorVideoMusicContainerView *musicView;

/** 视频播放器 */
@property (strong, nonatomic) LZCameraPlayer *videoPlayer;
/** 背景音乐播放器 */
@property (strong, nonatomic) AVAudioPlayer *BGMPlayer;
/** 背景音乐 */
@property (strong, nonatomic) LZCameraEditorMusicModel *musicModel;

@end

@implementation LZCameraVideoEditMusicViewController

// AMRK: - Initialization
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self setupUI];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	[self stopPlay];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	self.videoPlayer.playerLayer.frame = self.previewImgView.layer.frame;
}

- (void)dealloc {
	LZCameraLog();
}

// MARK: - Public
+ (instancetype)instance {
	
	NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LZCameraVideoEditMusicViewController"
														 bundle:bundle];
	return storyboard.instantiateInitialViewController;
}

// MARK: - UI Action
- (void)popDidClick {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneDidClick {
	
	LZCameraToastViewController *ctr = [LZCameraToastViewController instance];
	[ctr showMessage:@"处理中……"];
	[self presentViewController:ctr animated:YES completion:nil];
	[self stopPlay];
	[LZCameraToolkit mixAudioForAsset:self.videoURL
							timeRange:self.timeRange
						 audioPathURL:[self fetchBGMURL]
						originalAudio:YES
					   originalVolume:1.0
						  audioVolume:BGMVolume
						   presetName:AVAssetExportPresetMediumQuality
					completionHandler:^(NSURL * _Nullable outputFileURL, BOOL success) {
						if (success) {
							if (self.VideoEditCallback) {
								self.VideoEditCallback(outputFileURL);
							}
							[ctr hideAfterDelay:0 completionHandler:^{
								[self.navigationController dismissViewControllerAnimated:YES completion:nil];
							}];
						}
					}];
}

// MARK: - Private
- (void)setupUI {
	
	self.title = @"加音乐";
	
	self.previewImgView.image = [LZCameraToolkit thumbnailAtFirstFrameForVideoAtURL:self.videoURL];
	[self buildPlayer];
	
	__weak typeof(self) weakSelf = self;
	self.musicView.TapOriginalMusicCallback = ^{
		
		typeof(weakSelf) strongSelf = weakSelf;
		if (strongSelf.musicModel) {
			
			[strongSelf.BGMPlayer pause];
			strongSelf.BGMPlayer = nil;
			strongSelf.musicModel = nil;
			[strongSelf startPlay];
		}
	};
	self.musicView.TapMusicCallback = ^(LZCameraEditorMusicModel * _Nonnull musicModel) {
		
		typeof(weakSelf) strongSelf = weakSelf;
		if ([strongSelf.musicModel isEqual:musicModel]) {
			return ;
		}
		strongSelf.musicModel = musicModel;
		[strongSelf stopPlay];
		[strongSelf cutBGMusic];
	};
	
	NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
	UIImage *navBackImage = [UIImage imageNamed:@"nav_back_default"
									   inBundle:bundle
				  compatibleWithTraitCollection:nil];
	self.navigationItem.leftBarButtonItem =
	[[UIBarButtonItem alloc] initWithImage:navBackImage
									 style:UIBarButtonItemStylePlain
									target:self
									action:@selector(popDidClick)];
	self.navigationItem.rightBarButtonItem =
	[[UIBarButtonItem alloc] initWithTitle:@"完成"
									 style:UIBarButtonItemStylePlain
									target:self
									action:@selector(doneDidClick)];
}

- (void)cutBGMusic {
	
	CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, self.timeRange.duration);
	NSURL *musicURL = [self fetchBGMURL];
	[LZCameraToolkit cutAsset:musicURL
						 type:LZCameraAssetTypeM4A
					 timeRane:timeRange
			completionHandler:^(NSURL * _Nullable outputFileURL, BOOL success) {
				if (success) {
					
					NSError *error;
					self.BGMPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:outputFileURL error:&error];
					if (error == nil) {
						
						self.BGMPlayer.numberOfLoops = -1;
						self.BGMPlayer.volume = BGMVolume;
						[self.BGMPlayer prepareToPlay];
						[self startPlay];
					}
				}
	}];
}

- (NSURL *)fetchBGMURL {
	
	NSURL *musicURL = nil;
	if (self.musicModel) {
		
		NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
		NSString *musicPath = [bundle pathForResource:self.musicModel.thumbnail ofType:@"mp3"];
		musicURL = [NSURL fileURLWithPath:musicPath];
	}
	return musicURL;
}

- (void)buildPlayer {
	
	if (self.videoPlayer) {
		
		[self.videoPlayer pause];
		[self.videoPlayer.playerLayer removeFromSuperlayer];
	}
	self.videoPlayer = [LZCameraPlayer playerWithURL:self.videoURL];
	self.videoPlayer.timeRange = self.timeRange;
	self.videoPlayer.playerLayer.frame = self.previewImgView.frame;
	[self.view.layer insertSublayer:self.videoPlayer.playerLayer above:self.previewImgView.layer];
	[self startPlay];
}

- (void)startPlay{
	
	[self.videoPlayer play];
	[self.BGMPlayer play];
}

- (void)stopPlay {
	
	[self.videoPlayer pause];
	[self.BGMPlayer pause];
}

@end
