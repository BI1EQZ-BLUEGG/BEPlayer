//
//  BEDownloader.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/3.
//

#import "BEDownloader.h"
#import "../BEResourceLoaderConstants.h"
#import "../BETool.h"
#import "BEDownloaderGroupModel.h"
#import "BEDownloaderTask.h"

@interface BEDownloader () {
    
    NSInteger _concurrentTaskNumber;
}

@property(nonatomic, strong)NSMutableDictionary<NSString *, BEDownloaderGroupModel *> *groupManager;

@property(nonatomic, strong)NSMutableDictionary<NSString *, BEDownloaderTask *> *tasks;

@property(nonatomic, strong) NSMutableArray<NSString *> *taskIndexs;

@end

@implementation BEDownloader

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"BECache_clean_cache"
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"BECache_cleanAll"
                                                  object:nil];

    printf("%s\n", __func__);
}

- (instancetype)init {

    if (self = [super init]) {

        _concurrentTaskNumber =
            MAX(2, [NSProcessInfo processInfo].processorCount / 2);

        _tasks = [NSMutableDictionary new];

        _taskIndexs = [NSMutableArray new];

        _groupManager = [[NSMutableDictionary alloc] initWithCapacity:2];

        [[NSNotificationCenter defaultCenter]
            addObserver:self selector:@selector(cancelAndCleanCache:) name:@"BECache_clean_cache" object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAndCleanCache:) name:@"BECache_cleanAll" object:nil];
    }
    return self;
}

#pragma mark - Public

/// 添加单个任务，使用自定义标识
- (void)addTask:(NSString *)url
     identifier:(NSString *)identifier
       expected:(float)expectedPercent
          group:(NSString *)groupName
   onTaskStatus:(void (^)(NSString *url, NSInteger status))onTaskStatusChange
     onProgress:(void (^)(NSString *url, uint64_t loadedBytes, uint64_t totalBytes))onProcess
     onComplete:(void (^)(NSString *url, NSString *path, NSDictionary *metric, NSError *error))onComplete {

    __weak typeof(self) ws = self;

    dispatch_async(SerialQueue(), ^{
      [ws internalAddTask:url
               identifier:identifier
                 expected:expectedPercent
                    group:groupName
             onTaskStatus:onTaskStatusChange
               onProgress:onProcess
               onComplete:onComplete];

      [ws tryNextTask];
    });
}

- (void)addGroup:(NSString *)group
           tasks:(NSArray<NSString *> *)urls
     identifiers:(NSArray<NSString *> *)identifiers
        expected:(double)expectedPercent
 onGroupProgress:(void (^)(NSString *, NSInteger, NSInteger, NSInteger, uint64_t, uint64_t, NSDictionary *))onGroupProgress
         onSpeed:(void (^)(NSInteger))onGroupSpeed
      onComplete:(void (^)(NSDictionary *, NSDictionary *))onGroupComplete {

    __weak typeof(self) ws = self;

    dispatch_async(SerialQueue(), ^{
        
      [ws onGroup:group tasks:urls onGroupProgress:onGroupProgress onSpeed:onGroupSpeed onComplete:onGroupComplete];

      BOOL isIdentifierValid = urls.count == identifiers.count;

      for (int i = 0; i < urls.count; i++) {

          NSString *url = urls[i];

          NSString *identifier = @"";

          if (isIdentifierValid) {

              identifier = identifiers[i];
          }
          
          [self addTask:url identifier:identifier expected:expectedPercent group:group onTaskStatus:nil onProgress:nil onComplete:nil];
      }
    });
}

- (void)removeTask:(NSString *)url {

    [self removeTask:url onComplete:nil];
}

- (void)removeTask:(NSString *)url onComplete:(void (^)(void))onComplete {

    if ([url isKindOfClass:[NSString class]] && url.length > 0) {

        [self removeTasks:@[ url ] groups:nil onComplete:onComplete];
    } else {

        if (onComplete) {

            onComplete();
        }
    }
}

- (void)removeTasks:(NSArray *)urls
             groups:(NSArray *)groups
         onComplete:(void (^)(void))onCompleteBlock {
    [self removeTasks:urls
          identifiers:nil
               groups:groups
           onComplete:onCompleteBlock];
}

- (void)removeTasks:(NSArray *)urls
        identifiers:(NSArray *)identifiers
             groups:(NSArray *)groups
         onComplete:(void (^)(void))onCompleteBlock {

    __weak typeof(self) ws = self;

    dispatch_async(SerialQueue(), ^{
      [ws internalRemoveTasks:urls
                  identifiers:identifiers
                     orGroups:groups
                   onComplete:onCompleteBlock];
    });
}

- (void)advance:(NSString *)url {

    __weak typeof(self) ws = self;

    dispatch_async(SerialQueue(), ^{
      [ws internalAdvance:url];
    });
}

#pragma mark - Internal

- (BOOL)internalAddTask:(NSString *)url
             identifier:(NSString *)identifier
               expected:(float)expectedPercent
                  group:(NSString *)groupName
           onTaskStatus:(void (^)(NSString *, NSInteger))onTaskStatusChange
             onProgress:(void (^)(NSString *, uint64_t, uint64_t))onProcess
             onComplete:(void (^)(NSString *, NSString *, NSDictionary *,
                                  NSError *))onComplete {

    if (!([url isKindOfClass:[NSString class]] && url.length > 0)) {
        return NO;
    }

    groupName = groupName.length > 0 ? groupName : DEFAULT_GROUP;

    __weak typeof(self) ws = self;

    BOOL isValidIdentifier =
        [identifier isKindOfClass:[NSString class]] && identifier.length > 0;

    NSString *key = [BETool md5:isValidIdentifier ? identifier : url];

    // 🐣Task
    BEDownloaderTask *task = self.tasks[key];

    if (!task) {

        task = [BEDownloaderTask new];

        task.model.url = url;

        task.model.key = key;

        task.model.identifier = identifier;

        task.model.status = BEDownloaderTaskStatusPending;

        self.tasks[key] = task;
    }
    __weak typeof(task) wt = task;

    task.model.expectedPercent = expectedPercent;

    if ([groupName isKindOfClass:[NSString class]] && groupName.length) {

        task.model.groupName = groupName;
    }

    // 🙉Group
    BEDownloaderGroupModel *group = self.groupManager[groupName];

    __weak BEDownloaderGroupModel *wg = group;

    if (!group) {

        group = [BEDownloaderGroupModel new];

        wg = group;

        self.groupManager[groupName] = group;

        group.groupComplete =　^(NSDictionary *_Nonnull result, NSDictionary *_Nullable metrics) {
            [ws.groupManager removeObjectForKey:wg.groupName];
        };
    }

    if (!group.allTask[key]) {

        group.allTask[key] = task.model;
    }

    if (![self.taskIndexs containsObject:key]) {

        [self.taskIndexs addObject:key];
    }

    // Config Task
    task.model.taskStatusBlock = ^(NSString *key, NSString *url, BEDownloaderTaskStatus status) {
        
          if (onTaskStatusChange) {

              onTaskStatusChange(url, status);
          }

          [wg task:wt.model status:status];
        };

    task.model.progressBlock =　^(NSString * key, NSString * url, uint64_t loaded, uint64_t total) {
        
        if (onProcess) {

            onProcess(url, loaded, total);
        }
    };

    task.model.finishedBlock =　^(NSString * key, NSString * url, NSString * localPath, NSDictionary * metric, NSError * error) {
        if (onComplete) {

            onComplete(url, localPath, metric, error);
        }

        BEDownloaderTaskModel *taskModel = wg.allTask[key];

        [wg checkGroup:taskModel];

        [ws.taskIndexs removeObject:key];

        [ws.tasks removeObjectForKey:key];

        [ws tryNextTask];
    };
    return YES;
}

- (void)internalRemoveTasks:(NSArray *)urls
                identifiers:(NSArray *)identifiers
                   orGroups:(NSArray *)groups
                 onComplete:(void (^)(void))onCompleteBlock {

    NSDictionary *tasks = [self.tasks copy];

    if ((groups && ![groups isKindOfClass:[NSArray class]]) ||
        ((urls && ![urls isKindOfClass:[NSArray class]]) &&
         (identifiers && ![identifiers isKindOfClass:[NSArray class]])) ||
        tasks.count == 0) {

        if (onCompleteBlock) {

            onCompleteBlock();
        }
        return;
    }

    dispatch_group_t gcd_group = dispatch_group_create();

    BOOL rmAll = !urls && !identifiers && !groups;

    if (!rmAll) {

        if (groups.count > 0) {

            for (NSString *key in tasks) {

                BEDownloaderTask *obj = tasks[key];

                if (obj) {

                    NSMutableSet *toRm = [NSMutableSet setWithArray:groups];

                    NSMutableSet *cGrp = [NSMutableSet
                        setWithArray:[obj.model.groupName
                                         componentsSeparatedByString:@","]];

                    [cGrp minusSet:toRm];

                    obj.model.groupName = nil;

                    obj.model.groupName =
                        [cGrp.allObjects componentsJoinedByString:@","];

                    if (cGrp.count == 0 ||
                        [urls containsObject:obj.model.url] ||
                        [identifiers containsObject:obj.model.identifier]) {

                        dispatch_group_enter(gcd_group);

                        obj.model.finishedBlock =
                            ^(NSString *_Nonnull key, NSString *_Nonnull url,
                              NSString *_Nonnull localPath,
                              NSDictionary *metric, NSError *_Nonnull error) {
                              dispatch_group_leave(gcd_group);
                            };
                        [obj cancel];
                    }
                }
            }
        } else {

            BOOL isIdentifiersValid =
                [identifiers isKindOfClass:[NSArray class]] &&
                identifiers.count > 0;

            for (NSString *v in (isIdentifiersValid ? identifiers : urls)) {

                NSString *key = [BETool md5:　v];

                BEDownloaderTask *task = tasks[key];

                if (task) {

                    dispatch_group_enter(gcd_group);

                    [self internalCancelTask:task
                                  onCanceled:^{
                                    dispatch_group_enter(gcd_group);
                                  }];
                }
            }
        }
    } else {

        for (NSString *key in tasks) {

            BEDownloaderTask *task = tasks[key];

            if (task) {

                dispatch_group_enter(gcd_group);

                [self internalCancelTask:tasks[key]
                              onCanceled:^{
                                dispatch_group_leave(gcd_group);
                              }];
            }
        }
    }

    dispatch_group_notify(gcd_group, SerialQueue(), ^{
        
      if (onCompleteBlock) {

          onCompleteBlock();
      }
    });
}

- (void)internalCancelTask:(BEDownloaderTask *)task onCanceled:(void (^)(void))onCanceled {

    if (task) {
        task.model.finishedBlock = ^(NSString *_Nonnull key, NSString *_Nonnull url, NSString *_Nonnull localPath, NSDictionary *metric, NSError *_Nonnull error) {
            if (onCanceled) {
                onCanceled();
            }
        };
        [task cancel];
    } else {
        
        if (onCanceled) {

            onCanceled();
        }
    }
}

- (void)internalAdvance:(NSString *)url {

    [self internalAdvance:url identifier:nil];
}

- (void)internalAdvance:(NSString *)url identifier:(NSString *)identifier {

    if (!([url isKindOfClass:[NSString class]] && url.length > 0) && ![identifier isKindOfClass:[NSString class]] && identifier.length > 0) {
        return;
    }

    NSString *key = [BETool md5:identifier.length > 0 ? identifier : url];

    BEDownloaderTask *task = self.tasks[key];

    if (!task) {

        [self internalAddTask:url
                   identifier:identifier
                     expected:1.0
                        group:nil
                 onTaskStatus:nil
                   onProgress:nil
                   onComplete:nil];
    }
    [self.taskIndexs removeObject:key];

    [self.taskIndexs insertObject:key atIndex:0];
}

- (BEDownloaderGroupModel *)onGroup:(NSString *)group
                              tasks:(NSArray<NSString *> *)urls
                    onGroupProgress:(void (^)(NSString *, NSInteger, NSInteger, NSInteger, uint64_t, uint64_t, NSDictionary *))onGroupProgress
                            onSpeed:(void (^)(NSInteger))onSpeed
                         onComplete:(void (^)(NSDictionary *, NSDictionary *))onComplete {

    group = ([group isKindOfClass:[NSString class]] && group.length > 0) ? group : DEFAULT_GROUP;

    BEDownloaderGroupModel *obj = self.groupManager[group];

    if (!obj) {

        obj = [BEDownloaderGroupModel new];

        self.groupManager[group] = obj;
    }

    NSString *identifier = [NSString stringWithFormat:@"%@_%@", group, @([[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000)];

    obj.callIdentifier = identifier;

    obj.groupName = group;

    obj.groupProgressBlock = onGroupProgress;

    obj.groupSpeedBlock = onSpeed;

    __weak typeof(self) ws = self;

    obj.groupComplete = ^(NSDictionary *result, NSDictionary *metrics) {
        
        if (onComplete) {
            
            onComplete(result, metrics);
        }
        [ws.groupManager removeObjectForKey:group];
    };

    // 整理数据
    if ([urls isKindOfClass:[NSArray class]] && urls.count > 0) {

        if ([obj.refUrls isKindOfClass:[NSArray class]] && obj.refUrls.count > 0) {

            NSMutableArray *tmp = [obj.refUrls mutableCopy];

            [tmp addObjectsFromArray:urls];

            obj.refUrls = [tmp copy];
        } else {

            obj.refUrls = [urls copy];
        }
    }
    return obj;
}

- (void)tryNextTask {

    NSArray *tmp = [self.taskIndexs copy];

    NSUInteger cnt = tmp.count;

    if (cnt > 0) {

        NSInteger pendingStart =
            cnt > _concurrentTaskNumber ? _concurrentTaskNumber : cnt;

        for (int i = 0; i < pendingStart; i++) {

            NSString *key = tmp[i];

            BEDownloaderTask *task = self.tasks[key];

            if (task.model.status == BEDownloaderTaskStatusCancelled) {

                continue;
            } else {

                dispatch_async(SerialQueue(), ^{
                  [task start];
                });
            }
        }
    }
}

#pragma mark - Notify(BECache_clean_cache,BECache_cleanAll)

- (void)cancelAndCleanCache:(NSNotification *)notify {

    void (^onCanceled)(void) =
        (void (^)(void))notify.object[@"onCanceled"] ?: ^{
        };

    __weak typeof(self) ws = self;

    NSDictionary *tasks = [self.tasks copy];

    dispatch_async(SerialQueue(), ^{
      if ([notify.name isEqualToString:@"BECache_clean_cache"]) {

          // 一堆任务
          NSArray *keys = notify.object[@"identifiers"];

          if (keys.count > 0) {

              for (NSString *key in keys) {

                  BEDownloaderTask *task = tasks[key];

                  [self
                      internalCancelTask:task
                              onCanceled:^{

                                  //                        printf("canceled: %s
                                  //                        %s\n",task.model.key.UTF8String,
                                  //                        task.model.url.UTF8String);
                              }];
              }
          }

          // 多个组
          NSArray *groups = notify.object[@"groups"];

          if (groups.count > 0) {

              [self internalRemoveTasks:nil
                            identifiers:nil
                               orGroups:groups
                             onComplete:^{
                               printf("abc\n");
                             }];
          }

          // 单独任务
          NSString *key = notify.object[@"identifier"];

          if (key) {

              [ws internalCancelTask:tasks[key]
                          onCanceled:^{
                            onCanceled();
                          }];
          }

      } else if ([notify.name isEqualToString:@"BECache_cleanAll"]) {

          [ws internalRemoveTasks:nil
                      identifiers:nil
                         orGroups:nil
                       onComplete:^{
                         onCanceled();
                       }];
      } else {

          onCanceled();
      }
    });
}
@end
