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

@property(nonatomic, strong) NSURL* mediaURL;
@property(nonatomic, copy) NSString* mediaPath;
@property(nonatomic, strong) NSURL* lrcURL;
@property(nonatomic, copy) NSString* title;
@property(nonatomic, strong) NSURL* cover;
@property(nonatomic, copy) AVMediaType mediaType;

- (instancetype)initWithPath: (NSString *)path title: (NSString *)title;
- (instancetype)initWithURL: (NSURL *)mediaURL title: (NSString *) title;

@end

NS_ASSUME_NONNULL_END
