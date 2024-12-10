//
//  BEPlayer.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/1.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "BEPlayerItem.h"
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>
#import "BEPlayController.h"
#import "BEPlayerConstants.h"

NS_ASSUME_NONNULL_BEGIN


@class BEPlayer;
@protocol BEPlayerDelegate<NSObject>

@optional

/**
 播放器状态已更新

 @param status 状态值
 */
- (void)player:(BEPlayer* _Nonnull )player status:(BEPlayerStatus )status;


/**
 视频缓冲数据已更新

 @param buffers 包含视频片段数据的数组  [Range]
 */
- (void)player:(BEPlayer* _Nonnull )player buffered:(NSArray<NSValue *> *_Nonnull) buffers;


/**
 播放进度已改变

 @param seconds 进度值 单位：秒
 */

- (void)player:(BEPlayer* _Nonnull)player progress:(Float64 )seconds;



/**
 开始播放第 idx 首歌曲

 @param index 索引
 */
- (void)player:(BEPlayer* _Nonnull )player didPlayAtIndex:(NSInteger )index;

/**
 播放速率已改变

 @param rate 速率值
 */
- (void)player:(BEPlayer *_Nonnull)player rateTo:(CGFloat )rate;


/**
 播放器音量已改变

 @param volume 音量值
 */
- (void)player:(BEPlayer* _Nonnull )player volumeTo:(CGFloat)volume;

@end





@interface BEPlayer : NSObject

@property(nonatomic, weak) id<BEPlayerDelegate> _Nullable delegate;


/**
 加载完成Asset或者Loading完成时是否开始自动播放，默认为YES
 */
@property(nonatomic, assign) BOOL autoPlayWhenReady;

/**
 是否自动管理屏幕常亮，初始化时设置，默认YES;
 */
@property(nonatomic, assign) BOOL autoIdleTimer;

/**
 时间轴更新周期，单位:ms，默认:1000ms
 */
@property(nonatomic, assign) Float64 timelineUpdatePeriod;

/**
 缓冲n秒视频数据后尝试播放， 默认3s, 0认为不尝试；
 */
@property(nonatomic, assign) Float64 secondsOfTryingToPlayAfterBuffering;

/**
 播放器渲染View
 */
@property(nonatomic, strong, readonly, nullable) UIView* playerView;


/**
 视频扩展模式（值为:AVLayerVideoGravityResizeAspect/AVLayerVideoGravityResizeAspectFill/AVLayerVideoGravityResize）
 */
@property(nonatomic, copy) NSString* _Nonnull videoFillMode;


/**
 视频渲染Layer尺寸
 */
@property(nonatomic, assign, readonly) CGRect videoRenderRect;

/**
 播放器状态
 */
@property(nonatomic, assign, readonly) BEPlayerStatus status;


/**
 视频总时长
 */
@property(nonatomic, assign, readonly) CMTime duration;


/**
 播放器当前播放时间
 */
@property(nonatomic, assign, readonly) CMTime currentTime;

/**
 已经缓冲数据时间点
 */
@property(nonatomic, assign) CMTime buffered;

/**
 Player Volume
 */
@property(nonatomic, assign) CGFloat volume;

/**
 播放速率
 */
@property(nonatomic, assign) float rate;


/**
 播放错误，当收到 BEPlayerStatusError 错误状态时，读取此值获取详细信息
 */
@property(nonatomic, strong, readonly) NSError* _Nullable error;


/**
 当前多媒体信息模型
 */
@property(nonatomic, strong)BEPlayerItem* _Nullable beCurrentItem;


@property(nonatomic, strong, nullable) id<AVAssetResourceLoaderDelegate> resourceLoader;


/// 专辑列表
@property(nonatomic, copy, readonly) NSArray<BEPlayerItem *>* album;

/**
 表示列表循环/单曲循环/随机
 */
@property(nonatomic, assign) BEPlayMode playMode;


/**
 当前播放索引
 */
@property(nonatomic, assign, readonly) NSUInteger currentIndex;

///**
// 初始化播放器
//
// @param url 视频资源URL
// @param delegate 播放器代理
// @return 播放器实例
// */
//- (instancetype)initWithURL:(NSURL* )url delegate:(id<BEPlayerDelegate> )delegate;




#pragma mark - Public
/**
 以专辑初始化播放器

 @param album 专辑列表<NSURL>
 @param delegate 代理对象
 @return 返回播放器实例
 */
- (instancetype _Nonnull)initWithAlbum:(NSArray<BEPlayerItem *> *_Nullable)album delegate:(id<BEPlayerDelegate>_Nullable)delegate;


/**
 更新专辑列表

 @param album 专辑列表
 @param idx 默认播放索引
 */
- (void)updateAlbum:(NSArray<BEPlayerItem *> *_Nullable)album playAtIndex:(NSInteger )idx;

/**
 播放
 */
- (void)play;


/**
 播放下一首

 @return 已是最后一首，返回NO
 */
- (BOOL)playNext;


/**
 播放上一首

 @return 已是第一首，返回NO
 */
- (BOOL)playPrevious;


/**
 播放专辑中指定索引视频/音频

 @param idx 索引位置
 @return 返回 NO 表示没有该项
 */
- (BOOL)playAtIndex:(NSInteger )idx;

/**
 暂停
 */
- (void)pause;


/**
 倒播、倒带
 */
- (void)rewind;


/**
 快进
 */
- (void)fastForward;


/**
 Seek到指定时间

 @param seekPoint 时间值，单位:秒
 */
- (void)seekTo:(Float64 )seekPoint;


/**
 Seek到指定时间

 @param seekPoint 时间值 单位秒
 @param onComplete Seek完成回调
 */
- (void)seekTo:(Float64)seekPoint onComplete:(nullable void (^_Nullable)(void))onComplete;


/**
 启用列表循环模式一次，即强制开启一次列表循环模式
 */
- (void)EnableListRepeatOnce;

@end

@interface _BEAVPlayer : AVPlayer
@end

NS_ASSUME_NONNULL_END
