//
//  BEDownloaderTaskModel.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEDownloaderTaskModel.h"
#import <AVFoundation/AVFoundation.h>
#import "../Cache/BECache.h"
#import "../BEResourceLoaderConstants.h"

@interface BEDownloaderTaskModel ()

@property(nonatomic, strong) NSMutableArray* groupNames;

@end

@implementation BEDownloaderTaskModel
@synthesize groupName = _groupName;


- (void)dealloc {
    
    _handlerSet = nil;
    
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _taskDesc = [BEDownloaderTaskDesc new];
        
        _url = @"";
        
        _key = @"";
        
        _expectedPercent = 1.0;
        
        _status = 1;
        
        _loadedLength = 0;
        
        _totalLength = 0;
        
        _groupNames = [NSMutableArray new];
        
        _handlerSet = [BEDownloaderTaskHandlerSet new];
    }
    return self;
}

#pragma mark - SET/GET

- (void)setKey:(NSString *)key {
    
    _key = [key copy];
    
    NSDictionary* info = [[BECache share] contentInfo:self.key];
    
    if (info.count > 0) {
        
        self.groupName = info[@"group"];
    }
}

- (void)setStatus:(BEDownloaderTaskStatus)status {
    
    if (_status == status) { return; }
    
    _status = status;
    
    if (self.taskStatusBlock) {

        self.taskStatusBlock(self.key, self.url, status);
    }
}

- (NSString *)groupName {
    
    return _groupName;
}

- (void)setGroupName:(NSString *)groupName {
    
    NSInteger groupCount = self.groupNames.count;
    
    NSDictionary* info = [[BECache share] contentInfo:self.key];
    
    if (groupCount == 0) {
        
        NSArray* origin = [info[@"group"] componentsSeparatedByString:@","];
        
        if (origin.count) {
            
            [self.groupNames addObjectsFromArray:origin];
            
            groupCount = self.groupNames.count;
        }
    }
    
    BOOL duplicate = NO, newGroup = NO;
    
    if (!groupName || groupName.length == 0) {
        
        [self.groupNames removeAllObjects];
    }else{
        
        NSArray* groups = [groupName componentsSeparatedByString:@","];
        
        [self.groupNames removeObjectsInArray:groups];
        
        if (self.groupNames.count < groupCount) {
            
            duplicate = YES;
        }
        
        [self.groupNames addObjectsFromArray:groups];
        
        if (self.groupNames.count > groupCount) {
            
            newGroup = YES;
        }
    }
    NSString* gn = [self.groupNames componentsJoinedByString:@","];
    
    _groupName = gn.length > 0 ? gn : nil;
    
    if (info.count > 0 && (newGroup || !_groupName)) {
        
        NSMutableDictionary* nInfo = [NSMutableDictionary dictionaryWithDictionary:info];
        
        nInfo[@"group"] = _groupName;
        
        [[BECache share] updateContentInfo:[nInfo copy] identifier:self.key onComplete:^(NSData * _Nullable data, NSString * _Nullable identifier, BEMCFlagType flag) {}];
    }
}

- (void)setExpectedPercent:(double)expectedPercent {
    
    if (expectedPercent > 0.0 && expectedPercent < 1.0) {
        
        _expectedPercent = expectedPercent;
    }else{
        
        _expectedPercent = 1.0;
    }
}

- (void)setTaskStatusBlock:(void (^)(NSString *, NSString *, BEDownloaderTaskStatus))taskStatusBlock {
    
    if (taskStatusBlock) {

        [self.handlerSet.statusHandlers addObject:taskStatusBlock];
        
        if (!_taskStatusBlock) {
            
            __weak typeof(self) ws = self;
            
            _taskStatusBlock = ^(NSString* a, NSString* b, BEDownloaderTaskStatus status){
                
                for (id obj in ws.handlerSet.statusHandlers) {
                    
                    void (^block)(NSString* ,NSString* ,BEDownloaderTaskStatus status) = (void (^)(NSString* ,NSString* ,BEDownloaderTaskStatus status))obj;
                    
                    block(a,b,status);
                }
            };
        }
    }
}

- (void)setProgressBlock:(void (^)(NSString *, NSString *, uint64_t, uint64_t))progressBlock {
    
    if (progressBlock) {

        [self.handlerSet.progressHandlers addObject:progressBlock];
        
        if (!_progressBlock) {
            
            __weak typeof(self) ws = self;
            
            _progressBlock = ^(NSString* a,NSString* b,uint64_t c, uint64_t d){
                
                for (id obj in ws.handlerSet.progressHandlers) {
                    
                    void (^block)(NSString* a,NSString* b,uint64_t c, uint64_t d) = (void (^)(NSString* a,NSString* b,uint64_t c, uint64_t d))obj;
                    
                    block(a,b,c,d);
                }
            };
        }
    }
}

- (void)setFinishedBlock:(void (^)(NSString *, NSString *, NSString *, NSDictionary* , NSError *))finishedBlock {
    
    if (finishedBlock) {

        [self.handlerSet.finishHandlers addObject:finishedBlock];
        
        if (!_finishedBlock) {
            
            __weak typeof(self) ws = self;
            
            _finishedBlock = ^(NSString *a, NSString *b, NSString *c, NSDictionary* metric, NSError *e){
                
                while (ws.handlerSet.finishHandlers.firstObject) {
                    
                    void (^block)(NSString *, NSString *, NSString *, NSDictionary*, NSError *) = (void (^)(NSString *, NSString *, NSString *, NSDictionary *, NSError *))ws.handlerSet.finishHandlers.firstObject;
                    
                    block(a,b,c,metric,e);
                    
                    [ws.handlerSet.finishHandlers removeObject:block];
                }
                [ws.handlerSet.progressHandlers removeAllObjects];
                
                [ws.handlerSet.statusHandlers removeAllObjects];
            };
        }
    }
}

@end


@interface BEDownloaderTaskDesc ()
{
    CFTimeInterval lastTs;
}
@end

@implementation BEDownloaderTaskDesc


- (void)dealloc {
    
//    printf("%s\n", __func__);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        lastTs = CACurrentMediaTime();
        
        _taskNetSpeed = 0;
    }
    return self;
}

#pragma mark - GET/SET

- (NSMutableArray *)networkMetrics {
    
    if (!_networkMetrics) {
        
        _networkMetrics = [NSMutableArray new];
    }
    return _networkMetrics;
}

- (NSDictionary *)metric {
    
    NSMutableDictionary* tmp = [[NSMutableDictionary alloc] initWithDictionary:self.networkMetrics.lastObject];
    
    if (self.networkMetrics.count > 1) {
        
        NSDictionary* firstObject = self.networkMetrics.firstObject;
        
        [tmp setValue:firstObject[@"connect"] forKey:@"connect"];
        
        [tmp setValue:firstObject[@"lookup"] forKey:@"lookup"];
        
        [tmp setValue:firstObject[@"reused"] forKey:@"reused"];
        
        [tmp setValue:firstObject[@"secure_connect"] forKey:@"secure_connect"];
        
        //ts|lookup|secure_connect|connect|req|resp|duration|length|code|proxy|reused|redirect|cellular|constrained|expensive|multipath|protocol|dns_protocol|tls_suite|tls_version|fetch_type|local_addr|remote_addr
        NSString* desc = [NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@",
                          tmp[@"ts"],
                          tmp[@"lookup"],
                          tmp[@"secure_connect"],
                          tmp[@"connect"],
                          tmp[@"req"],
                          tmp[@"resp"],
                          tmp[@"duration"],
                          tmp[@"length"],
                          tmp[@"code"],
                          tmp[@"proxy"],
                          tmp[@"reused"],
                          tmp[@"redirect"],
                          tmp[@"cellular"],
                          tmp[@"constrained"],
                          tmp[@"expensive"],
                          tmp[@"multipath"],
                          tmp[@"protocol"],
                          tmp[@"dns_protocol"],
                          tmp[@"tls_suite"],
                          tmp[@"tls_version"],
                          tmp[@"fetch_type"],
                          tmp[@"local_addr"],
                          tmp[@"remote_addr"]];
        desc = [desc stringByReplacingOccurrencesOfString:@"(null)" withString:@"-"];
        
        [tmp setValue:desc forKey:@"_description"];
    }
    
    _metric = [tmp copy];
    
    return _metric;
}

- (void)newDataLength:(uint64_t)len {
    
    CFTimeInterval ts = CACurrentMediaTime();
    
    CFTimeInterval tv = ts - lastTs;
    
    lastTs = ts;
    
    double bps = len/tv;
    
    self.taskNetSpeed = bps;
}

@end




@implementation BEDownloaderTaskHandlerSet

- (void)dealloc {
    
    [_statusHandlers removeAllObjects];
    
    _statusHandlers = nil;
    
    [_progressHandlers removeAllObjects];
    
    _progressHandlers = nil;
    
    [_finishHandlers removeAllObjects];
    
    _finishHandlers = nil;
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _statusHandlers = [[NSMutableArray alloc] initWithCapacity:1];
        
        _progressHandlers = [[NSMutableArray alloc] initWithCapacity:1];
        
        _finishHandlers = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}

@end
