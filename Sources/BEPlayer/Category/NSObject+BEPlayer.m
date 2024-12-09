//
//  NSObject+BEPlayer.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/1.
//

#import "NSObject+BEPlayer.h"

@implementation NSObject (BEPlayer)

//PerformDelegate
BOOL DelegateAction(SEL selector, id delegate, void (^block)(void)) {
    
    if (delegate && [delegate respondsToSelector:selector]) {
        if (dispatch_get_current_queue() == dispatch_get_main_queue()) {
            if (block) {
                block();
                return YES;
            }
        } else {
            if (block) {
                dispatch_sync(dispatch_get_main_queue(), block);
                return YES;
            }
        }
    }
    return NO;
}
    
BOOL CMTimeEnabled(CMTime time){
    
    return !(CMTIME_IS_INVALID(time) || CMTIME_IS_INDEFINITE(time) || !CMTIME_IS_NUMERIC(time));
}

@end
