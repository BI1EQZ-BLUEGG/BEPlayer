//
//  BEPlayerRC.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, BEPlayerRCAction) {
    BEPlayerRCActionPlay,
    BEPlayerRCActionPause,
    BEPlayerRCActionTogglePlayPause,
    BEPlayerRCActionPlayNext,
    BEPlayerRCActionPlayPrevious,
    BEPlayerRCActionLike,
    BEPlayerRCActionMark
};

@interface BEPlayerRC : NSObject

@property(nonatomic, copy) void (^rcAction)(BEPlayerRCAction );

@property(nonatomic, assign, getter= isReceivingRemoteControlEvents) BOOL receivingRemoteControlEvents;

+ (BEPlayerRC *)share;

- (void)updateLockedScreen:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
