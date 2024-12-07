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
@property (nonatomic, assign) uint64_t limitCacheSize;

+ (instancetype)share;


#pragma mark - 兼容旧接口 - Public

- (BOOL )preload:(NSString *)url;

- (BOOL )preload:(NSString *)url expected:(float)expectedPercent onTaskStatus:(void (^)(NSString* url, NSInteger status))onTaskStatusChange onProgress:(void (^)(NSString* url, uint64_t loaded, uint64_t total))onProcess onComplete:(void (^)(NSString *url, NSString *localPath, NSError*error))onComplete;

- (BOOL )cancelPreload:(NSString *)url;

- (BOOL )preloadGroup:(NSString *)groupName expected:(CGFloat )expected tasks:(NSArray *)urls onGroupProgress:(void (^)(NSString *group, NSInteger loadedCnt, NSInteger failedCnt, NSInteger totalCnt, uint64_t loadedBytes, uint64_t totalBytes))onProgress onSpeed:(void (^)(NSInteger ))onSpeed onComplete:(void (^)(NSDictionary *))onComplete;


#pragma mark - 下载
/**
 下载

 @param url URL
 */
- (void )preloadTask:(NSString *)url;


/**
 下载
 @param url URL
 @param expectedPercent 下载长度比例
 @param onTaskStatusChange 任务状态变化
 @param onProcess 进度回调
 @param onComplete 完成回调
 */
- (void )preloadTask:(NSString *)url expected:(float)expectedPercent onTaskStatus:(void (^)(NSString* url, NSInteger status))onTaskStatusChange onProgress:(void (^)(NSString* url, uint64_t loaded, uint64_t total))onProcess onComplete:(void (^)(NSString *url, NSString *localPath, NSDictionary *metric, NSError*error))onComplete;



/// 下载
/// @param url URL
/// @param group 组
/// @param expectedPercent 下载长度比例
/// @param onTaskStatusChange 任务状态回调
/// @param onProcess 进度回调
/// @param onComplete 完成回调
- (void )preloadTask:(NSString *)url group:(NSString *)group expected:(float)expectedPercent onTaskStatus:(void (^)(NSString *, NSInteger))onTaskStatusChange onProgress:(void (^)(NSString *, uint64_t, uint64_t))onProcess onComplete:(void (^)(NSString *url, NSString *localPath, NSDictionary *metric, NSError *error))onComplete;
/**
 组任务添加

 @param group 组名/标识符
 @param expectedPercent 预期下载长度(0-1)
 @param urls urls数组
 @param onGroupProgress 组任务进度回调
 @param onSpeed 组任务下载速度
 @param onComplete 组任务完成回调
 */
- (void)preloadTasksWithGroup:(NSString *)group expected:(double)expectedPercent tasks:(NSArray<NSString *> *)urls onGroupProgress:(void (^)(NSString *group, NSInteger loadedCnt, NSInteger failedCnt, NSInteger totalCnt, uint64_t loadedBytes, uint64_t totalBytes, NSDictionary* loadedTask))onGroupProgress onSpeed:(void (^)(NSInteger bps))onSpeed onComplete:(void (^)(NSDictionary *result, NSDictionary* metrics))onComplete;


#pragma mark - 取消下载
/**
 取消预加载

 @param url 目标URL
 */
- (void )cancelTask:(NSString *)url;


/**
 取消预加载

 @param url 目标URL
 @param onCompleteBlock 完成Block
 */
- (void)cancelTask:(NSString *)url onComplete:(void (^)(void))onCompleteBlock;


/// 按组或一组URL取消任务
/// @param urls URL集合
/// @param groups 组集合
/// @param onComplete 完成回调
- (void)cancelTasks:(NSArray<NSString *>*)urls groups:(NSArray<NSString *> *)groups onComplete:(void (^)(void))onComplete;


#pragma mark - 清理

/**
 清除缓存
 */
- (void )cleanAll;


/// 同cleanAll
/// @param onComplete 完成回调
- (void )cleanAll:(void(^)(void))onComplete;

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
- (uint64_t )cacheSize;
@end

NS_ASSUME_NONNULL_END
