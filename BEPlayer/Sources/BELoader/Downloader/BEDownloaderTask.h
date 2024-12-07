//
//  BEDownloaderTask.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class BEDownloaderTaskModel;
@class BEDownloaderTaskDesc;
@interface BEDownloaderTask : NSObject

//@property(nonatomic, copy) void (^taskFinishedBlock)(NSString *key, NSString* filePath, NSError* error);

@property(nonatomic, strong) BEDownloaderTaskModel* model;

- (void)start;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
