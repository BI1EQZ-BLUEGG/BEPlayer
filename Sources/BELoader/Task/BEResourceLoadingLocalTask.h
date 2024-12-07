//
//  BEResourceLoadingLocalTask.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BEResourceLoadingLocalTask : NSObject

@property(nonatomic, copy) NSString* localIdentifier;

@property(nonatomic, copy) NSString* resourceLoaderIdentifier;

@property(nonatomic, copy) void (^MediaLocalTaskDidFinished)(AVAssetResourceLoadingRequest *loadingRequest ,NSRange range ,NSError* error);
@property(nonatomic, copy) void (^MediaLocalTaskDidResponseData)(AVAssetResourceLoadingRequest *loadingRequest, NSData* data);

@property(nonatomic, copy) void (^MediaLocalTaskFinishedAll)(void);

- (void)addLocalTaskURL:(NSURL *)url range:(NSRange )range loadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest resourceLoaderIdentifier:(NSString *)resourceLoaderIdentifier;

- (void)cancelLocalTaskForLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest orResourceLoaderIdenifier:(NSString *)resourceLoaderIdentifier;

@end

NS_ASSUME_NONNULL_END
