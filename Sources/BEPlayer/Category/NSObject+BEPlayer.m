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
        
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                block();
            });
            return YES;
        }
    }
    return NO;
}
    
BOOL CMTimeEnabled(CMTime time){
    
    return !(CMTIME_IS_INVALID(time) || CMTIME_IS_INDEFINITE(time) || !CMTIME_IS_NUMERIC(time));
}

@end
