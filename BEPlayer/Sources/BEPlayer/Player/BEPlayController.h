//
//  BEPlayController.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 播放控制模式
 
 - BEPlayModeListRepeat: 列表循环
 - BEPlayModeRepeat: 单曲循环
 - BEPlayModeShuffle: 随机
 - BEPlayModeListOnce: 列表一次
 - BEPlayModeOnce: 单曲一次
 */
typedef NS_ENUM(NSInteger, BEPlayMode) {
    BEPlayModeListRepeat,
    BEPlayModeRepeat,
    BEPlayModeShuffle,
    BEPlayModeListOnce,
    BEPlayModeOnce
};

@interface BEPlayController : NSObject


/**
 播放模式
 */
@property(nonatomic, assign) BEPlayMode mode;

/**
 播放列表部歌曲数
 */
@property(nonatomic, assign) NSUInteger cnt;


/**
 当前序号索引
 */
@property(nonatomic, assign) NSUInteger current;

/**
 启用列表循环模式一次
 */
- (void)EnableListRepeatOnce;

- (NSUInteger )next;

- (NSUInteger )previous;

@end

NS_ASSUME_NONNULL_END
