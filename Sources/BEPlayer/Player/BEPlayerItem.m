//
//  BEPlayerItem.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEPlayerItem.h"

@implementation BEPlayerItem

- (instancetype)initWithURL: (NSURL *)mediaURL title: (NSString *) title
{
    self = [super init];
    if (self) {
        self.mediaURL = mediaURL;
        self.title = title;
    }
    return self;
}

- (instancetype)initWithPath: (NSString *)path title: (NSString *)title
{
    self = [super init];
    if (self) {
        self.mediaPath = path;
        self.title = title;
    }
    return self;
}

@end
