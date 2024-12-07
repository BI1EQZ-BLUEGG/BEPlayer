//
//  NSValue+BECache.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct _BEMCRange {
    
    uint64_t location;
    
    uint64_t length;
    
} BEMCRange;

NS_INLINE BEMCRange BEMCMakeRange(uint64_t loc, uint64_t len) {
    
    BEMCRange r;
    
    r.location = loc;
    
    r.length = len;
    
    return r;
}

@interface NSValue (BECache)

+ (NSValue *)valueWithBEMCRange:(BEMCRange)range;

- (BEMCRange )BEMCRangeValue;

@end

NS_ASSUME_NONNULL_END
