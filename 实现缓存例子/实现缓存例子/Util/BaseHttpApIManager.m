//
//  BaseHttpApIManager.m
//  实现缓存例子
//
//  Created by rayootech on 16/6/22.
//  Copyright © 2016年 rayootech. All rights reserved.
//

#import "BaseHttpApIManager.h"
#import "AFNetworking.h"
#import "NSString+Common.h"
#import "HttpCache.h"
#import "OpenUDID.h"

//默认缓存目录名
static NSString *const  kHttpDefaultNetCacheDirectory   = @"httpNetCache";
//默认缓存条数
static const NSUInteger kHttpDefaultNetMemoryCacheCost  = 10;

@interface HLHHttpClient : AFHTTPSessionManager
//实现缓存对象
@property (nonatomic) HttpCache *httpCache;
//单例
+ (instancetype)sharedClient;

@end

@implementation HLHHttpClient

+ (instancetype)sharedClient
{
    static HLHHttpClient *client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [HLHHttpClient manager];
        AFHTTPResponseSerializer *serializer     = [AFJSONResponseSerializer serializer];
        serializer.acceptableContentTypes        =
        [NSSet setWithObjects:@"application/json",
         @"text/json",
         @"text/plain",
         @"text/javascript",
         @"text/html",nil];
        client.requestSerializer.timeoutInterval = 60.0f;
        client.responseSerializer                = serializer;
        client.httpCache                          = [[HttpCache alloc] initWithCacheDirectory:kHttpDefaultNetCacheDirectory inMemoryCost:kHttpDefaultNetMemoryCacheCost];
    });
    return client;
}

@end





//------------------------------------BaseHttpApIManager-----------------------------------------

@interface BaseHttpApIManager ()

@property (nonatomic) NSURLSessionDataTask *dataTask;  //urlsection
@property (nonatomic) NSString             *singedString; //唯一签名

@end

@implementation BaseHttpApIManager

#pragma mark - init
- (instancetype)init
{
    self = [super init];
    if (self) {
        _shoudCache     = NO; //默认不缓存数据
        _useCachePolicy = HTTPCachePolicyUseCacheWhenNetError;
    }
    return self;
}

#pragma mark - 图片压缩方法
- (NSArray <NSData *>*)getImageDatas:(NSArray <UIImage *>*)images
{
    NSMutableArray <NSData *>*datas = @[].mutableCopy;
    for (UIImage *image in images) {
        UIImage *newImage = nil;
        float scale       = 1.0;
        NSData *imageData = UIImageJPEGRepresentation(image, scale);
        if (imageData.length < 0.1*1024*1024) {
            newImage = image;
        }
        else {
            do {
                imageData = UIImageJPEGRepresentation(image, scale);
                scale     = scale - 0.1;
            } while (imageData.length > 0.1*1024*1024 && scale>0);
        }
        [datas addObject:imageData];
    }
    return nil;
}

/**
 *  get方法
 *
 *  @param URLString  url
 *  @param parameters 参数
 *  @param success    成功
 *  @param failure    失败
 */
- (void)GET:(NSString *)URLString
 parameters:(NSDictionary *)parameters
    success:(HTTPSuccessHandle)success
    failure:(HTTPFailureHandle)failure
{
   [self requestWithURL:URLString method:@"GET" parameters:parameters success:success failure:failure];
}

/**
 *  post方法
 *
 *  @param URLString  URLString
 *  @param parameters 参数
 *  @param success    成功
 *  @param failure    失败
 */
- (void)POST:(NSString *)URLString
  parameters:(NSDictionary *)parameters
     success:(HTTPSuccessHandle)success
     failure:(HTTPFailureHandle)failure
{
  [self requestWithURL:URLString method:@"POST" parameters:parameters success:success failure:failure];
}

/**
 *  上传图片
 *
 *  @param URLString  url
 *  @param parameters 参数
 *  @param name       图片名
 *  @param images     图片数组
 *  @param progress   进度
 *  @param success    成功
 *  @param failure    失败
 */
- (void)UploadImage:(NSString *)URLString
         parameters:(NSDictionary *)parameters
               name:(NSString *)name
             images:(NSArray <UIImage *>*)images
           progress:(void(^)(CGFloat progress))progress
            success:(HTTPSuccessHandle)success
            failure:(HTTPFailureHandle)failure
{
    __weak __typeof(self) weakSelf = self;
    HLHHttpClient *httpClient = [HLHHttpClient sharedClient];
    NSDictionary *commonParameters = [self commonParameters:parameters];
    self.dataTask =
    [httpClient POST:URLString parameters:commonParameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSArray <NSData *>* imageDatas= [weakSelf getImageDatas:images];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        for (int i=0;i<imageDatas.count;++i) {
            NSString *fileName = [NSString stringWithFormat:@"%@%@.png",[formatter stringFromDate:[NSDate date]],@(i)];
            [formData appendPartWithFileData:imageDatas[i] name:name fileName:fileName mimeType:@"image/png"];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) progress(uploadProgress.completedUnitCount/uploadProgress.totalUnitCount*1.0);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *result = responseObject[@"result"];
        NSString *code       = result[@"code"];
        NSString *msg        = result[@"msg"];
        self.msg             = msg;
        self.code            = code;
        if ([result[@"code"] isEqualToString:@"1000"]) {
            if (success) success(weakSelf);
        }
        else {
            if (failure) failure(weakSelf);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        weakSelf.error = error;
        if (failure) failure(weakSelf);
    }];
}


- (void)requestWithURL:(NSString *)URLString
                method:(NSString *)method
            parameters:(NSDictionary *)parameters
               success:(HTTPSuccessHandle)success
               failure:(HTTPFailureHandle)failure
{
    
    __weak __typeof(self) weakSelf = self;
    HLHHttpClient *httpClient = [HLHHttpClient sharedClient];
    NSDictionary *commonParameters = [self commonParameters:parameters];
    if(IsEmptyValue([parameters objectForKey:@"writeTime"])) {
        httpClient.requestSerializer.timeoutInterval = 30.0f;
    }
    else {
        httpClient.requestSerializer.timeoutInterval = 90.0f;
    }
    if (self.shoudCache && self.useCachePolicy == HTTPCachePolicyUseCacheAlways) {
        NSString *cacheKey      = [[URLString stringByAppendingString:self.singedString] md5];
        id cacheData            = httpClient.httpCache[cacheKey];
        if (cacheData) {
            self.responseObject = cacheData;
            self.isFromCache    = YES;
            success(self);
        }
    }
    
    if ([method isEqualToString:@"GET"]) {
        self.dataTask =
        [httpClient GET:URLString parameters:commonParameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [weakSelf success:success failure:failure responseObject:responseObject];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [weakSelf success:success failure:failure error:error];
        }];
    }
    else {
        self.dataTask =
        [httpClient POST:URLString parameters:commonParameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [weakSelf success:success failure:failure responseObject:responseObject];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [weakSelf success:success failure:failure error:error];
        }];
    }
}

#pragma mark - 处理请求成功方法
- (void)success:(HTTPSuccessHandle)success failure:(HTTPFailureHandle)failure  responseObject:(id)responseObject
{
    self.responseObject  = responseObject;
//    NSDictionary *result = responseObject[@"result"];
//    NSString *code       = result[@"code"];
//    NSString *msg        = result[@"msg"];
    
    //聚合api
    NSString *code       = responseObject[@"resultcode"];
    NSString *msg        = responseObject[@"reason"];
    
    self.msg             = msg;
    self.code            = code;
//     if ([code isEqualToString:@"1000"]) {
    if ([code isEqualToString:@"200"]) {
        self.isFromCache = NO;
        //设置缓存
        if (self.shoudCache) {
            HLHHttpClient *client = [HLHHttpClient sharedClient];
            NSLog(@"cachePath:%@",client.httpCache.directoryPath);
            NSLog(@"boundlePath:%@",[NSBundle mainBundle].bundlePath);
            NSString *cacheKey    = [[self.dataTask.currentRequest.URL.absoluteString stringByAppendingString:self.singedString] md5];
            client.httpCache[cacheKey] = responseObject;
//            [client.httpCache setObject:responseObject forKeyedSubscript:cacheKey];
        }
        if (success) success(self);
        if ([self.delegate respondsToSelector:@selector(httpAPIManagerDidSuccess:)]) {
            [self.delegate httpAPIManagerDidSuccess:self];
        }
    }
    else if ([code isEqualToString:@"5000"] || [code isEqualToString:@"9999"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"singalPoint"]) {
            
        }
        [self success:success failure:failure error:nil];
    }
    else if ([code isEqualToString:@"3005"]) {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
        [self success:success failure:failure error:nil];
    }
    else {
        [self success:success failure:failure error:nil];
    }
}

#pragma mark - 处理请求失败方法
- (void)success:(HTTPSuccessHandle)success failure:(HTTPFailureHandle)failure error:(NSError *)error
{
    HLHHttpClient *client  = [HLHHttpClient sharedClient];
    if (self.shoudCache && self.useCachePolicy == HTTPCachePolicyUseCacheWhenNetError) {
        NSString *cacheKey = [[self.dataTask.currentRequest.URL.absoluteString stringByAppendingString:self.singedString] md5];
        id cacheData       = client.httpCache[cacheKey];
        if (cacheData) {
            self.responseObject = cacheData;
            self.isFromCache    = YES;
            success(self);
        }
    }
    self.error = error;
    if (failure) failure(self);
    if ([self.delegate respondsToSelector:@selector(httpAPIManagerDidFaiture:)]) {
        [self.delegate httpAPIManagerDidFaiture:self];
    }
}

#pragma mark - 添加公共参数，签名参数
- (NSDictionary *)commonParameters:(NSDictionary *)parameters
{
    NSMutableDictionary *commonParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    UIDevice *device = [UIDevice currentDevice];
    NSBundle *bundle = [NSBundle mainBundle];
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    //获取bundleIdentifier
    NSString *bundleIdentifier = bundle.bundleIdentifier;
    //配置公共参数
    commonParameters[@"bundleIdentifier"]  = bundleIdentifier;
    commonParameters[@"device"]            = device.model;
    commonParameters[@"sign"]              = [self signWithParameters:commonParameters];
    return commonParameters;
}

#pragma mark - 签名参数
- (NSString *)signWithParameters:(NSDictionary *)parameters
{
    NSMutableString * signString = [NSMutableString string];
    NSArray *         keys       = [parameters allKeys];
    NSArray *         sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for(id key in sortedKeys) {
        id value = parameters[key];
        if ([value isKindOfClass:[NSString class]]) {
            [signString appendString:value];
        }
        else if ([value isKindOfClass:[NSArray class]])
        {
            for (NSString *str in value) {
                [signString appendString:[NSString stringWithFormat:@"%@",str]];
            }
        }
    }
    NSString * signedString = [signString md5];
    self.singedString       = signedString;
    return signedString;
}


/**
 *  关闭当前网络请求
 */
- (void)cancel
{
  [self.dataTask cancel];
}

- (void)dealloc
{
    [_dataTask cancel];
}

/**
 *  清空缓存数据
 */
+ (void)EmptyCache
{
    HLHHttpClient *client = [HLHHttpClient sharedClient];
    [client.httpCache emptyCache];
}



@end
