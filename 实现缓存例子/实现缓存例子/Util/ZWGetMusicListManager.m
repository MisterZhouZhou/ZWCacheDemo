//
//  ZWGetMusicListManager.m
//  实现缓存例子
//
//  Created by rayootech on 16/6/22.
//  Copyright © 2016年 rayootech. All rights reserved.
//

#import "ZWGetMusicListManager.h"

@implementation ZWGetMusicListManager

-(void)getMusicListInfo
{
  //聚合数据，查询天气
   NSString *urlString = @"http://v.juhe.cn/weather/index";
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"cityname"] = [@"北京" stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    parameters[@"key"] =@"077b7a55ac48ad77abe14fbbf130cabd";
    self.shoudCache = YES;
    
   [self GET:urlString parameters:parameters success:^(__kindof BaseHttpApIManager *apiManager) {
       NSLog(@"%@",apiManager.responseObject);
   } failure:^(__kindof BaseHttpApIManager *apiManager) {
       
   }];
}

@end
