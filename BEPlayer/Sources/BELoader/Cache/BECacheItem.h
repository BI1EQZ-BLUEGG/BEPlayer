//
//  BECacheItem.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>
#import "../BEResourceLoaderConstants.h"
NS_ASSUME_NONNULL_BEGIN


/**
 缓存处理Block
 
 @param data 读/写的数据
 @param identifier 标识符
 @param flag 标记，0 - BEMCFlagTypeSuccess成功
 */
typedef void (^BECacheHandler)(NSData* _Nullable data, NSString* _Nullable identifier, BEMCFlagType flag);

@class BECacheItemFragment;
@class BECacheItemInfo;
@interface BECacheItem : NSObject

/**
 文件操作Handle
 */
@property(nonatomic, strong) NSFileHandle* _Nullable fileHandle;


/// 标识是否空闲状态，空闲状态时收到 memroy warning 时自动移除释放
@property(nonatomic, assign, getter=isIdle) BOOL idle;


@property(nonatomic, copy) NSString *identifier;


@property(nonatomic, strong) NSDictionary* info;


@property(nonatomic, copy) NSString *extension;


@property(nonatomic, copy) NSString* fileName;


- (void)addFragment:(BECacheItemFragment *)fragment;

@end








@interface BECacheItemFragment : NSObject

/**
 标识
 */
@property(nonatomic, copy) NSString* identifier;

/**
 Sender标识符 即播放器层的 ResourceLoader 地址标识；
 */
@property(nonatomic, copy) NSString* senderIdentifier;

/**
 任务是否正在运行
 */
@property(nonatomic, assign, getter=isRunning) BOOL running;

/**
 操作,读/写
 */
@property(nonatomic, assign) BECacheAction action;

/**
 范围
 */
@property(nonatomic, assign) NSRange range;


/**
 计数，已读/已写
 */
@property(nonatomic, assign) uint64_t counter;

/**
 写操作数据,读操作时赋值长度为0的NSData
 */
@property(nullable, nonatomic, strong) NSData* data;

/**
 查询已经下载ranges和未下载ranges
 */
@property(nonatomic, copy) void (^queryRangeHandler)(uint64_t totalLenght, NSArray *loadedRanges, NSArray *pendingRanges, NSDictionary* info);

/**
 小片段读取时的新数据回调 ，默认 ReadBufferSize = 1024*1024
 */
@property(nonatomic, copy) void (^readNewDataHandler)(NSData* nData);

/**
 读取完成,通过 counter来判断是否读写成功
 */

/// fragment完成回调
@property(nonatomic, copy) BECacheHandler completeHandler;

@end

NS_ASSUME_NONNULL_END
