#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BEPlayerItem : NSObject

/// 用于匹配 resourceLoader 对应的标识符
@property(nonatomic, copy, nullable) NSString* identifier;

/// 资源 URL
@property(nonatomic, strong, nullable) NSURL* mediaURL;

/// 资源路径
@property(nonatomic, copy, nullable) NSString* mediaPath;

/// 标题
@property(nonatomic, copy, nullable) NSString* title;

/// 封面 URL
@property(nonatomic, strong, nullable) NSURL* cover;

/// 资源类型
@property(nonatomic, copy, nullable) AVMediaType mediaType;

- (instancetype)initWithURL:(NSURL *)mediaURL identifier:(NSString *)identifier;

- (instancetype)initWithPath:(NSString *)path;

- (instancetype)initWithURL:(NSURL *)mediaURL;

@end

NS_ASSUME_NONNULL_END
