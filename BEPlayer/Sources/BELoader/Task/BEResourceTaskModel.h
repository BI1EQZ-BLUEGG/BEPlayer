//
//  BEResourceTaskModel.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BETaskType) {
    BETaskTypeLocal,
    BETaskTypeRemote
};

typedef NS_ENUM(NSUInteger, BEResourceTaskStatus) {
    BEResourceTaskStatusPending,
    BEResourceTaskStatusRunning,
    BEResourceTaskStatusSuspend,
    BEResourceTaskStatusCancelled,
    BEResourceTaskStatusCompleted
};

@interface BEResourceTaskModel : NSObject



@property(nonatomic, copy) NSString* resourceLoaderIdentifier;


/**
 缓冲区大小,默认初始化 10*1024
 */
@property(nonatomic, assign) NSUInteger bufferLimitSize;


/**
 当前缓冲数据偏移位置，即当前请求的响应数据的大小
 */
@property(nonatomic, assign) NSUInteger bufferOffset;

/**
 缓冲区
 */
@property(nonatomic, strong) NSMutableData* dataBuffer;


/**
 当前请求的 Range
 */
@property(nonatomic, assign) NSRange range;


/**
 当前任务状态
 */
@property(nonatomic, assign) BEResourceTaskStatus status;


/**
 任务类型 本地任务/远程任务
 */
@property(nonatomic, assign) BETaskType taskType;

/**
 Remote任务Task
 */
@property(nonatomic, strong) NSURLSessionDataTask* dataTask;


/**
 loadingRequest
 */
@property(nonatomic, strong) AVAssetResourceLoadingRequest* loadingRequest;

- (void)start;

- (void)cancel;

- (void)finishedWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
