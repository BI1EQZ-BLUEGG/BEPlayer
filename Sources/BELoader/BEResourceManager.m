//
//  BEResourceManager.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/3.
//

#import "BEResourceManager.h"
#import "Downloader/BEDownloader.h"
#import "Cache/BECache.h"

@interface BEResourceManager ()

@property(nonatomic, strong) BEDownloader* downloader;

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

- (void )preloadTask:(NSString *)url {
    
    [self.downloader addTask:url expected:1 onTaskStatus:nil onProgress:nil onComplete:nil];
}

- (void )preloadTask:(NSString *)url expected:(float)expectedPercent onTaskStatus:(void (^)(NSString *, NSInteger))onTaskStatusChange onProgress:(void (^)(NSString *, uint64_t, uint64_t))onProcess onComplete:(void (^)(NSString *, NSString *, NSDictionary *, NSError *))onComplete {
    
    [self.downloader addTask:url expected:expectedPercent onTaskStatus:onTaskStatusChange onProgress:onProcess onComplete:onComplete];
}

- (void )preloadTask:(NSString *)url group:(NSString *)group expected:(float)expectedPercent onTaskStatus:(void (^)(NSString *, NSInteger))onTaskStatusChange onProgress:(void (^)(NSString *, uint64_t, uint64_t))onProcess onComplete:(void (^)(NSString *, NSString *, NSDictionary *, NSError *))onComplete {
    
    [self.downloader addTask:url group:group expected:expectedPercent onTaskStatus:onTaskStatusChange onProgress:onProcess onComplete:onComplete];
}

- (void)preloadTasksWithGroup:(NSString *)group expected:(double)expectedPercent tasks:(NSArray<NSString *> *)urls onGroupProgress:(void (^)(NSString *group, NSInteger loadedCnt, NSInteger failedCnt, NSInteger totalCnt, uint64_t loadedBytes, uint64_t totalBytes, NSDictionary *loadedTask))onGroupProgress onSpeed:(void (^)(NSInteger bps))onSpeed onComplete:(void (^)(NSDictionary *result, NSDictionary* metrics))onComplete {
    
    [self.downloader addGroup:group expected:expectedPercent tasks:urls onGroupProgress:onGroupProgress onSpeed:onSpeed onComplete:onComplete];
}

- (void )cancelTask:(NSString *)url {
    
    [self cancelTask:url onComplete:nil];
}

- (void)cancelTask:(NSString *)url onComplete:(void (^)(void))onCompleteBlock {
    
    [self.downloader removeTask:url onComplete:onCompleteBlock];
}

- (void)cancelTasks:(NSArray<NSString *>*)urls groups:(NSArray<NSString *> *)groups onComplete:(void (^)(void))onComplete {
    
    [self.downloader removeTasks:urls groups:groups onComplete:onComplete];
}

- (uint64_t)cacheSize {
    
    return [BECache cacheSize];
}

- (void )cleanAll {

    [BECache cleanAll];
}

- (void )cleanAll:(void(^)(void))onComplete {
    
    [BECache cleanAll:onComplete];
}

- (void)cleanCacheFiles:(NSArray *)urls orGroups:(NSArray *)groups {
    
    [BECache cleanCacheFiles:urls orGroups:groups];
}
@end
