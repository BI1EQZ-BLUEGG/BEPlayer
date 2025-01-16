//
//  NSString+URL.h
//  BEPlayer
//
//  Created by bluegg on 2025/1/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (URL)

- (NSString *)URLEncodString;

- (NSString *)URLDecodeString;

@end

NS_ASSUME_NONNULL_END
