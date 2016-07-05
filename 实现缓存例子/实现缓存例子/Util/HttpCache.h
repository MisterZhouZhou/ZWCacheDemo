//
//  HttpCache.h
//  实现缓存例子
//
//  Created by rayootech on 16/6/22.
//  Copyright © 2016年 rayootech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HttpCache : NSObject

//文件缓存路径
@property NSString *directoryPath;
//缓存条数
@property NSUInteger cacheMemoryCost;
/**
 *  初始化缓存
 *
 *  @param cacheDirectory 设置缓存文件名称
 *  @param inMemoryCost   缓存条数
 *
 *  @return self
 */
-(instancetype) initWithCacheDirectory:(NSString*) cacheDirectory inMemoryCost:(NSUInteger) inMemoryCost;
/**
 *  根据key获取缓存
 *
 *  @param key key
 *
 *  @return 缓存
 */
- (id) objectForKeyedSubscript:(id<NSCopying>) key;
/**
 *  设置缓存
 *
 *  @param obj 缓存值
 *  @param key key
 */
- (void)setObject:(id<NSCoding>)obj forKeyedSubscript:(id<NSCopying>) key;
/**
 *  清除缓存
 */
- (void)emptyCache;

@end
