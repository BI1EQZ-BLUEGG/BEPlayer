//
//  BEPlayerView.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEPlayerView.h"

@implementation BEPlayerView


- (instancetype)init{
    
    if (self = [super init]) {
        
        _videoFillMode = AVLayerVideoGravityResizeAspect;
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

+ (Class)layerClass {
    
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (void)setVideoFillMode:(NSString *)videoFillMode {
    
    _videoFillMode = (videoFillMode && videoFillMode.length > 0) ? videoFillMode : AVLayerVideoGravityResizeAspect;
    
    AVPlayerLayer* layer = (AVPlayerLayer *)[self layer];
    
    layer.videoGravity = self.videoFillMode;
}

- (AVPlayerLayer *)playerLayer {
    
    return (AVPlayerLayer *)self.layer;
}

@end
