//
//  BEDownloaderGroupModel.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEDownloaderGroupModel.h"
#import "BEDownloaderTaskModel.h"
#import "../BEResourceLoaderConstants.h"
#import "../BETool.h"

@interface BEDownloaderGroupModel ()

@property(nonatomic, strong) dispatch_source_t timer;

@property(nonatomic, strong) NSMutableArray* loadedTask;

@property(nonatomic, strong) NSMutableArray* failedTask;

@property(nonatomic, strong) BEDownloaderGroupHandlerSet* handlerSet;

@end

@implementation BEDownloaderGroupModel

- (void)dealloc {
    
    [_allTask removeAllObjects];
    
    _allTask = nil;

    [_loadedTask removeAllObjects];
    
    _loadedTask = nil;

    [_failedTask removeAllObjects];
    
    _failedTask = nil;
    
    _groupComplete = nil;
    
    _groupSpeedBlock = nil;
    
    _groupProgressBlock = nil;
    
//    printf("%s %s\n", __func__, _groupName.UTF8String);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _allTask = [[NSMutableDictionary alloc] initWithCapacity:1];
        
        _loadedTask = [NSMutableArray new];
        
        _failedTask = [NSMutableArray new];
        
        _groupName = DEFAULT_GROUP;
        
        _handlerSet = [BEDownloaderGroupHandlerSet new];
    }
    return self;
}
#pragma mark - GET/SET

- (NSInteger)caculateGroupSpeed {
    
    NSInteger cnt = 0;
    
    NSInteger totalSpeed = 0;
    
    NSDictionary* task = [self.allTask copy];
    
    for (NSString* key in task) {
        
        BEDownloaderTaskModel* obj = task[key];
        
        if (obj.status == BEDownloaderTaskStatusRunning) {
            
            totalSpeed += obj.taskDesc.taskNetSpeed;
            
            obj.taskDesc.taskNetSpeed = 0;
            
            cnt++;
        }
    }
    return cnt > 0 ? totalSpeed / cnt : 0;
}

- (void)destroy {
    
    if (_timer) {
        
        dispatch_cancel(_timer);
        
        _timer = NULL;
    }
    
    [_allTask removeAllObjects];

    _allTask = nil;
    
    _groupComplete = NULL;
    
    _groupProgressBlock = NULL;
    
    _groupSpeedBlock = NULL;
    
    _handlerSet = nil;
    
    _refUrls = nil;
}

- (void)task:(BEDownloaderTaskModel *)taskModel status:(BEDownloaderTaskStatus)status {
    
//    if ([@[@(BEDownloaderTaskStatusFinished), @(BEDownloaderTaskStatusCancelled)] containsObject:@(status)]) {
//
//        [self checkGroup:taskModel];
//    }
}

- (void)setGroupProgressBlock:(void (^)(NSString *, NSInteger, NSInteger, NSInteger, uint64_t, uint64_t, NSDictionary*))groupProgressBlock {
    
    if (groupProgressBlock) {
        
        [self.handlerSet.groupProgressHandlers addObject:groupProgressBlock];

        if (!_groupProgressBlock) {
            
            __weak typeof(self) weakSelf = self;
            
            _groupProgressBlock = ^(NSString *group, NSInteger loadedCnt, NSInteger failedCnt, NSInteger totalCnt, uint64_t loadeBytes, uint64_t totalBytes, NSDictionary* loadedTask) {
                
                for (id obj in weakSelf.handlerSet.groupProgressHandlers) {
                    
                    void (^block)(NSString *, NSInteger, NSInteger, NSInteger, uint64_t, uint64_t, NSDictionary *) = (void (^)(NSString *group, NSInteger loadedCnt, NSInteger failedCnt, NSInteger totalCnt, uint64_t loadeBytes, uint64_t totalBytes, NSDictionary*))obj;
                    
                    block(group, loadedCnt, failedCnt, totalCnt, loadeBytes, totalBytes, loadedTask);
                }
            };
        }
    }
}

- (void)setGroupSpeedBlock:(void (^)(NSInteger))groupSpeedBlock {
    
    if (groupSpeedBlock) {

        [self.handlerSet.groupSpeedHandlers addObject:groupSpeedBlock];
        
//        if (self.handlerSet.groupSpeedHandlers.count > 0) {
//            
//            [self startSpeedTimer];
//        }
        
        if (!_groupSpeedBlock) {
            
            __weak typeof(self) weakSelf = self;
            
            _groupSpeedBlock = ^(NSInteger v) {
                
                for (id obj in weakSelf.handlerSet.groupSpeedHandlers) {
                    
                    void (^block)(NSInteger ) = (void (^)(NSInteger))obj;
                    
                    block(v);
                }
            };
        }
    }
}

- (void)setGroupComplete:(void (^)(NSDictionary *, NSDictionary* ))groupComplete {
    
    if (groupComplete) {
        
        [self.handlerSet.groupCompleteHandlers addObject:groupComplete];
        
        if (!_groupComplete) {
            
            __weak typeof(self) ws = self;
            
            _groupComplete = ^(NSDictionary *result, NSDictionary* metrics) {
                
                for (id obj in ws.handlerSet.groupCompleteHandlers) {
                    
                    void (^block)(NSDictionary *, NSDictionary* ) = (void (^)(NSDictionary *, NSDictionary* ))obj;
                    
                    block(result, metrics);
                }
                if (ws.handlerSet.groupProgressHandlers) {
                    
                    [ws.handlerSet.groupProgressHandlers removeAllObjects];
                }
                
                if (ws.handlerSet.groupSpeedHandlers) {
                    
                    [ws.handlerSet.groupSpeedHandlers removeAllObjects];
                }
                
                if (ws.handlerSet.groupCompleteHandlers) {
                    
                    [ws.handlerSet.groupCompleteHandlers removeAllObjects];
                }
            };
        }
    }
}

//检测是否全部完成
- (BOOL )checkGroup:(BEDownloaderTaskModel *)taskModel {
    
    NSDictionary* respData = nil;
    
    if (taskModel.error) {
        
        respData = @{@"url":taskModel.url, @"identifier":taskModel.identifier ?:@"", @"error":@{@"code":@(taskModel.error.code), @"msg":taskModel.error.localizedDescription}};
        
        [self.failedTask addObject:respData];
    }else{
        
        respData = @{@"url":taskModel.url, @"identifier":taskModel.identifier ?:@"", @"filePath":taskModel.localPath, @"totalSize":@(taskModel.totalLength)};
        
        [self.loadedTask addObject:respData];
    }
    
    if (self.groupProgressBlock) {
        
        NSMutableDictionary *resp = [NSMutableDictionary dictionaryWithDictionary:respData];
        
        [resp setValue:taskModel.taskDesc.metric forKey:@"metric"];
        
        self.groupProgressBlock(self.groupName, self.loadedTask.count, self.failedTask.count, self.refUrls.count, 0, 0, [resp copy]);
    }
    
    if (self.loadedTask.count + self.failedTask.count == self.refUrls.count) {
        
        if (self.groupComplete) {
            
            NSMutableDictionary* metrics = [NSMutableDictionary new];
            
            NSMutableArray* tmp = [[NSMutableArray alloc] initWithArray:self.refUrls copyItems:YES];
            
            NSMutableDictionary* orderMap = [NSMutableDictionary new];
            
            for (int i = 0; i < self.refUrls.count; i++) {
                orderMap[self.refUrls[i]] = @(i);
            }
            
            for (NSString* key in self.allTask) {
                
                BEDownloaderTaskModel* obj = self.allTask[key];
                
                if (orderMap[obj.url]) {
                    
                    NSInteger idx = [orderMap[obj.url] integerValue];
                    
                    //返回数据
                    if (obj.error) {
                        
                        [tmp replaceObjectAtIndex:idx withObject:@{@"url":obj.url, @"identifier":obj.identifier ?:@"", @"error":@{@"code":@(obj.error.code), @"msg":obj.error.localizedDescription}}];
                    }else{
                        
                        [tmp replaceObjectAtIndex:idx withObject:@{@"url":obj.url, @"identifier":obj.identifier ?:@"", @"filePath":obj.localPath, @"totalSize":@(obj.totalLength)}];
                    }
                    
                    //网络指标数据
                    if (!metrics[obj.url]) {
                        
                        [metrics setValue:@{@"metric":obj.taskDesc.metric, @"metricDetail":obj.taskDesc.networkMetrics} forKey:obj.url];
                    }
                }
            }
            self.groupComplete(@{@"loaded":[self.loadedTask copy], @"failed": [self.failedTask copy], @"all":[tmp copy]}, [metrics copy]);
        }
        
        [self destroy];
        
        return YES;
    }else{
        return NO;
    }
}

- (void)startSpeedTimer {
    
    BOOL needCaculateSpeed = self.handlerSet.groupSpeedHandlers.count > 0;
    
    if (needCaculateSpeed && !_timer) {
        
        dispatch_queue_t serialQueue = SerialQueue();
        
        __weak typeof(self) weakSelf = self;
        
        //速度定时器
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, serialQueue);
        
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, NSEC_PER_SEC * 0);
        
        dispatch_source_set_event_handler(timer, ^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (!strongSelf) {
                return ;
            }
            
            if (weakSelf.groupSpeedBlock) {
                
                NSInteger s = [weakSelf caculateGroupSpeed];
                
                weakSelf.groupSpeedBlock(s);
            }
        });
        
        dispatch_resume(timer);
        
        self.timer = timer;
    }
}

@end


@implementation BEDownloaderGroupHandlerSet

- (instancetype)init {
    
    if (self = [super init]) {
        
        _groupProgressHandlers = [NSMutableArray new];
        
        _groupSpeedHandlers = [NSMutableArray new];
        
        _groupCompleteHandlers = [NSMutableArray new];
    }
    return self;
}

@end
