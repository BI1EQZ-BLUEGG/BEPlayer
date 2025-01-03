//
//  BEResourceManager.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BEResourceManager : NSObject

/**
 缓存大小，默认1G
 */
@property(nonatomic, assign) uint64_t limitCacheSize;

+ (instancetype)share;

#pragma mark - 下载

- (void)preload: (NSString *)url
     identifier: (NSString *)identifier
       expected: (float) expected
          group: (NSString *)group
         status: (nullable void (^)(NSString *url, NSInteger status))onStatus
       progress: (nullable void (^)(NSString *url, uint64_t loadedBytes, uint64_t totalBytes))onProgress
       complete: (nullable void (^)(NSString *url, NSString *path, NSDictionary *metric, NSError *error))onComplete;

- (void)preloadGroup: (NSString *)group
                urls: (NSArray<NSString *> *)urls
         identifiers: (NSArray<NSString *> *)identifiers
            expected: (float)expected
            progress: (nullable void (^)(NSString *group, NSInteger loadedCount, NSInteger failedCount, NSInteger totalCount, uint64_t loaderBytes, uint64_t totalBytes, NSDictionary *loadedTask))onProgress
               speed: (nullable void (^)(NSInteger bps))onSpeed
            complete: (nullable void (^)(NSDictionary *result, NSDictionary *metrics))onComplete;

#pragma mark - 取消下载
/**
 取消预加载

 @param url 目标URL
 */
- (void)cancelTask:(NSString *)url;

/**
 取消预加载

 @param url 目标URL
 @param onCompleteBlock 完成Block
 */
- (void)cancelTask:(NSString *)url
        onComplete:(nullable void (^)(void))onCompleteBlock;

/// 按组或一组URL取消任务
/// @param urls URL集合
/// @param groups 组集合
/// @param onComplete 完成回调
- (void)cancelTasks:(NSArray<NSString *> *)urls
             groups:(NSArray<NSString *> *)groups
         onComplete:(nullable void (^)(void))onComplete;

#pragma mark - 清理

/**
 清除缓存
 */
- (void)cleanAll;

/// 同cleanAll
/// @param onComplete 完成回调
- (void)cleanAll:(nullable void (^)(void))onComplete;

/**
 清除指定文件或者组缓存文件
 urls和groups全为nil时，清除所有磁盘缓存

 @param urls 媒体URL数组
 @param groups 组名数组
 */
- (void)cleanCacheFiles:(NSArray *)urls orGroups:(NSArray *)groups;

#pragma mark - 统计
/**
 获取缓存大小

 @return 缓存大小
 */
- (uint64_t)cacheSize;
@end

NS_ASSUME_NONNULL_END
