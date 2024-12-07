//
//  BEDownloader.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BEDownloader : NSObject

/**
 添加

 @param url 目标URL
 */
- (void )addTask:(NSString *)url;

/**
 添加任务

 @param url 目标URL
 @param expectedPercent 期望下载百分比(值为0-1)。
 @param onTaskStatusChange 任务状态回调
 @param onProcess 下载进度回调
 @param onComplete 下载完成回调
 */
- (void )addTask:(NSString *)url expected:(float)expectedPercent onTaskStatus:(void (^)(NSString* url, NSInteger status))onTaskStatusChange onProgress:(void (^)(NSString* url, uint64_t loaded, uint64_t total))onProcess onComplete:(void (^)(NSString *url, NSString *localPath, NSDictionary *, NSError*error))onComplete;


/// 添加任务
/// @param url 目标URL
/// @param group 组
/// @param expectedPercent 期望百分比（0-1）
/// @param onTaskStatusChange 状态回调
/// @param onProcess 进度回调
/// @param onComplete 完成回调
- (void )addTask:(NSString *)url group:(NSString *)group expected:(float)expectedPercent onTaskStatus:(void (^)(NSString *, NSInteger))onTaskStatusChange onProgress:(void (^)(NSString *, uint64_t, uint64_t))onProcess onComplete:(void (^)(NSString *, NSString *, NSDictionary *, NSError *))onComplete;


/**
 按组添加任务

 @param group 组名标识
 @param expectedPercent 预期下载长度(0-1)
 @param urls URL数组
 @param onGroupProgress 组任务下载进度
 @param onSpeed 下载速度
 @param onComplete 完成回调
 */
- (void)addGroup:(NSString *)group expected:(double)expectedPercent tasks:(NSArray<NSString *> *)urls onGroupProgress:(void (^)(NSString *, NSInteger, NSInteger, NSInteger, uint64_t, uint64_t,NSDictionary*))onGroupProgress onSpeed:(void (^)(NSInteger))onSpeed onComplete:(void (^)(NSDictionary *, NSDictionary* ))onComplete;



/**
 移除任务

 @param url 目标URL
 */
- (void)removeTask:(NSString *)url;


/**
 移除任务

 @param url 目标URL
 @param onComplete 完成回调
 */
- (void )removeTask:(NSString *)url onComplete:(void (^)(void))onComplete;


/**
 按组或批量取消任务

 @param urls URL集合
 @param groups 组集合
 @param onCompleteBlock 完成回调
 */
- (void)removeTasks:(NSArray *)urls groups:(NSArray *)groups onComplete:(void (^)(void)) onCompleteBlock;

@end

NS_ASSUME_NONNULL_END
