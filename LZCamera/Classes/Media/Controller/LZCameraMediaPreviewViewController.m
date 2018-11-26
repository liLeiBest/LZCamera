//
//  LZCameraMediaPreviewViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/23.
//

#import "LZCameraMediaPreviewViewController.h"
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
    self.cancelBtn.layer.cornerRadius = 30.0f;
    UIImage *editlImg = [self imageInBundle:@"media_preview_edit"];
    [self.editBtn setImage:editlImg forState:UIControlStateNormal];
    self.editBtn.layer.cornerRadius = 30.0f;
    UIImage *surelImg = [self imageInBundle:@"media_preview_done"];
    [self.sureBtn setImage:surelImg forState:UIControlStateNormal];
    
    if (self.previewObject) {
        
        if ([self.previewObject isKindOfClass:[UIImage class]]) {
            
            self.previewImgView.image = self.previewObject;
        } else {
            
            AVAsset *asset = [AVAsset assetWithURL:self.previewObject];
            self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
            self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
            self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
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
}

// MARK: - UI Action
- (IBAction)cancelDidClick:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)editDidClick:(id)sender {
    
}

- (IBAction)sureDidClick:(id)sender {
    
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

@end
