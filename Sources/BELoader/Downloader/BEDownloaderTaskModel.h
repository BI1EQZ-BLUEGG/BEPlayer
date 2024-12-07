//
//  BEDownloaderTaskModel.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BEDownloaderTaskStatus) {
    BEDownloaderTaskStatusPending = 1,
    BEDownloaderTaskStatusRunning,
    BEDownloaderTaskStatusFinished,
    BEDownloaderTaskStatusCancelled
};

@class BEDownloaderTaskHandlerSet,BEDownloaderTaskDesc;
@interface BEDownloaderTaskModel : NSObject


/**
 资源URL
 */
@property(nonatomic, copy) NSString* url;

/**
 所属任务组，默认Default
 */
@property(nonatomic, copy) NSString* _Nullable groupName;
/**
 本地缓存资源路径
 */
@property(nonatomic, copy) NSString* localPath;


/**
 期望下载比率,0~1，默认1
 */
@property(nonatomic, assign) double expectedPercent;

/**
 标识符Key,URL md5值
 */
@property(nonatomic, copy) NSString* key;


/**
 任务状态
 */
@property(nonatomic, assign)BEDownloaderTaskStatus status;


/**
 出错时记录错误
 */
@property(nonatomic, strong) NSError* error;

/**
 已下载长度
 */
@property(nonatomic, assign) uint64_t loadedLength;

/**
 总长度
 */
@property(nonatomic, assign) uint64_t totalLength;


@property(nonatomic, strong) BEDownloaderTaskHandlerSet* handlerSet;

/**
 任务状态回调
 */
@property(nonatomic, copy) void (^taskStatusBlock)(NSString* key, NSString* url, BEDownloaderTaskStatus status);

/**
 单任务下载进度回调
 */
@property(nonatomic, copy) void (^progressBlock)(NSString* key, NSString* url, uint64_t loaded, uint64_t total);


/**
 下载完成回调
 */
@property(nonatomic, copy) void (^finishedBlock)(NSString* key, NSString *url, NSString* localPath, NSDictionary* metric, NSError* error);


/**
 任务状态描述
 */
@property(nonatomic, strong) BEDownloaderTaskDesc* taskDesc;

@end




@interface BEDownloaderTaskDesc : NSObject

@property(nonatomic, assign) double taskNetSpeed;

@property(nonatomic, strong) NSMutableArray* networkMetrics;

@property(nonatomic, strong) NSDictionary* metric;

- (void)newDataLength:(uint64_t )len;

@end



@interface BEDownloaderTaskHandlerSet : NSObject

@property(nonatomic, strong)NSMutableArray* statusHandlers;

@property(nonatomic, strong)NSMutableArray* progressHandlers;

@property(nonatomic, strong)NSMutableArray* finishHandlers;

@end

NS_ASSUME_NONNULL_END
