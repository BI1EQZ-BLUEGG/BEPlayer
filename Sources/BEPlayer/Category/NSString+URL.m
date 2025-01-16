//
//  NSString+URL.m
//  BEPlayer
//
//  Created by bluegg on 2025/1/5.
//

#import "NSString+URL.h"

@implementation NSString (URL)

- (NSString *)URLEncodString {
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8));
    return encodedString;
}

- (NSString *)URLDecodeString {
    return [self stringByRemovingPercentEncoding];
}

@end
