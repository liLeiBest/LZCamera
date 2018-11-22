//
//  LZPreviewViewController.m
//  LZCamera_Example
//
//  Created by Dear.Q on 2018/11/19.
//  Copyright © 2018 lilei_hapy@163.com. All rights reserved.
//

#import "LZPreviewViewController.h"

@interface LZPreviewViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation LZPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView.image = self.preViewImage;
}

@end
