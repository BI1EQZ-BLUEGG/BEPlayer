//
//  BEPlayerView.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AVPlayerLayer;
@class AVPlayer;
@interface BEPlayerView : UIView

@property(nonatomic, strong) AVPlayer* player;

@property(nonatomic, strong) NSString* videoFillMode;

@property(nonatomic, strong) AVPlayerLayer* playerLayer;

@end

NS_ASSUME_NONNULL_END
