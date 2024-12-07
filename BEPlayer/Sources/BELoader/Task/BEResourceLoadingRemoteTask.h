//
//  BEResourceLoadingRemoteTask.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BEResourceLoadingRemoteTask : NSObject

@property(nonatomic, copy) NSString* remoteIdentifier;


@property(nonatomic, copy) NSString* resourceLoaderIdentifier;

/**
 是否缓存到磁盘。默认YES,当磁盘空间不足时为NO.
 */
@property(nonatomic, assign) BOOL cacheToDisk;


/**
 任务完成时回调，成功/失败
 */
@property(nonatomic, copy, nullable) void(^MediaRemoteTaskAllDidComplete)(void);

/**
 收到请求响应时获取总长度
 */
@property(nonatomic, copy, nullable) void(^MediaRemoteTaskDidResponse)(NSDictionary* contentInfo);

- (void)addRemoteTaskURL:(NSURL *)url range:(NSRange)range loadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest resourceLoaderIdentifier:(NSString *) resourceLoadingIdentifier;

- (void)cancelRemoteTaskForLoadingRequest:(nullable AVAssetResourceLoadingRequest *)loadingRequest orResourceLoaderIdentifier:(nullable NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
