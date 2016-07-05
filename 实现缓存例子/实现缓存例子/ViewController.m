//
//  ViewController.m
//  实现缓存例子
//
//  Created by rayootech on 16/6/22.
//  Copyright © 2016年 rayootech. All rights reserved.
//

#import "ViewController.h"
#import "ZWGetMusicListManager.h"
@interface ViewController ()

@property (nonatomic) ZWGetMusicListManager *musicListManager;

@end

@implementation ViewController

-(ZWGetMusicListManager *)musicListManager
{
    if (_musicListManager == nil) {
        _musicListManager = [[ZWGetMusicListManager alloc]init];
    }
    return _musicListManager;
}

//http://music.163.com/api/song/detail/?id=28377211&ids=%5B28377211%5D
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.musicListManager getMusicListInfo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
