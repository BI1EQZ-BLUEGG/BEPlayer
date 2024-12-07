//
//  BEDownloaderGroupModel.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>
#import "BEDownloaderTaskModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BEDownloaderGroupModel : NSObject


/// 组名
@property(nonatomic, copy) NSString* groupName;


///组调用标识，用于区分每次调用，在多次调用且groupName相同时，也能分别返回处理
@property(nonatomic, copy) NSString* callIdentifier;


/**
 原始URL数组，主要用于任务完成排序
 */
@property(nonatomic, copy) NSArray* refUrls;

/**
 组任务下载回调
 */
@property(nonatomic, copy) void (^groupProgressBlock)(NSString* group, NSInteger loadedCnt, NSInteger failedCnt, NSInteger totalCnt, uint64_t loadeBytes, uint64_t totalBytes, NSDictionary* );

/**
 组下载速度
 */
@property(nonatomic, copy) void (^groupSpeedBlock)(NSInteger);


/**
 组任务完成
 */
@property(nonatomic, copy) void (^groupComplete)(NSDictionary *, NSDictionary* );


/**
 该组任务信息
 */
@property(nonatomic, strong) NSMutableDictionary<NSString *, BEDownloaderTaskModel* >* allTask;


- (void)task:(BEDownloaderTaskModel *)taskModel status:(BEDownloaderTaskStatus )status;

- (BOOL )checkGroup:(BEDownloaderTaskModel *)taskModel;

- (void)destroy;

@end

@interface BEDownloaderGroupHandlerSet : NSObject

@property(nonatomic, strong)NSMutableArray* groupProgressHandlers;

@property(nonatomic, strong)NSMutableArray* groupSpeedHandlers;

@property(nonatomic, strong)NSMutableArray* groupCompleteHandlers;

@end


NS_ASSUME_NONNULL_END
