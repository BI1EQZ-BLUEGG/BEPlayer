//
//  BETool.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BETool.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/stat.h>
#import <sys/statvfs.h>
#import <CoreServices/CoreServices.h>

static NSTimer* timer;

static long long counter = 0;

@implementation BETool

dispatch_queue_t IOQueue(void){
    
    static dispatch_queue_t ioQueue = NULL;
    
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        
        if (!ioQueue) {
            
            ioQueue = dispatch_queue_create("BEMediaIOQueue", DISPATCH_QUEUE_CONCURRENT);
        }
    });
    return ioQueue;
}

dispatch_queue_t SerialQueue(void){
    
    static dispatch_queue_t serialQueue = NULL;
    
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        
        if (!serialQueue) {
            
            serialQueue = dispatch_queue_create("BEMediaSerialQueue", DISPATCH_QUEUE_SERIAL);
        }
    });
    return serialQueue;
}

+ (NSString *)md5:(NSString *)string {
    
    const char *cStr = [string UTF8String];
    
    unsigned char result[16];
    
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    
    NSString *key = [NSString stringWithFormat:
                     @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                     result[0], result[1], result[2], result[3],
                     result[4], result[5], result[6], result[7],
                     result[8], result[9], result[10], result[11],
                     result[12], result[13], result[14], result[15]
                     ];
    return [key uppercaseString];
}

+ (NSRange)rangeOfRequest:(NSURLRequest *)request {
    
    NSArray* rangeSegs = [[[request.allHTTPHeaderFields[@"Range"] componentsSeparatedByString:@"="] lastObject] componentsSeparatedByString:@"-"];
    
    if (rangeSegs.count == 2) {
        
        return NSMakeRange([rangeSegs[0] longLongValue], [(id)rangeSegs[1] longLongValue]+1);
    }else{
        
        return NSMakeRange(NSNotFound, NSNotFound);
    }
}


+ (NSRange)rangeOfResponse:(NSURLResponse *)response {
    
    NSRange range = NSMakeRange(NSUIntegerMax, NSUIntegerMax);
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        
        NSHTTPURLResponse* HTTPURLResponse = (NSHTTPURLResponse *)response;
        
        NSString* contentRange = HTTPURLResponse.allHeaderFields[@"Content-Range"]?:@"";
        
        NSError* error;
        
        NSRegularExpression* regular = [NSRegularExpression regularExpressionWithPattern:@"(\\d)+" options:0 error:&error];
        
        NSArray<NSTextCheckingResult *>* matches = [regular matchesInString:contentRange options:0 range:NSMakeRange(0, contentRange.length)];
        
        long long contentLength = 0;
        
        if (matches.count == 3) {
            
            contentLength = [[contentRange substringWithRange:matches[2].range] longLongValue];
            
            range.location = [[contentRange substringWithRange:matches[0].range] longLongValue];
            
            range.length = [[contentRange substringWithRange:matches[1].range] longLongValue] + 1;
            
        }else if (matches.count == 2){
            
            contentLength = [[contentRange substringWithRange:matches[1].range] longLongValue];
            
            range.location = [[contentRange substringWithRange:matches[0].range] longLongValue];
            
            range.length = contentLength - range.location;
        }
    }
    return range;
}

+ (NSDictionary *)cacheInfoByResponse:(NSURLResponse *)response task:(NSURLSessionTask *)task error:(NSError **)error {
    
    NSString* errorDomain = @"bluegg.media.cache";
    
    if (!response) {
        
        *error = [NSError errorWithDomain:errorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"response null"}];
        
        return nil;
    }
    
    NSString* mimeType = response.MIMEType;
    
    NSString* uti = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL));
    
    NSString* extension = CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef _Nonnull)(uti), kUTTagClassFilenameExtension))?:([NSURLComponents componentsWithString:task.originalRequest.URL.absoluteString].path.pathExtension?:@"");
    
    BOOL byteRangeAccessSupported = NO;
    
    BOOL validContentRange = NO;
    
    long long contentLength = 0;
    
    NSRange range = NSMakeRange(0, 0);
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        
        NSHTTPURLResponse* HTTPURLResponse = (NSHTTPURLResponse *)response;
        
        if (HTTPURLResponse.statusCode >= 300) {
            
            *error = [NSError errorWithDomain:errorDomain code:HTTPURLResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: @"HTTP Error"}];
            
            return nil;
        }
        
        NSString* acceptRange = HTTPURLResponse.allHeaderFields[@"Accept-Ranges"]?:HTTPURLResponse.allHeaderFields[@"accept-range"];
        
        byteRangeAccessSupported = [acceptRange isEqualToString:@"bytes"];
        
        NSString* contentRange = HTTPURLResponse.allHeaderFields[@"Content-Range"]?:@"";
        
        validContentRange = contentRange.length > 0;
        
        NSError* error;
        
        NSRegularExpression* regular = [NSRegularExpression regularExpressionWithPattern:@"(\\d)+" options:0 error:&error];
        
        NSArray<NSTextCheckingResult *>* matches = [regular matchesInString:contentRange options:0 range:NSMakeRange(0, contentRange.length)];
        
        if (matches.count == 3) {
            
            contentLength = [[contentRange substringWithRange:matches[2].range] longLongValue];
            
            range.location = [[contentRange substringWithRange:matches[0].range] longLongValue];
            
            range.length = [[contentRange substringWithRange:matches[1].range] longLongValue] + 1;
            
        }else if (matches.count == 2){
            
            contentLength = [[contentRange substringWithRange:matches[1].range] longLongValue];
            
            range.location = [[contentRange substringWithRange:matches[0].range] longLongValue];
            
            range.length = contentLength - range.location;
        }
    }
    
    if (!byteRangeAccessSupported && !validContentRange) {
        
        if (error != NULL) {
            
            *error = [NSError errorWithDomain:errorDomain code:-2 userInfo:@{NSLocalizedDescriptionKey: @"not support byte range access"}];
        }
    }

    if (contentLength) {
        
        NSMutableDictionary* info = [[NSMutableDictionary alloc] initWithDictionary:
                                     @{
                                         @"contentType":uti,
                                         @"contentLength":[NSNumber numberWithLongLong:contentLength],
                                         @"byteRangeAccessSupported":@(byteRangeAccessSupported),
                                         @"createTime":@(time(NULL)),
                                         @"range":[NSValue valueWithRange:range],
                                         @"extension":extension,
                                         @"validContentRange": @(validContentRange),
                                     }];
        return info;
    }else{
        
        *error = [NSError errorWithDomain:errorDomain code:-3 userInfo:@{NSLocalizedDescriptionKey:@"contentLength is 0"}];
    }
    return nil;
}

+ (NSDictionary* )fileAttribute:(NSString *)path {
    
    if ([path isKindOfClass:[NSString class]] && path.length > 0) {
        
        struct stat buf;
        
        if (stat(path.UTF8String, &buf) == 0) {
            
            return @{
                     @"createTime":@(buf.st_ctimespec.tv_sec),
                     @"lastAccessTime":@(buf.st_atimespec.tv_sec),
                     @"lastModifyTime":@(buf.st_mtimespec.tv_sec),
                     @"fileSize":@(buf.st_size)
                     };
        }
    }
    return nil;
}

+ (unsigned long)diskBlockSzie {
    
    static unsigned long disk_block_size = 0;
    
    if (disk_block_size == 0) {
        
        struct statvfs vfs;
        
        if (statvfs([NSBundle mainBundle].bundlePath.UTF8String, &vfs) < 0) {
            
            return 1048576;
        }else{
            
            disk_block_size = vfs.f_bsize;
        }
    }
    return disk_block_size;
}


+ (BOOL)setExtendedAttribute:(NSString*)attribute forKey:(NSString*)key withPath:(NSString*)path {
    
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:attribute format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    
    NSError *error;
    
    BOOL sucess = [[NSFileManager defaultManager] setAttributes:@{@"NSFileExtendedAttributes":@{key:data}}
                                                   ofItemAtPath:path error:&error];
    return sucess;
}

+ (id)getExtendedAttributeForKey:(NSString*)key  withPath:(NSString*)path {
    NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (!attributes) {
        return nil;
    }
    NSDictionary *extendedAttributes = [attributes objectForKey:@"NSFileExtendedAttributes"];
    if (!extendedAttributes) {
        return nil;
    }
    NSData *data = [extendedAttributes objectForKey:key];
    
    id plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:NSPropertyListImmutable error:nil];
    
    return [plist description];
}
//

+ (void)netSpeed:(long long )byte {
    
    counter += byte;
    
    if (!timer) {
        
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(cccc) userInfo:nil repeats:YES];
    }
    if (counter != 0) {
        
        [timer setFireDate:[NSDate date]];
    }
}

+ (void)cccc {
    
    static NSMutableArray* container = NULL;
    
    if (!container) {
        
        container = [[NSMutableArray alloc] initWithCapacity:3];
    }
    
    [container insertObject:@(counter) atIndex:0];
    
    counter = 0;
    
    if (container.count > 8) {
        
        [container removeLastObject];
    }
    __block long long tmp = 0;
    
    [container enumerateObjectsUsingBlock:^(NSNumber* obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        tmp += [obj longLongValue];
    }];
    
    NSString* str = [NSByteCountFormatter stringFromByteCount:tmp/container.count countStyle:NSByteCountFormatterCountStyleFile];
    
    printf("%s\\s\n", str.UTF8String);
    
    if (tmp == 0) {
        
        [timer setFireDate:[NSDate distantFuture]];
    }
}

@end
