//
//  NSObject+BEPlayer.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/1.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (BEPlayer)


/**
 封装 并简化 delegate 调用， 如: if（delegate && [delegate respondsToSelector:@selector(xxx)]）
 
 @param selector SEL
 @param delegate 消息接收者
 @param block 执行 block
 @return 执行成功/失败
 */
BOOL DelegateAction(SEL selector, id delegate, void (^block)(void));

    
/**
 检查CMTime是否为正常可用值

 @param time CMTime值
 @return YES 可用,NO 不可用
 */
BOOL CMTimeEnabled(CMTime time);

@end

NS_ASSUME_NONNULL_END
