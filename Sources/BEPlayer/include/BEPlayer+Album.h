//
//  BEPlayer+Album.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEPlayer.h"
#import "BEPlayController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BEPlayer (Album)

/**
 专辑列表
 */
@property(nonatomic, copy) NSArray<BEPlayerItem *>* albume;

/**
 表示列表循环/单曲循环/随机
 */
@property(nonatomic, assign) BEPlayMode playMode;


/**
 当前播放索引
 */
@property(nonatomic, assign, readonly) NSUInteger currentIndex;

/**
 启用列表循环模式一次，即强制开启一次列表循环模式
 */
- (void)EnableListRepeatOnce;

- (BEPlayerItem *)itemCurrent;

- (BEPlayerItem *)itemNext;

- (BEPlayerItem *)itemPrevious;

- (BEPlayerItem *)itemAtIndex:(NSInteger )index;

@end

NS_ASSUME_NONNULL_END
