//
//  BEPlayerItem.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEPlayerItem.h"

@implementation BEPlayerItem

- (instancetype)initWithURL: (NSURL *)mediaURL {
    self = [super init];
    if (self) {
        self.mediaURL = mediaURL;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)mediaURL identifier: (NSString *)identifier {
    self = [super init];
    if (self) {
        self.mediaURL = mediaURL;
        self.identifier = identifier;
    }
    return self;
}

- (instancetype)initWithPath: (NSString *)path {
    self = [super init];
    if (self) {
        self.mediaPath = path;
    }
    return self;
}

@end
