//
//  BEResourceTask.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BEResourceTask;
@protocol BEResourceTaskDelegate<NSObject>

- (void)mediaResourceTaskFinished:(BEResourceTask *)task;

- (void)mediaResourceTaskCanceled:(BEResourceTask *)task;

- (void)mediaResourceTaskSuspend:(BEResourceTask *)task;

@end

@interface BEResourceTask : NSObject

@property(nonatomic, copy) NSString* identifier;

@property(nonatomic, assign) BOOL isIdle;

@property(nonatomic, weak) id<BEResourceTaskDelegate> delegate;

- (void)addRequest:(AVAssetResourceLoadingRequest *)loadingRequest forResourceLoaderIdentifier:(NSString *)resourceLoaderIdentifier;

- (void)cancelRequest:(AVAssetResourceLoadingRequest *)loadingRequest forResourceLoaderIdentifier:(NSString *)resourceLoaderIdentifier;

@end

NS_ASSUME_NONNULL_END
