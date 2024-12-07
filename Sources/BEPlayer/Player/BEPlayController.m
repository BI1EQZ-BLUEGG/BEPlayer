//
//  BEPlayController.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEPlayController.h"

@interface BEPlayController () {
    
    BEPlayMode _mode;
    
    //是否强制启用列表循环模式
    BOOL _isEnableListRepeatOnce;
}

@end

@implementation BEPlayController

- (void)EnableListRepeatOnce {
    
    _isEnableListRepeatOnce = YES;
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _mode = 0;
        
        _cnt = 0;
    }
    return self;
}

#pragma mark - GET/SET

- (BEPlayMode)mode {
    
    return _mode;
}

- (void)setMode:(BEPlayMode)mode {
    
    _mode = mode;
}

- (NSUInteger )next {
    
    NSUInteger index = NSUIntegerMax;
    
    NSUInteger action = self.mode;
    
    if(_isEnableListRepeatOnce) {
        
        action = BEPlayModeListRepeat;
        
        _isEnableListRepeatOnce = NO;
    }
    
    switch (action) {
            
        case BEPlayModeOnce:
        case BEPlayModeListRepeat: //顺序
        {
            NSUInteger toIdx = ++self.current;
            
            if (!(toIdx < self.cnt)) {
                
                toIdx = 0;
            }
            
            index = toIdx;
        }
            break;
        case BEPlayModeRepeat: //单曲
            
            index = self.current;
            
            break;
            
        case BEPlayModeShuffle: //随机
            
            index = [self randoms];
            
            break;
            
        case BEPlayModeListOnce:
            
            if (self.current+1 < self.cnt) {
                
                index = ++self.current;
            }else{
                
                return NSUIntegerMax;
            }
            
            break;
    }
    self.current = index;
    
    return index;
}

- (NSUInteger )previous {
    
    NSUInteger index = NSUIntegerMax;
    
    BEPlayMode action = self.mode;
    
    if(_isEnableListRepeatOnce) {
        
        action = BEPlayModeListRepeat;
        
        _isEnableListRepeatOnce = NO;
    }
    
    switch (action) {
            
        case BEPlayModeOnce:
        case BEPlayModeListOnce:
        case BEPlayModeListRepeat:
        {
            if (self.current != 0) {
                
                index = --self.current;
                
            }else{
                
                index = self.cnt-1;
            }
        }
            break;
        case BEPlayModeRepeat:
            
            index = self.current;
            
            break;
            
        case BEPlayModeShuffle:
            
            index = [self randoms];
            
            break;
    }
    
    self.current = index;
    
    return index;
}

- (NSUInteger )randoms{
    
    return arc4random() % self.cnt;
}

@end
