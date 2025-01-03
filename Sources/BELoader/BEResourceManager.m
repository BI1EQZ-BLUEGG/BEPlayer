//
//  BEResourceManager.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/3.
//

#import "BEResourceManager.h"
#import "Cache/BECache.h"
#import "Downloader/BEDownloader.h"

@interface BEResourceManager ()

@property(nonatomic, strong) BEDownloader *downloader;

@end

@implementation BEResourceManager

+ (instancetype)share {

    static dispatch_once_t once;

    static BEResourceManager *instance;

    dispatch_once(&once, ^{
      instance = [BEResourceManager new];
    });

    return instance;
}

- (void)dealloc {

    printf("%s\n", __func__);
}

- (instancetype)init {

    if (self = [super init]) {

        _downloader = [BEDownloader new];
    }
    return self;
}

#pragma mark - GET/SET

- (uint64_t)limitCacheSize {

    return [BECache share].limitCacheSize;
}

- (void)setLimitCacheSize:(uint64_t)limitCacheSize {

    [BECache share].limitCacheSize = limitCacheSize;
}

#pragma mark - Public

- (void)preload: (NSString *)url
     identifier: (NSString *)identifier
       expected: (float) expected
          group: (NSString *)group
         status: (nullable void (^)(NSString *url, NSInteger status)) onStatus
       progress: (nullable void (^)(NSString *url, uint64_t loadedBytes, uint64_t totalBytes)) onProgress
       complete: (nullable void (^)(NSString *url, NSString *path, NSDictionary *metric, NSError *error)) onComplete {
    
    [self.downloader addTask:url
                  identifier:identifier
                    expected:expected
                       group:group
                onTaskStatus:onStatus
                  onProgress:onProgress
                  onComplete:onComplete];
}

- (void)preloadGroup: (NSString *)group
                urls: (NSArray<NSString *> *)urls
         identifiers: (NSArray<NSString *> *)identifiers
            expected: (float)expected
            progress: (nullable void (^)(NSString *group, NSInteger loadedCount, NSInteger failedCount, NSInteger totalCount, uint64_t loaderBytes, uint64_t totalBytes, NSDictionary *loadedTask))onProgress
               speed: (nullable void (^)(NSInteger bps))onSpeed
            complete: (nullable void (^)(NSDictionary *result, NSDictionary *metrics))onComplete {
    
    [self.downloader addGroup:group
                        tasks:urls
                  identifiers:identifiers
                     expected:expected
              onGroupProgress:onProgress
                      onSpeed:onSpeed
                   onComplete:onComplete];
}

- (void)cancelTask:(NSString *)url {

    [self cancelTask:url onComplete:nil];
}

- (void)cancelTask:(NSString *)url onComplete:(void (^)(void))onCompleteBlock {

    [self.downloader removeTask:url onComplete:onCompleteBlock];
}

- (void)cancelTasks:(NSArray<NSString *> *)urls
             groups:(NSArray<NSString *> *)groups
         onComplete:(void (^)(void))onComplete {

    [self.downloader removeTasks:urls groups:groups onComplete:onComplete];
}

- (uint64_t)cacheSize {

    return [BECache cacheSize];
}

- (void)cleanAll {

    [BECache cleanAll];
}

- (void)cleanAll:(void (^)(void))onComplete {

    [BECache cleanAll:onComplete];
}

- (void)cleanCacheFiles:(NSArray *)urls orGroups:(NSArray *)groups {

    [BECache cleanCacheFiles:urls orGroups:groups];
}
@end
