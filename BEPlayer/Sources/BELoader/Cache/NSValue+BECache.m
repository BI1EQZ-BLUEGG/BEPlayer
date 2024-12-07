//
//  NSValue+BECache.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "NSValue+BECache.h"

@implementation NSValue (BECache)

+ (NSValue *)valueWithBEMCRange:(BEMCRange)range {
    
    NSValue* value = [NSValue valueWithBytes:&range objCType:@encode(BEMCRange)];
    
    return value;
}

- (BEMCRange )BEMCRangeValue {
    
    BEMCRange range;
    
    [self getValue:&range];
    
    return range;
}

@end
