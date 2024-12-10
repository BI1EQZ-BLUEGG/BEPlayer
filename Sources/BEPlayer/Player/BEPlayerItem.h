//
//  BEPlayerItem.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BEPlayerItem : NSObject

@property(nonatomic, strong, nullable) NSURL* mediaURL;
@property(nonatomic, copy, nullable) NSString* mediaPath;
@property(nonatomic, strong, nullable) NSURL* lrcURL;
@property(nonatomic, copy, nullable) NSString* title;
@property(nonatomic, strong, nullable) NSURL* cover;
@property(nonatomic, copy, nullable) AVMediaType mediaType;

- (instancetype)initWithPath: (NSString *)path title: (NSString *)title;
- (instancetype)initWithURL: (NSURL *)mediaURL title: (NSString *) title;

@end

NS_ASSUME_NONNULL_END
