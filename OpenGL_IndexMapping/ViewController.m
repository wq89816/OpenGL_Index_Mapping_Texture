//
//  ViewController.m
//  OpenGL_IndexMapping
//
//  Created by zhangchi on 8/1/20.
//  Copyright © 2020 Wangqiao. All rights reserved.
//

#import "ViewController.h"
#import "HTView.h"


@interface ViewController ()

@property(nonatomic,strong)HTView *htView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     self.htView = (HTView *)self.view;
    // Do any additional setup after loading the view.
}


@end
