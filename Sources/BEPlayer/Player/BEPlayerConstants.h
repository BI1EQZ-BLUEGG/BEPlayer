//
//  Header.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/9.
//

#ifndef Header_h
#define Header_h

/**
 播放器状态枚举
 - BEPlayerStatusUnknow: 未知状态
 - BEPlayerStatusReady: 播放器已装备完毕，已获取 Meta 信息
 - BEPlayerStatusLoading: 正在加载
 - BEPlayerStatusPlaying: 正在播放
 - BEPlayerStatusPaused: 已暂停
 - BEPlayerStatusFinished: 播放完成
 - BEPlayerStatusError: 播放出错
 */
typedef NS_ENUM(NSUInteger, BEPlayerStatus) {
    BEPlayerStatusUnknow,
    BEPlayerStatusReady,
    BEPlayerStatusLoading,
    BEPlayerStatusPlaying,
    BEPlayerStatusPaused,
    BEPlayerStatusFinished,
    BEPlayerStatusError,
};


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

#endif /* Header_h */
