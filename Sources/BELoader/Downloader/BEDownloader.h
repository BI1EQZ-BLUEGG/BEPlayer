//
//  BEDownloader.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BEDownloader : NSObject

/// 添加单个任务
/// @param url 资源 URL
/// @param identifier 自定义标识符
/// @param expectedPercent 期望下载长度（0.0-0.1）
/// @param groupName 组名
/// @param onTaskStatusChange 状态回调
/// @param onProcess 进度回调
/// @param onComplete 完成回调
- (void)addTask:(NSString *)url
     identifier:(NSString *)identifier
       expected:(float)expectedPercent
          group:(NSString *)groupName
   onTaskStatus:(void (^)(NSString *url, NSInteger status))onTaskStatusChange
     onProgress:(void (^)(NSString *url, uint64_t loadedBytes, uint64_t totalBytes))onProcess
     onComplete:(void (^)(NSString *url, NSString *path, NSDictionary *metric, NSError *error))onComplete;


/// 添加一组任务
/// @param group 组名
/// @param urls 资源数组
/// @param identifiers 自定义标识数组
/// @param expectedPercent 期望加载长度（0.0－1.0）
/// @param onGroupProgress 组进度回调
/// @param onGroupSpeed 组下载速度回调
/// @param onGroupComplete 组完成回调
- (void)addGroup:(NSString *)group
           tasks:(NSArray<NSString *> *)urls
     identifiers:(NSArray<NSString *> *)identifiers
        expected:(double)expectedPercent
 onGroupProgress:(void (^)(NSString *, NSInteger, NSInteger, NSInteger, uint64_t, uint64_t, NSDictionary *))onGroupProgress
         onSpeed:(void (^)(NSInteger))onGroupSpeed
      onComplete:(void (^)(NSDictionary *, NSDictionary *))onGroupComplete;

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
- (void)removeTask:(NSString *)url onComplete:(nullable void (^)(void))onComplete;

/**
 按组或批量取消任务

 @param urls URL集合
 @param groups 组集合
 @param onCompleteBlock 完成回调
 */
- (void)removeTasks:(NSArray *)urls groups:(NSArray *)groups onComplete:(nullable void (^)(void))onCompleteBlock;

@end

NS_ASSUME_NONNULL_END
