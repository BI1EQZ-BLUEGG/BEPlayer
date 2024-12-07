//
//  UIDevice+Volume.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/1.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (Volume)


@property(nonatomic, strong) MPVolumeView* mpVolumeView;

- (void)setSysVolume:(CGFloat )volume;

- (CGFloat )sysVolume;

@end

NS_ASSUME_NONNULL_END
