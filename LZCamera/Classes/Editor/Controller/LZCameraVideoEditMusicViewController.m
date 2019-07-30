//
//  LZCameraVideoEditMusicViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/25.
//

#import "LZCameraVideoEditMusicViewController.h"
#import "LZCameraEditorVideoMusicContainerView.h"
#import "LZCameraToastViewController.h"
#import "LZCameraLoadingButton.h"
#import "LZCameraPlayer.h"
#import "LZCameraToolkit.h"
#import <LZDependencyToolkit/LZObject.h>

/** 背景音音量 */
static CGFloat BGMVolume = 0.5f;
/** 监听资源导出进度的 Key */
static NSString * const AssetProgressKeyPath = @"progress";
@interface LZCameraVideoEditMusicViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@property (weak, nonatomic) IBOutlet LZCameraEditorVideoMusicContainerView *musicView;

/** 视频播放器 */
@property (strong, nonatomic) LZCameraPlayer *videoPlayer;
/** 背景音乐播放器 */
@property (strong, nonatomic) AVAudioPlayer *BGMPlayer;
/** 背景音乐 */
@property (strong, nonatomic) LZCameraEditorMusicModel *musicModel;
/** 导出会话 */
@property (strong, nonatomic) AVAssetExportSession *exportSession;
/** 加载视图 */
@property (weak, nonatomic) LZCameraLoadingButton *doneLoadingItem;
/** 计时器 */
@property (strong, nonatomic) LZWeakTimer *timer;

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

	if (self.exportSession && (self.exportSession.status ==  AVAssetExportSessionStatusWaiting
		 || self.exportSession.status == AVAssetExportSessionStatusExporting)) {
		[self.exportSession cancelExport];
	}
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneDidClick {
	
	[self stopPlay];
	[self.musicView updateEditEnable:NO];
	self.exportSession =
	[LZCameraToolkit mixAudioForAsset:self.videoURL
							timeRange:self.timeRange
						 audioPathURL:[self fetchBGMURL]
						originalAudio:YES
					   originalVolume:1.0
						  audioVolume:BGMVolume
						   presetName:AVAssetExportPresetMediumQuality
					completionHandler:^(NSURL * _Nullable outputFileURL, BOOL success) {
						
						[self.doneLoadingItem animationFinish];
						[self.timer invalidate];
						[self.musicView updateEditProgress:1.0f];
						[self.musicView updateEditEnable:YES];
						if (success) {
							if (self.VideoEditCallback) {
								self.VideoEditCallback(outputFileURL);
							}
							[self.navigationController dismissViewControllerAnimated:YES completion:nil];
						} else {
#warning 这里需要改
							LZCameraToastViewController *ctr = [LZCameraToastViewController instance];
							[ctr showMessage:@"编辑失败，请重试"];
							[self presentViewController:ctr animated:YES completion:nil];
						}
					}];
	[self scheduledTimer];
}

// MARK: - Private
- (void)setupUI {
	
	self.title = @"加音乐";
	[self configNavigationItem];
	[self configEditorMusicContainerView];
	self.previewImgView.image = [LZCameraToolkit thumbnailAtFirstFrameForVideoAtURL:self.videoURL];
	[self buildPlayer];
}

- (void)configNavigationItem {
	
	NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
	UIImage *navBackImage = [UIImage imageNamed:@"nav_back_default"
									   inBundle:bundle
				  compatibleWithTraitCollection:nil];
	self.navigationItem.leftBarButtonItem =
	[[UIBarButtonItem alloc] initWithImage:navBackImage
									 style:UIBarButtonItemStylePlain
									target:self
									action:@selector(popDidClick)];
	
	NSDictionary *attributes = self.navigationController.navigationBar.titleTextAttributes;
	UIColor *titleColor = nil;
	if (nil == attributes) {
		
		titleColor = self.navigationController.navigationBar.tintColor ?:[UIColor blackColor];
		attributes = attributes?:@{NSFontAttributeName : [UIFont systemFontOfSize:17],
								   NSForegroundColorAttributeName :  titleColor,
								   };
	} else {
		titleColor = [attributes objectForKey:NSForegroundColorAttributeName];
	}
	NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"完成" attributes:attributes];
	CGSize size = title.size;
	LZCameraLoadingButton *loadingBtn = [[LZCameraLoadingButton alloc] initWithTitle:title shapColor:[UIColor clearColor] frame:CGRectMake(0, 0, size.width + 5, 30)];
	loadingBtn.circleColor = titleColor;
	loadingBtn.maskColor = [UIColor clearColor];
	loadingBtn.loadColor = titleColor;
	[loadingBtn addTarget:self action:@selector(doneDidClick)];
	self.doneLoadingItem = loadingBtn;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingBtn];
}

- (void)configEditorMusicContainerView {
	
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
		[strongSelf syncPlayBGMusic];
	};
	[self.musicView updateEditEnable:YES];
}

- (void)scheduledTimer {
	
	__weak typeof(self) weakSelf = self;
	self.timer =
	[LZWeakTimer scheduledTimerWithTimeInterval:1.0f
										repeats:YES
								  dispatchQueue:dispatch_get_main_queue()
								   eventHandler:^{
									 
									   typeof(weakSelf) strongSelf = weakSelf;
									   CGFloat exportProgress = strongSelf.exportSession.progress;
									   [strongSelf.musicView updateEditProgress:exportProgress];
								   }];
}

- (void)syncPlayBGMusic {
	
	[self stopPlay];
	[self.musicView updateEditEnable:NO];
	self.exportSession =
	[LZCameraToolkit cutAsset:[self fetchBGMURL]
						 type:LZCameraAssetTypeM4A
					 timeRane:CMTimeRangeMake(kCMTimeZero, self.timeRange.duration)
			completionHandler:^(NSURL * _Nullable outputFileURL, BOOL success) {
				
				[self.timer invalidate];
				[self.musicView updateEditProgress:1.0f];
				[self.musicView updateEditEnable:YES];
				if (success) {
					
					NSError *error;
					self.BGMPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:outputFileURL error:&error];
					if (error == nil) {

						self.BGMPlayer.numberOfLoops = -1;
						self.BGMPlayer.volume = BGMVolume;
						[self.BGMPlayer prepareToPlay];
						[self startPlay];
					}
				}
			}];
	[self scheduledTimer];
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
	if (CMTIMERANGE_IS_EMPTY(self.timeRange) || CMTIMERANGE_IS_INVALID(self.timeRange)) {
		
		AVAsset *asset = [AVAsset assetWithURL:self.videoURL];
		self.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
	}
	self.videoPlayer.timeRange = self.timeRange;
	self.videoPlayer.playerLayer.frame = self.previewImgView.frame;
	[self.view.layer insertSublayer:self.videoPlayer.playerLayer above:self.previewImgView.layer];
	[self startPlay];
}

- (void)startPlay {
	
	[self.videoPlayer play];
	[self.BGMPlayer play];
}

- (void)stopPlay {
	
	[self.timer invalidate];
	[self.videoPlayer pause];
	[self.BGMPlayer pause];
}

@end
