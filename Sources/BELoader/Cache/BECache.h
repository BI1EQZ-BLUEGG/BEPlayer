//
//  BECache.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>
#import "BECacheItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface BECache : NSObject

/**
 缓存限制大小，默认1G
 */
@property (nonatomic, assign) uint64_t limitCacheSize;

+ (instancetype)share;


/**
 查询缓存详情
 
 @param key 标识符
 @param completeHandler 完成回调
 */
- (void)queryCacheRanges:(NSString *)key onComplete:(void (^)(uint64_t, NSArray * _Nonnull, NSArray * _Nonnull, NSDictionary* info))completeHandler;


/**
 读取数据
 
 @param range 数据范围
 @param identifier 标识符
 @param readDataHandler 回调
 @param handler 完成回调
 */
- (void )dataForRange:(NSRange )range identifier:(NSString *)identifier onReadNewData:(void(^)(NSData* nData))readDataHandler onComplete:(BECacheHandler) handler;


/**
 更新数据
 
 @param data 数据
 @param range 数据范围
 @param identifier 标识符
 @param totalLenght 总长度
 @param handler 完成回调
 */
- (void )updateData:(NSData *)data range:(NSRange)range identifier:(NSString *)identifier totalLenght:(uint64_t )totalLenght onComplete:(nullable BECacheHandler )handler;

/**
 更新文件信息

 @param info 文件信息
 @param identifier 标识符
 @param handler 完成回调
 */
- (void )updateContentInfo:(NSDictionary * _Nullable)info identifier:(NSString *)identifier onComplete:(BECacheHandler )handler;

/**
 读取文件缓存信息
 
 @param identifier 标识符
 @return 返回文件信息
 */
- (NSDictionary *)contentInfo:(NSString *)identifier;


/**
 缓存文件总大小
 
 @return 大小
 */
+ (uint64_t)cacheSize;


/**
 清除所有缓存数据 & 取消正在下载的任务
 */
+ (void )cleanAll;


/// 同cleanAll
/// @param onComplete 完成回调
+ (void )cleanAll:(void(^)(void))onComplete;


/**
 清除指定URL缓存或者组缓存 & 取消正在下载的任务

 @param files 媒体URL数组，直接删除文件，优先级大于按组删除
 @param groups 组名数组，如果有多组引用该文件，按组清除时，会将指定组名移除，移除后，如果没有其他组占用则删除文件，否则不删除
 */
+ (void)cleanCacheFiles:(NSArray * _Nullable)files orGroups:(NSArray * _Nullable)groups;


/// 异步回调 功能同上
/// @param files 同上
/// @param groups 同上
/// @param onComplete 完成回调
+ (void)cleanCacheFiles:(NSArray * _Nullable)files orGroups:(NSArray * _Nullable)groups onComplete:(void (^)(void))onComplete;

@end



@interface BECache (File)

+ (NSString *)pathForKey:(nullable NSString *)key extension:(nullable NSString *)extension;

+ (NSFileManager *)fileMgr;

+ (uint64_t)deleteFileWithIdentifier:(NSString *)identifier;

+ (void )enoughDiskSpaceForLength:(NSUInteger )expectLength onComplete:(void (^)(BOOL enoughSpace))onComplete;

@end

NS_ASSUME_NONNULL_END
