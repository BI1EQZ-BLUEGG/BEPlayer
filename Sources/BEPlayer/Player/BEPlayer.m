//
//  BEPlayer.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/1.
//

#import "BEPlayer.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BEPlayerView.h"
#import "../Category/NSObject+BEPlayer.h"
#import "BEPlayController.h"

@interface BEPlayer () {
    /*
     *状态值 默认1 -> ..... -> ±7（loading 时调用 pause） -> ±2(缓存达到预期时长<secondsOfTryingToPlayAfterBuffering>) -> 0/1 (调用play)
     *seek时使用 -5（赋值前为0） -5（赋值前为1）标记；seek 完成后重置；
     */
    
    int _autoPlayWhenReadyFlag;
    
    NSDictionary* _kvoKeys;
    _BEAVPlayer* _player;
    id<NSObject> _timeObserver;
    CMTime _currentTime;
    float _rate;
    dispatch_queue_t serialQueue;
    NSString* BEPlayerKVOContext;
}

@property(assign) BEPlayerStatus status;

@property(nonatomic, strong) AVPlayerLayer* playerLayer;

@property(nonatomic, strong) AVURLAsset* asset;

@property(nonatomic, strong) UIView* playerView;

@property(nonatomic, strong) _BEAVPlayer* player;

@property(nonatomic, strong) NSError* error;

@property(nonatomic, assign) CMTime currentTime;

@property(nonatomic, assign) BEPlayerStatus beforeSeekingStatus;

@property(nonatomic, strong) BEPlayController* controller;

@property(nonatomic, assign) NSUInteger currentIndex;

@property(nonatomic, copy, readwrite) NSArray<BEPlayerItem *>* album;

@end

@implementation BEPlayer

- (void)dealloc {
    
    [_asset cancelLoading];
    
    [self unObserve];
    
    serialQueue = NULL;
    
    _playerView = nil;
    
    _player = nil;
    
    _timeObserver = nil;
    
    _playerLayer = nil;
    
    _asset = nil;
    
    _resourceLoader = nil;
    
//    printf("%s\n",__func__);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        BEPlayerKVOContext = [NSString stringWithFormat:@"KVOContext-%p",self];
        
        _secondsOfTryingToPlayAfterBuffering  = 3.5;
        
        _autoPlayWhenReadyFlag = 1;
        
        _rate = 1.f;
        
        _kvoKeys = @{@"":@0, @"player.currentItem.duration":@1, @"player.rate":@2, @"player.currentItem.status":@3, @"player.currentItem.loadedTimeRanges":@4,  @"player.currentItem.playbackBufferEmpty":@5, @"player.currentItem.playbackLikelyToKeepUp":@6, @"player.volume":@7};
        
        serialQueue = dispatch_queue_create("mediaplayer.bluegg.fun", DISPATCH_QUEUE_SERIAL);
        
        _autoIdleTimer = YES;
        
        _controller = [BEPlayController new];
        
        [self observe];
    }
    return self;
}

- (instancetype)initWithAlbum:(NSArray<BEPlayerItem *> *)album delegate:(id<BEPlayerDelegate>)delegate {

    if (self = [self init]) {
        
        [(BEPlayerView *)self.playerView playerLayer].player = self.player;
        
        self.delegate = delegate;
        
        self.album = album;
        
        [self updateAlbum:album playAtIndex:0];
    }
    return self;
}

- (void)updateAlbum:(NSArray<BEPlayerItem *> *)album playAtIndex:(NSInteger )idx {
    
    idx = idx != -1 ? idx : 0;
    
    self.album = album;
    
    self.currentIndex = idx;
    
    self.controller.current = idx;
    
    self.controller.cnt = album.count;
    
    if (album.count) {
        
        [self playAtIndex:idx];
    }else{
        
        __weak typeof(self) weakSelf = self;
        
        dispatch_async(serialQueue, ^{
            
            [weakSelf.player replaceCurrentItemWithPlayerItem:nil];
        });
    }
}

- (void)observe {
    
    [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&BEPlayerKVOContext];
    [self addObserver:self forKeyPath:@"player.volume" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&BEPlayerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.duration" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&BEPlayerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&BEPlayerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.loadedTimeRanges" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&BEPlayerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.playbackBufferEmpty" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&BEPlayerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&BEPlayerKVOContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemNewError:) name:AVPlayerItemNewErrorLogEntryNotification object:self.player.currentItem];
    
    [self updateTimelineObserver:YES];
}

- (void)unObserve {
    
    [self removeObserver:self forKeyPath:@"player.rate" context:&BEPlayerKVOContext];
    [self removeObserver:self forKeyPath:@"player.volume" context:&BEPlayerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.duration" context:&BEPlayerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:&BEPlayerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.loadedTimeRanges" context:&BEPlayerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.playbackBufferEmpty" context:&BEPlayerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.playbackLikelyToKeepUp" context:&BEPlayerKVOContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemNewErrorLogEntryNotification object:nil];
    
    [self updateTimelineObserver:NO];
}

- (void)updateTimelineObserver:(BOOL )enable {
    
    if (enable) {
        
        BEPlayer* __weak weakSelf = self;
        
        if (self.timelineUpdatePeriod == 0) {
            
            self.timelineUpdatePeriod = 1000;
        }
        if (_timeObserver) { return; }
        
        _timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(self.timelineUpdatePeriod, 1000) queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
            
            BEPlayer* strongSelf = weakSelf;
            
            if (!strongSelf) { return ; }
            
            strongSelf->_currentTime = time;
            
            DelegateAction(@selector(player:progress:), weakSelf.delegate, ^{
                
                [weakSelf.delegate player:weakSelf progress:CMTimeGetSeconds(time)];
            });
        }];
    }else{
        
        if (_timeObserver) {
            
            @try {
                
                [self.player removeTimeObserver:_timeObserver];
                
            } @catch (NSException *exception) {} @finally {
                
                _timeObserver = nil;
            }
        }
    }
}

// MARK: - GET/SET

- (_BEAVPlayer *)player {
    
    if (!_player) {
        
        _player = [_BEAVPlayer new];
        
        
        if(@available(iOS 10.0, *)){
            
            _player.automaticallyWaitsToMinimizeStalling = NO;
        }
    }
    return _player;
}

- (BOOL)autoPlayWhenReady {
    
    return _autoPlayWhenReadyFlag > 0;
}

- (void)setAutoPlayWhenReady:(BOOL)autoPlayWhenReady {
    
    _autoPlayWhenReadyFlag = autoPlayWhenReady ? 1 : 0;
}

- (CMTime)currentTime {
    
    CMTime currentTime = self.error ? _currentTime : self.player.currentTime;
    
    if (!CMTimeEnabled(currentTime)) {
        
        currentTime = kCMTimeZero;
    }
    return currentTime;
}

- (void)setCurrentTime:(CMTime)currentTime {
    
    if (!CMTimeEnabled(currentTime)) { return; }
    
    _currentTime = currentTime;
}

- (CMTime)duration{
    
    CMTime duration = self.player.currentItem.asset ? self.player.currentItem.asset.duration : kCMTimeZero;
    
    if (!CMTimeEnabled(duration)) {
        
        duration = kCMTimeZero;
    }
    
    return duration;
}

- (CGFloat)volume {
    
    return self.player.volume;
}

- (void)setVolume:(CGFloat)volume {
    
    self.player.volume = volume;
}

- (float)rate {
    
    return _rate;
}

- (void)setRate:(float)rate {
    
    _rate = rate;
    
    if (self.player.rate != 0) {
        
        self.player.rate = rate;
    }
}

- (UIView *)playerView {
    
    if (!_playerView) {
        
        BEPlayerView* view = [BEPlayerView new];
        
        _playerView = view;
    }
    return _playerView;
}

- (CGRect)videoRenderRect {
    
    return [[self playerLayer] videoRect];
}

- (AVPlayerLayer *)playerLayer {
    
    return [(BEPlayerView *)self.playerView playerLayer];
}

- (void)setVideoFillMode:(NSString *)videoFillMode {
    
    [(BEPlayerView *)self.playerView setVideoFillMode:videoFillMode];
}

- (void)setTimelineUpdatePeriod:(NSTimeInterval)timelineUpdatePeriod {
    
    if (_timelineUpdatePeriod == timelineUpdatePeriod){ return; }
    
    [self updateTimelineObserver:NO];
    
    _timelineUpdatePeriod = timelineUpdatePeriod;
    
    [self updateTimelineObserver:YES];
}

//MARK: Asset load

- (void)asynchronouslyLoadURLAsset:(AVURLAsset *) asset {
    
    self.status = BEPlayerStatusLoading;

    DelegateAction(@selector(player:status:), self.delegate, ^{

        [self.delegate player:self status:BEPlayerStatusLoading];
    });
    
    NSArray* assetKeys = @[@"tracks", @"playable", @"hasProtectedContent"];
    
    BEPlayer* __weak weakSelf = self;
    
    [asset loadValuesAsynchronouslyForKeys:assetKeys completionHandler:^{
        
        BOOL success = NO;
        
        for (NSString* key in assetKeys) {
            
            NSError* error = nil;
            
            AVKeyValueStatus status = [asset statusOfValueForKey:key error:&error];
            
            switch (status) {
                case AVKeyValueStatusFailed:
                {
                    weakSelf.status = BEPlayerStatusError;
                    
                    if (weakSelf.asset == asset) {
                        
                        weakSelf.error = error;
                        
                        DelegateAction(@selector(player:status:), weakSelf.delegate, ^{
                            
                            [weakSelf.delegate player:self status:BEPlayerStatusError];
                        });
                    }
                    
                    return;
                }
                    break;
                    
                case AVKeyValueStatusLoaded:
                {
                    NSInteger type = [assetKeys indexOfObject:key];
                    
                    switch (type) {
                        case 0:
                        {
                            //多媒体类型,
                            if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
                                
                                weakSelf.beCurrentItem.mediaType = AVMediaTypeVideo;
                                
                            }else if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0){
                                
                                weakSelf.beCurrentItem.mediaType = AVMediaTypeAudio;
                            }else{
                                
                                weakSelf.beCurrentItem.mediaType = @"unknow";
                            }
                            
                            success = YES;
                        }
                            break;
                        case 1:
                            
                            if (!asset.playable) { type = -1; }
                        case 2:
                        {
                            if (asset.hasProtectedContent) { type = -1; }
                            
                            //-1标记asset的playable\hasProtectedContent异常
                            if (type == -1) {
                                
                                DelegateAction(@selector(player:status:), self.delegate, ^{
                                    
                                    weakSelf.status = BEPlayerStatusError;
                                    
                                    weakSelf.error = [NSError errorWithDomain:@"localhost" code:-1 userInfo:@{@"info":@" AVPlayer can't play the contents or asset has protected content"}];
                                    
                                    [weakSelf.delegate player:weakSelf status:BEPlayerStatusError];
                                });
                                return;
                            }
                            break;
                        }
                    }
                    break;
                }
                default:
                    continue;
                    break;
            }
        }
        
        if (!success) {
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        dispatch_async(strongSelf->serialQueue, ^{
            
            AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
            
            if (@available(iOS 10.0, *)) {
                
                playerItem.preferredForwardBufferDuration = weakSelf.secondsOfTryingToPlayAfterBuffering;
            }
            
            if (asset == weakSelf.asset) {
                
                if (@available(iOS 8.0, *)) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [weakSelf.player replaceCurrentItemWithPlayerItem:playerItem];
                    });
                }else{
                    
                    [weakSelf.player replaceCurrentItemWithPlayerItem:playerItem];
                }
            }
        });
    }];
}


//MARK: Player Control - Public

- (void)play {
    
    if (self.player.rate == 0.0) {
        
        if (CMTIME_COMPARE_INLINE(self.currentTime, ==, self.duration)) {
            
            self.currentTime = kCMTimeZero;
        }
        if (self.error) {
            
            [self playAtIndex:self.currentIndex];
        }else{
            
            self.player.rate = self.rate;
        }
    }
    if (abs(_autoPlayWhenReadyFlag) == 2) {
        
        _autoPlayWhenReadyFlag = _autoPlayWhenReadyFlag > 0 ? 1 : 0;
    }
}

- (BOOL)playNext {
    
    BEPlayerItem* item = [self itemNext];
    
    if (item.mediaURL || item.mediaPath) {
        
        [self playItem:item];
        
        return YES;
    }
    return NO;
}

- (BOOL)playPrevious {
    
    BEPlayerItem* item = [self itemPrevious];
    
    if (item.mediaURL || item.mediaPath) {
        
        [self playItem:item];
        
        return YES;
    }
    return NO;
}

- (BOOL)playAtIndex:(NSInteger )idx {
    
    if (idx >= 0 && idx < self.album.count && self.beCurrentItem == [self.album objectAtIndex:idx] && !self.error){
        
        return YES;
    }
    
    BEPlayerItem* item = [self itemAtIndex:idx];
    
    if (item.mediaURL || item.mediaPath) {
        
        [self playItem:item];
        
        return YES;
    }
    
    return NO;
}

- (void)pause {
    
    if (self.player.rate != 0.0) {
        
        [self.player pause];
    }else{
        
        if (self.status == BEPlayerStatusLoading) {
            
            if (_autoPlayWhenReadyFlag == 1) {
                
                _autoPlayWhenReadyFlag = 7;
            }
            if (_autoPlayWhenReadyFlag == 0) {
                
                _autoPlayWhenReadyFlag = -7;
            }
        }
    }
}

- (void)rewind {
    self.rate = MAX(self.player.rate - 2.0, -2.0);
}

- (void)fastForward {
    self.rate = MIN(self.player.rate + 2.0, 2.0);
}

- (void)seekTo:(Float64 )seekPoint {
    
    [self seekTo:seekPoint onComplete:nil];
}

- (void)seekTo:(Float64)seekPoint onComplete:(void (^)(void))onComplete {
    
    CMTime t = self.player.currentItem.duration;
    
    CMTime toTime = kCMTimeZero;
    
    if (!CMTimeEnabled(t)) {
        
        toTime = CMTimeMake(seekPoint, 1000);
    }else{
        
        toTime = CMTimeMakeWithSeconds(seekPoint, self.player.currentItem.duration.timescale);
    }
    
    [self seek:toTime onComplete:onComplete];
}

//MARK: - Internal

- (void)seek:(CMTime )seekPoint onComplete:(void (^)(void))onComplete {
    
    if (self.status == BEPlayerStatusUnknow) { return; }
    
    self.currentTime = seekPoint;
    
//    NSLog(@"seekToTime ============ AAA");
    
    BEPlayer* __weak weakSelf = self;
    
    if (abs(_autoPlayWhenReadyFlag) == 5) {
        
        _autoPlayWhenReadyFlag = _autoPlayWhenReadyFlag > 0 ? 1 : 0;
        
        self.status = self.beforeSeekingStatus;
    }
    
    //由于seek不触发loading，此处手动触发并记住seek前的状态
    self.beforeSeekingStatus = self.status;

//    DelegateAction(@selector(player:status:), self.delegate, ^{
//
//        self.status = BEPlayerStatusLoading;
//        
//        [self.delegate player:self status:BEPlayerStatusLoading];
//    });
    
    //seek前记录autoPlayWhenReady状态，±5均表示seek发起的状态变化；(loading状态调用pause会设置_autoPlayWhenReadyFlag为-7)
    _autoPlayWhenReadyFlag = self.autoPlayWhenReady ? 5 : -5;
    
    [self pause];
    
    [self.player.currentItem cancelPendingSeeks];
    
    [self.player.currentItem seekToTime:seekPoint toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished){
        
//        NSLog(@"seekToTime ============ BBB = %@", @(finished));
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (!strongSelf) { return; }
        
        if (finished) {
            
            //还原状态
            self.status = strongSelf.beforeSeekingStatus;
            
            //上面手动触发loading，此处补全 pause 时的隐藏loading消息
            if (strongSelf.beforeSeekingStatus == BEPlayerStatusPaused) {
                
                DelegateAction(@selector(player:status:), self.delegate, ^{
                    
                    [self.delegate player:self status:BEPlayerStatusPlaying];
                    
                    [self.delegate player:self status:BEPlayerStatusPaused];
                });
            }
            
            strongSelf.beforeSeekingStatus = BEPlayerStatusUnknow;
            
            strongSelf->_autoPlayWhenReadyFlag = strongSelf->_autoPlayWhenReadyFlag > 0 ? 1 : 0;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (strongSelf.autoPlayWhenReady) {
                    
                    if ((strongSelf.status == BEPlayerStatusLoading && strongSelf.player.currentItem.playbackLikelyToKeepUp) || strongSelf.status == BEPlayerStatusPlaying) {
                        
                        [strongSelf play];
                    }
                }else{
                    
                    [strongSelf pause];
                }
                
                if (onComplete) { onComplete(); }
            });
        }
    }];
    
    DelegateAction(@selector(player:status:), self.delegate, ^{

        self.status = BEPlayerStatusLoading;
        
        [self.delegate player:self status:BEPlayerStatusLoading];
    });
}

- (void)playItem:(BEPlayerItem *)item {

    __weak typeof(self) weakSelf = self;
    
    dispatch_async(serialQueue, ^{
        
        __strong BEPlayer* strongSelf = weakSelf;
        
        if (strongSelf == NULL) { return; }
        
        [strongSelf.player cancelPendingPrerolls];
        
        [strongSelf.player replaceCurrentItemWithPlayerItem:nil];
        
        [strongSelf.asset cancelLoading];
        
        if (strongSelf->_error) {
            
            [strongSelf unObserve];
            
            strongSelf->_player = nil;
            
            strongSelf->_error = nil;
            
            [strongSelf observe];
        }
        
        strongSelf->_autoPlayWhenReadyFlag = strongSelf.autoPlayWhenReady ? 1 : 0;
        
        DelegateAction(@selector(player:didPlayAtIndex:), strongSelf.delegate, ^{
            
            [strongSelf.delegate player:strongSelf didPlayAtIndex:strongSelf.currentIndex];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [(BEPlayerView *)strongSelf.playerView playerLayer].player = strongSelf.player;
        });
        
        AVURLAsset *asset;
        
        if ([item.mediaPath isKindOfClass:[NSString class]] && item.mediaPath.length > 0){
            
            asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:item.mediaPath]];
            
        }else if (item.mediaURL) {
            
            NSURLComponents *components = [[NSURLComponents alloc] initWithURL:item.mediaURL resolvingAgainstBaseURL:NO];
            
            if (strongSelf.resourceLoader && ([components.scheme.lowercaseString isEqualToString:@"http"] || [components.scheme.lowercaseString isEqualToString:@"https"])) {
                
                components.scheme = [components.scheme stringByReplacingOccurrencesOfString:@"http" withString:@"BECachescheme"];
                
                asset = [AVURLAsset URLAssetWithURL:[components URL] options:nil];
                
                [asset.resourceLoader setDelegate:strongSelf.resourceLoader queue:dispatch_get_main_queue()];
                
                NSMutableDictionary* postDict = [NSMutableDictionary dictionaryWithCapacity:4];
                
                [postDict setValue:strongSelf.asset.URL.absoluteString forKey:@"oldUrl"];
                
                [postDict setValue:strongSelf.asset.resourceLoader forKey:@"oldResourceLoader"];
                
                [postDict setValue:asset.URL.absoluteString forKey:@"newUrl"];
                
                [postDict setValue:asset.resourceLoader forKey:@"newResourceLoader"];
                
                dispatch_async(asset.resourceLoader.delegateQueue, ^{
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"BEPlayerWillPlayNewItem" object:[postDict copy]];
                });
                
            }else{
                
                asset = [AVURLAsset assetWithURL:item.mediaURL];
            }
        }
        
        strongSelf.asset = asset;
        
        [strongSelf asynchronouslyLoadURLAsset:asset];
    });
    
}

//MARK: Play Finish
- (void)playerItemDidPlayFinished:(NSNotification *)notify {
    
    if ((AVPlayerItem *)notify.object != self.player.currentItem) { return; }
    
    self.status = BEPlayerStatusFinished;
    
    DelegateAction(@selector(player:status:), self.delegate, ^{
        
        [self.delegate player:self status:BEPlayerStatusFinished];
    });

    if (self.playMode != BEPlayModeOnce) {
        
        BEPlayerItem* item = [self itemNext];
        
        if (item) {
            
            [self playItem:item];
        }
    }
}

- (void)playerItemNewError:(NSNotification *)notify {
    
//    NSLog(@"+++++++++++++++++++++++++++++%@ - %@", notify.object, notify.userInfo);
}


//MARK: KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (context != &BEPlayerKVOContext) {
        
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        
        return;
    }
#if 0
    if (![keyPath isEqualToString:@"player.currentItem.loadedTimeRanges"]){

        NSLog(@"%@   -------------------------------------  %@", keyPath, change[NSKeyValueChangeNewKey]);
    }
#endif
    
    __weak typeof(self) weakSelf = self;
    
    NSInteger keyValue = [_kvoKeys[keyPath] integerValue];
    
    switch (keyValue) {
        case 0:
            
            break;
            //MARK:player.currentItem.duration
        case 1:
        {
            NSValue *durationVal = change[NSKeyValueChangeNewKey];
            
            CMTime durationTime = [durationVal isKindOfClass:[NSValue class]] ? [durationVal CMTimeValue] : kCMTimeZero;
            
            BOOL hasValidDuration = CMTIME_IS_VALID(durationTime) && CMTIME_IS_NUMERIC(durationTime) && durationTime.value != 0;
            
            if (hasValidDuration) {
                
            }
        }
            break;
        case 2://MARK:player.rate
        {
            double rate = [change[NSKeyValueChangeNewKey] doubleValue];
            
            self.status = rate == 0.0 ? BEPlayerStatusPaused : BEPlayerStatusPlaying;
            
            DelegateAction(@selector(player:rateTo:), self.delegate, ^{
                
                [self.delegate player:self rateTo:rate];
            });
            
            DelegateAction(@selector(player:status:), self.delegate, ^{
                
                if (rate == 0.0) {
                    
                    [self.delegate player:self status:BEPlayerStatusPaused];

                    if (self.autoIdleTimer) {
                        
                        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                    }
                    
                }else{
                    
                    [self.delegate player:self status:BEPlayerStatusPlaying];
                    
                    if (self.autoIdleTimer) {
                        
                        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
                    }
                }
            });
        }
            break;
        case 3://MARK:player.currentItem.status
        {
            
            NSNumber* statusNum = change[NSKeyValueChangeNewKey];
            
            AVPlayerItemStatus status = [statusNum isKindOfClass:[NSNumber class]] ? statusNum.integerValue : AVPlayerItemStatusUnknown;
            
            switch (status) {
                case AVPlayerItemStatusUnknown:
                {
                    self.status = BEPlayerStatusUnknow;
                }

                    break;
                case AVPlayerItemStatusFailed:
                {
                    self.status = BEPlayerStatusError;
                    
                    self.error = self.player.currentItem.error;
                    
                    DelegateAction(@selector(player:status:), self.delegate, ^{
                        
                        [self.delegate player:self status:BEPlayerStatusError];
                    });
                }
                    break;
                    
                case AVPlayerItemStatusReadyToPlay:
                {
                    self.status = BEPlayerStatusReady;
                    
                    DelegateAction(@selector(player:status:), self.delegate, ^{
                        
                        [self.delegate player:self status:BEPlayerStatusReady];
                    });
                    
                    if (self.autoPlayWhenReady) {
                        
                        if (self.player.rate != 0) {//TODO:音频触发
                            
                            DelegateAction(@selector(player:status:), self.delegate, ^{
                                
                                self.status = BEPlayerStatusPlaying;
                                
                                [self.delegate player:self status:BEPlayerStatusPlaying];
                            });
                        }
                        
                        if (self.player.currentItem.isPlaybackLikelyToKeepUp || self.player.currentItem.isPlaybackBufferFull) {
                            
//                            printf("\n======================== C ReadyToPlay %s \n", __func__);
                            [self play];
                        }
                    }else{
                        
                        [self pause];
                    }
                }
                    break;
            }
        }
            break;
        case 4://MARK:playerItem.loadedTimeRanges
        {
            CMTimeRange range = [self.player.currentItem.loadedTimeRanges.lastObject CMTimeRangeValue];
            
            self.buffered = CMTimeAdd(range.start, range.duration);
            
            BOOL tryToPlay =  self.secondsOfTryingToPlayAfterBuffering > 0 && CMTimeGetSeconds(self.buffered) - CMTimeGetSeconds(self.currentTime) > self.secondsOfTryingToPlayAfterBuffering;
            
            if (self.autoPlayWhenReady && tryToPlay) {
                
                BOOL flag = self.status == BEPlayerStatusLoading || self.status == BEPlayerStatusReady;

                if (flag) {
                    
                    [self play];
                }
            }else{
                
                if (abs(_autoPlayWhenReadyFlag) == 7 && tryToPlay) {
                    
                    DelegateAction(@selector(player:status:), self.delegate, ^{
                        
                        [self.delegate player:weakSelf status:BEPlayerStatusPlaying];
                        
                        [self.delegate player:weakSelf status:BEPlayerStatusPaused];
                    });
                    _autoPlayWhenReadyFlag = 2*(_autoPlayWhenReadyFlag/7);
                }
            }

            DelegateAction(@selector(player:buffered:), self.delegate, ^{
                
                [self.delegate player:weakSelf buffered:weakSelf.player.currentItem.loadedTimeRanges];
            });
        }
            break;
        case 5://MARK:playerItem.playbackBufferEmpty
        {
            NSNumber* value = change[NSKeyValueChangeNewKey];
            
            if (![value isKindOfClass:[NSNumber class]]) {
                
                return;
            }
            
            BOOL isBufferEmpty = [value boolValue];
            
            if (isBufferEmpty) {
                
                self.status = BEPlayerStatusLoading;
                
                [self pause];//确保状态顺序为  paused->loading.
                
                self.status = BEPlayerStatusLoading;
                
                DelegateAction(@selector(player:status:), self.delegate, ^{
                    
                    [self.delegate player:weakSelf status:BEPlayerStatusLoading];
                });
            }
        }
            
            break;
            
        case 6://MARK:playerItem.playbackLikelyToKeepUp
        {
            NSNumber* value = change[NSKeyValueChangeNewKey];
            
            if (![value isKindOfClass:[NSNumber class]]) {
                
                return;
            }
            
            BOOL isKeepUp = [value boolValue];
            
            if (isKeepUp) {
                
                if (self.status == BEPlayerStatusFinished) {
                    
//                    NSLog(@" ======: BEPlayerStatusFinished");
                    
                }else if(self.player.rate != 0) {
                    
                    self.status = BEPlayerStatusPlaying;

                    DelegateAction(@selector(player:status:), self.delegate, ^{

                        [self.delegate player:self status:BEPlayerStatusPlaying];
                    });
                }else if (self.player.rate == 0) {
                    
                    NSNumber* oldValue = change[NSKeyValueChangeOldKey];
                    
                    if (self.autoPlayWhenReady && (self.status == BEPlayerStatusLoading || self.status == BEPlayerStatusReady) && [oldValue boolValue] != [value boolValue]) {
                        
                        [self play];
                    }
                }
            }
        }
            break;
        case 7://MARK:player.volume
        {
            DelegateAction(@selector(player:volumeTo:), self.delegate, ^{
                
                NSNumber* value = change[NSKeyValueChangeNewKey];
                
                if (![value isKindOfClass:[NSNumber class]]) {
                    
                    return;
                }
                
                CGFloat volume = [value floatValue];
                
                [self.delegate player:self volumeTo:volume];
            });
        }
            break;
 
        default:
            
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
            break;
    }
}

- (BEPlayMode)playMode {
    return self.controller.mode;
}

- (void)setPlayMode:(BEPlayMode)playMode {
    self.controller.mode = playMode;
}

- (BEPlayerItem *)itemCurrent {

    NSUInteger idx = self.controller.current;
    
    BEPlayerItem* item = [self itemAtIndex:idx];
    
    return item;
}

- (BEPlayerItem *)itemNext {
    
    NSUInteger idx = self.controller.next;
    
    BEPlayerItem* item = [self itemAtIndex:idx];
    
    return item;
}

- (BEPlayerItem *)itemPrevious {
    
    NSUInteger idx = self.controller.previous;
    
    BEPlayerItem* item = [self itemAtIndex:idx];
    
    return item;
}

- (BEPlayerItem *)itemAtIndex:(NSInteger )index {
    
    if (index >= 0 && index < self.album.count) {
        
        self.currentIndex = index;
        
        BEPlayerItem* item = [self.album objectAtIndex:self.currentIndex];
        
        self.beCurrentItem = item;
        
        return item;
    }
    
    return nil;
}

- (void)EnableListRepeatOnce {
    
    [self.controller EnableListRepeatOnce];
}

@end



@implementation _BEAVPlayer
@end

