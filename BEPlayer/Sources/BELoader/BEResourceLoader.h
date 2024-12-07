//
//  BEResourceLoader.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/3.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BEResourceLoader :  NSObject<AVAssetResourceLoaderDelegate>

/**
 Weak Singleton 伪单例，所有对其引用对象释放时自动释放

 @return Instance
 */
+ (instancetype)share;

@end

NS_ASSUME_NONNULL_END
