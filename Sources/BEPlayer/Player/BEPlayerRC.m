//
//  BEPlayerRC.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/1.
//

#import "BEPlayerRC.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <notify.h>
//static BEPlayer* player;

static BOOL screenLocked = NO;

static BOOL screenOn = YES;

@interface BEPlayerRC ()

//@property(nonatomic, weak) BEPlayer* player;

@end

@implementation BEPlayerRC


static void handleScreenStatusNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
    
    uint64_t state;
    
    int token;
    
    notify_register_check("com.apple.iokit.hid.displayStatus", &token);
    
    notify_get_state(token, &state);
    
    notify_cancel(token);
    
    if ((uint64_t )1 == state) {
        
        printf("============ 点亮 \n");
        screenOn = YES;
        
    }else{
        
        printf("============  熄灭\n");
        screenOn = NO;
    }
}


- (void)BESpringboardStatusForLock:(NSNotification *) notify {
    
    BOOL isLock = [[notify object] boolValue];
    
    screenLocked = isLock;
}


- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"%s", __func__);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, handleScreenStatusNotification, CFSTR("com.apple.iokit.hid.displayStatus"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BESpringboardStatusForLock:) name:@"BESpringboardStatusForLock" object:nil];
        
        
        self.receivingRemoteControlEvents = NO;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    
    return self;
}

- (void)setReceivingRemoteControlEvents:(BOOL)receivingRemoteControlEvents {
    
    if (receivingRemoteControlEvents == _receivingRemoteControlEvents) {
        
        return;
    }
    
    _receivingRemoteControlEvents = receivingRemoteControlEvents;
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong BEPlayerRC* strongSelf = weakSelf;
        
        if (strongSelf->_receivingRemoteControlEvents) {
            
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        }else{
            
            [[AVAudioSession sharedInstance] setActive:NO error:nil];
            [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
        }
    });
    
    [self configRemoteCommandCenterHandler:_receivingRemoteControlEvents];
}

//锁屏界面开启和监控远程控制事件
- (void)configRemoteCommandCenterHandler:(BOOL) isAdd{
    
    __weak typeof(self) weakSelf = self;
    
    MPRemoteCommandCenter* center = [MPRemoteCommandCenter sharedCommandCenter];
    
    if (isAdd) {
        
        MPRemoteCommand* cmdPlay = [center playCommand];
        
        cmdPlay.enabled = YES;
        
        [cmdPlay addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent* event){
            
            [weakSelf actionFor:BEPlayerRCActionPlay];
            
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        
        MPRemoteCommand* cmdPause = [center pauseCommand];
        
        cmdPause.enabled = YES;
        
        [cmdPause addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent* event){
            
            [weakSelf actionFor:BEPlayerRCActionPause];
            
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        
        MPRemoteCommand* cmdNext = [center nextTrackCommand];
        
        cmdNext.enabled = YES;
        
        [cmdNext addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent* event){
            
            [weakSelf actionFor:BEPlayerRCActionPlayNext];
            
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        
        MPRemoteCommand* cmdPrevious = [center previousTrackCommand];
        
        cmdPrevious.enabled = YES;
        
        [cmdPrevious addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent* event){
            
            [weakSelf actionFor:BEPlayerRCActionPlayPrevious];
            
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        
        MPRemoteCommand* cmdTogglePlayPause = [center togglePlayPauseCommand];
        
        cmdTogglePlayPause.enabled = YES;
        
        [cmdTogglePlayPause addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent* event){
            
            [weakSelf actionFor:BEPlayerRCActionTogglePlayPause];
            
            return MPRemoteCommandHandlerStatusSuccess;
        }];
    }else{
        
        [center.playCommand removeTarget:self];
        [center.pauseCommand removeTarget:self];
        [center.nextTrackCommand removeTarget:self];
        [center.previousTrackCommand removeTarget:self];
        [center.togglePlayPauseCommand removeTarget:self];
    }
    
}

- (void)actionFor:(BEPlayerRCAction )action {
    
    if (self.rcAction) {
        
        self.rcAction(action);
    }
}

- (void)updateLockedScreen:(NSDictionary *)dict {

    if (!dict) {
        
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
        
        self.receivingRemoteControlEvents = NO;
        
        return;
    }
    if (screenOn) {
        
        NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary:dict];
        
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
    }
}

@end
