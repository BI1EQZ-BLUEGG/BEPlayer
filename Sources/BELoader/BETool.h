//
//  BETool.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BETool : NSObject

dispatch_queue_t SerialQueue(void);

dispatch_queue_t IOQueue(void);

+ (NSString *)md5:(NSString *)string;

+ (NSRange )rangeOfRequest:(NSURLRequest *)request;

+ (NSRange )rangeOfResponse:(NSURLResponse *)response;

+ (NSDictionary *)cacheInfoByResponse:(NSURLResponse *)response task:(NSURLSessionTask *)task error:(NSError **)error;

+ (NSDictionary* )fileAttribute:(NSString *)path;

+ (BOOL)setExtendedAttribute:(NSString*)attribute forKey:(NSString*)key withPath:(NSString*)path;

+ (id)getExtendedAttributeForKey:(NSString*)key  withPath:(NSString*)path;

+ (unsigned long)diskBlockSzie;

+ (void)netSpeed:(long long )byte;
@end

NS_ASSUME_NONNULL_END
