//
//  BEPlayer+Album.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEPlayer+Album.h"
#import <objc/runtime.h>
#import "BEPlayController.h"

static const NSString* keyAlbum;
static const NSString* keyCurrentIndex;
static const NSString* keyPlayCtlActionSeed;

@implementation BEPlayer (Album)

#pragma mark - GET/SET

- (NSArray<BEPlayerItem *> *)albume {
    
    NSArray<BEPlayerItem *>* obj = objc_getAssociatedObject(self, &keyAlbum);
    
    if (!obj) {
        
        obj = [[NSArray alloc] init];
    }
    return obj;
}

- (void)setAlbume:(NSArray<BEPlayerItem *> *)albume {
    
    objc_setAssociatedObject(self, &keyAlbum, albume, OBJC_ASSOCIATION_COPY);
    
    self.currentIndex = 0;
    
    [self playCtlActionSeed].cnt = albume.count;
}

- (NSUInteger)currentIndex {
    
    return [[self playCtlActionSeed] current];
}

- (void)setCurrentIndex:(NSUInteger)currentIndex {
    
    [[self playCtlActionSeed] setCurrent:currentIndex];
}

- (BEPlayMode)playMode {
    
    return [self playCtlActionSeed].mode;
}

- (void)setPlayMode:(BEPlayMode)playMode {
    
    [self playCtlActionSeed].mode = playMode;
}

#pragma mark - Seed

- (BEPlayController *)playCtlActionSeed {
    
    BEPlayController* obj = objc_getAssociatedObject(self, &keyPlayCtlActionSeed);
    
    if (!obj) {
        
        obj = [[BEPlayController alloc] init];
        
        [self setPlayCtlActionSeed:obj];
    }
    return obj;
}

- (void)setPlayCtlActionSeed:(BEPlayController *)seed {
 
    objc_setAssociatedObject(self, &keyPlayCtlActionSeed, seed, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - Public

- (BEPlayerItem *)itemCurrent {

    NSUInteger idx = [[self playCtlActionSeed] current];
    
    BEPlayerItem* item = [self itemAtIndex:idx];
    
    return item;
}

- (BEPlayerItem *)itemNext {
    
    NSUInteger idx = [[self playCtlActionSeed] next];
    
    BEPlayerItem* item = [self itemAtIndex:idx];
    
    return item;
}

- (BEPlayerItem *)itemPrevious {
    
    NSUInteger idx = [[self playCtlActionSeed] previous];
    
    BEPlayerItem* item = [self itemAtIndex:idx];
    
    return item;
}

- (BEPlayerItem *)itemAtIndex:(NSInteger )index {
    
    if (index >= 0 && index < self.albume.count) {
        
        self.currentIndex = index;
        
        BEPlayerItem* item = [self.albume objectAtIndex:self.currentIndex];
        
        self.beCurrentItem = item;
        
        return item;
    }
    
    return nil;
}

- (void)EnableListRepeatOnce {
    
    [[self playCtlActionSeed] EnableListRepeatOnce];
}


@end
