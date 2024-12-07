//
//  UIDevice+Volume.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/1.
//

#import "UIDevice+Volume.h"
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>

static const NSString* keyMpVolumeView;

@implementation UIDevice (Volume)


-(MPVolumeView *) mpVolumeView
{
    MPVolumeView* mpVolumeView = objc_getAssociatedObject(self, &keyMpVolumeView);
    
    if (!mpVolumeView) {
        
        MPVolumeView* _mpVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-1000, -100, 100, 100)];
        
        _mpVolumeView.hidden = YES;
        
        mpVolumeView = _mpVolumeView;
        
        objc_setAssociatedObject(self, &keyMpVolumeView, _mpVolumeView, OBJC_ASSOCIATION_RETAIN);
    }
    
    return mpVolumeView;
}

- (void)setMpVolumeView:(MPVolumeView *)mpVolumeView {
    
    if (mpVolumeView != self.mpVolumeView) {
        
        objc_setAssociatedObject(self, &keyMpVolumeView, mpVolumeView, OBJC_ASSOCIATION_RETAIN);
        
    }
}

- (CGFloat )sysVolume {
    
    return [[AVAudioSession sharedInstance] outputVolume];
}

- (void)setSysVolume:(CGFloat )volume {
    
    UISlider *volumeViewSlider = nil;
    
    self.mpVolumeView.frame = CGRectMake(-1000, -100, 100, 100);
    
    for (UIView *view in [self.mpVolumeView subviews])
    {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"])
        {
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    [volumeViewSlider setValue:volume];
}

@end
