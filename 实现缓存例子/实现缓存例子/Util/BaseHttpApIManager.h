//
//  BaseHttpApIManager.h
//  实现缓存例子
//
//  Created by rayootech on 16/6/22.
//  Copyright © 2016年 rayootech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger,HTTPUseCachePolicy) {
    HTTPCachePolicyUseCacheWhenNetError,
    HTTPCachePolicyUseCacheAlways
};

@class BaseHttpApIManager;

@protocol BaseHttpApIManagerDelegate <NSObject>

- (void)httpAPIManagerDidSuccess:(__kindof BaseHttpApIManager *)apiManager;
@optional
- (void)httpAPIManagerDidFaiture:(__kindof BaseHttpApIManager *)apiManager;

@end

typedef void(^HTTPFailureHandle)(__kindof BaseHttpApIManager *apiManager);
typedef void(^HTTPSuccessHandle)(__kindof BaseHttpApIManager *apiManager);

@interface BaseHttpApIManager : NSObject

@property (nonatomic,strong) id           responseObject;//未经处理的响应数据
@property (nonatomic,weak)   id<BaseHttpApIManagerDelegate> delegate;//仅共子类使用
@property (nonatomic,strong) NSError  *   error;//网络请求失败的错误，eg:请求超时、找不到服务器、网络不连通,当不是网络错误的时候为nil
@property (nonatomic,copy)   NSString *   code;//服务器返回的响应码
@property (nonatomic,copy)   NSString *   msg;//服务器返回的响应信息
@property (nonatomic,assign) BOOL         shoudCache; //是否缓存
@property (nonatomic,assign) BOOL         isFromCache; //数据是否来自缓存
@property (nonatomic,assign) HTTPUseCachePolicy useCachePolicy;//何时开启缓存

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
    failure:(HTTPFailureHandle)failure;

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
     failure:(HTTPFailureHandle)failure;

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
            failure:(HTTPFailureHandle)failure;


/**
 *  关闭当前网络请求
 */
- (void)cancel;

/**
 *  清空缓存数据
 */
+ (void)EmptyCache;



@end
