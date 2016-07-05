//
//  HttpCache.m
//  实现缓存例子
//
//  Created by rayootech on 16/6/22.
//  Copyright © 2016年 rayootech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HttpCache.h"

//默认缓存文件扩展名
NSString *const kHttpCacheDefaultPathExtension = @"httpCache";
//默认缓存条数
NSUInteger const kHttpCacheDefaultCost = 10;

@interface HttpCache ()
//存放缓存数据的数组
@property NSMutableDictionary *inMemoryCache;
//存放缓存数据key的数组
@property NSMutableArray *recentlyUsedKeys;
//全局队列
@property dispatch_queue_t queue;

@end

@implementation HttpCache

#pragma mark - 写入缓存
- (void)flush {
    
    [self.inMemoryCache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSString *stringKey = [NSString stringWithFormat:@"%@", key];
        NSString *filePath = [[self.directoryPath stringByAppendingPathComponent:stringKey]
                              stringByAppendingPathExtension:kHttpCacheDefaultPathExtension];
        //是否存在缓存文件
        if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSError *error = nil;
            if(![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
                NSLog(@"%@", error);
            }
        }
        
        NSData *dataToBeWritten = nil;
        id objToBeWritten = self.inMemoryCache[key];
        dataToBeWritten = [NSKeyedArchiver archivedDataWithRootObject:objToBeWritten];
        [dataToBeWritten writeToFile:filePath atomically:YES];
    }];
    
    [self.inMemoryCache removeAllObjects];
    [self.recentlyUsedKeys removeAllObjects];
}


#pragma mark - 初始化缓存
/**
 *  初始化缓存
 *
 *  @param cacheDirectory 设置缓存文件名称
 *  @param inMemoryCost   缓存条数
 *
 *  @return self
 */
-(instancetype) initWithCacheDirectory:(NSString*) cacheDirectory inMemoryCost:(NSUInteger) inMemoryCost
{
    NSParameterAssert(cacheDirectory != nil);
    if(self = [super init]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        //拼接缓存路径
        self.directoryPath   = [paths.firstObject stringByAppendingPathComponent:cacheDirectory];
        //初始化缓存条数
        self.cacheMemoryCost = inMemoryCost ? inMemoryCost: kHttpCacheDefaultCost;
        
        //初始化数组
        self.inMemoryCache   = [NSMutableDictionary dictionaryWithCapacity:self.cacheMemoryCost];
        self.recentlyUsedKeys= [NSMutableArray arrayWithCapacity:self.cacheMemoryCost];
        //判断缓存文件是否存在
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory    = YES;
        BOOL directoryExit  = [fileManager fileExistsAtPath:self.directoryPath isDirectory:&isDirectory];
        //不是目录
        if (!isDirectory) {
            NSError *error = nil;
            if(![fileManager removeItemAtPath:self.directoryPath error:&error]) {
                NSLog(@"%@", error);
            }
            directoryExit = NO;
        }
        
        if(!directoryExit)
        {
            NSError *error = nil;
            if(![fileManager createDirectoryAtPath:self.directoryPath
                                                withIntermediateDirectories:YES attributes:nil
                                                              error:&error]) {
                NSLog(@"%@", error);
            }
        }
        self.queue = dispatch_queue_create("com.http.cachequeue", DISPATCH_QUEUE_SERIAL);
        //收到内容警告
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flush)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        //进入后台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flush)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        //终止应用程序
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flush)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
     return self;
}

- (instancetype)init {
    
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"HttpCache should be initialized with the designated initializer initWithCacheDirectory:inMemoryCost:"
                                 userInfo:nil];
    return nil;
}



#pragma mark - 根据key获取缓存
/**
 *  根据key获取缓存
 *
 *  @param key key
 *
 *  @return 缓存
 */
- (id) objectForKeyedSubscript:(id<NSCopying>) key
{
    NSData *cachedData = self.inMemoryCache[key];
    if(cachedData) return cachedData;
    
    NSString *stringKey = [NSString stringWithFormat:@"%@", key];
    
    NSString *filePath = [[self.directoryPath stringByAppendingPathComponent:stringKey]
                          stringByAppendingPathExtension:kHttpCacheDefaultPathExtension];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        cachedData = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfFile:filePath]];
        self.inMemoryCache[key] = cachedData;
        return cachedData;
    }
    
    return nil;
}

#pragma mark - 设置缓存
/**
 *  设置缓存
 *
 *  @param obj 缓存值
 *  @param key key
 */
- (void)setObject:(id<NSCoding>)obj forKeyedSubscript:(id<NSCopying>) key
{
    dispatch_async(self.queue, ^{
        
        self.inMemoryCache[key] = obj;
        
        // inserts the recently added item's key into the top of the queue.
        NSUInteger index = [self.recentlyUsedKeys indexOfObject:key];
        
        if(index != NSNotFound) {
            [self.recentlyUsedKeys removeObjectAtIndex:index];
        }
        
        [self.recentlyUsedKeys insertObject:key atIndex:0];
        
        if(self.recentlyUsedKeys.count > self.cacheMemoryCost) {
            
            id<NSCopying> lastUsedKey = self.recentlyUsedKeys.lastObject;
            id objectThatNeedsToBeWrittenToDisk = [NSKeyedArchiver archivedDataWithRootObject:self.inMemoryCache[lastUsedKey]];
            [self.inMemoryCache removeObjectForKey:lastUsedKey];
            
            NSString *stringKey = [NSString stringWithFormat:@"%@", lastUsedKey];
            
            NSString *filePath = [[self.directoryPath stringByAppendingPathComponent:stringKey] stringByAppendingPathExtension:kHttpCacheDefaultPathExtension];
            
            if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                
                NSError *error = nil;
                if(![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
                    NSLog(@"Cannot remove file: %@", error);
                }
            }
            
            [objectThatNeedsToBeWrittenToDisk writeToFile:filePath atomically:YES];
            [self.recentlyUsedKeys removeLastObject];
        }
    });
}

#pragma mark - 清除缓存
/**
 *  清除缓存
 */
- (void)emptyCache
{
    NSError *error = nil;
    NSArray *directoryContents = [[NSFileManager defaultManager]
                                  contentsOfDirectoryAtPath:self.directoryPath error:&error];
    if(error) NSLog(@"%@", error);
    
    error = nil;
    for(NSString *fileName in directoryContents) {
        NSString *path = [self.directoryPath stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if(error) NSLog(@"%@", error);
    }
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

@end
