//
//  NSObject+BEPlayer.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/1.
//

#import "NSObject+BEPlayer.h"

@implementation NSObject (BEPlayer)

/// 同步主线程调用
/// - Parameters:
///   - selector: 方法
///   - delegate: 代理
BOOL DelegateAction(SEL selector, id delegate, void (^block)(void)) {

    if (delegate && [delegate respondsToSelector:selector]) {
        if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL),
                   dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
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

/// 异步主线程调用
/// - Parameters:
///   - selector: 方法
///   - delegate: 代理
BOOL AsyncDelegateAction(SEL selector, id delegate, void (^block)(void)) {
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

BOOL CMTimeEnabled(CMTime time) {

    return !(CMTIME_IS_INVALID(time) || CMTIME_IS_INDEFINITE(time) ||
             !CMTIME_IS_NUMERIC(time));
}

@end
