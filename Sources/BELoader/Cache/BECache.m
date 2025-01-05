//
//  BECache.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import <UIKit/UIKit.h>
#import "BECache.h"
#import "../BETool.h"
#import "BECacheItem.h"

@interface BECache ()

@property(nonatomic, strong) NSFileManager* fileMgr;

@property(nonatomic, strong) NSMutableDictionary<NSString *, BECacheItem *>* buffer;

@end

@implementation BECache

+ (instancetype)share {
    
    static BECache* instance;
    
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        
        instance = [BECache new];
    });
    
    return instance;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
//    printf("%s\n", __func__);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _fileMgr = [NSFileManager new];
        
        _buffer = [[NSMutableDictionary alloc] initWithCapacity:5];
        
        _limitCacheSize = 1073741824;//1G
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

#pragma mark - File
//拼路径，入空返回workPath,否则返回具体路径
- (NSString *)pathForIdentifier:(NSString *)identifier {
    
    static NSString* workPath = NULL;
    
    if (!workPath) {
        
        workPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:MediaCacheWorkRootPath];
        
        printf("\nopen %s\n\n", workPath.UTF8String);
        
        //清理旧版本文件
        NSArray* items = [[self fileMgr] contentsOfDirectoryAtPath:workPath error:nil];
        
        for (NSString* item in items) {
            
            if (![item isEqualToString:BE_Resource_Loader_Version]) {
                
                [[self fileMgr] removeItemAtPath:[workPath stringByAppendingPathComponent:item] error:nil];
            }
        }
        
        workPath = [workPath stringByAppendingPathComponent:BE_Resource_Loader_Version];
    }
    
    if ([identifier isKindOfClass:[NSString class]] && identifier.length > 0) {
        
        return  [workPath stringByAppendingPathComponent:identifier];
    }
    return workPath;
}

#pragma mark - Public Data R/W

///MARK:查询数据
- (void)queryCacheRanges:(NSString *)key onComplete:(void (^)(uint64_t, NSArray * _Nonnull, NSArray * _Nonnull, NSDictionary* info))completeHandler {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        BECacheItem* item = [ws itemForIdentifier:key];
        
        BECacheItemFragment* fragment = [BECacheItemFragment new];
        
        fragment.action = BECacheActionReadRanges;
        
        fragment.identifier = key;
        
        fragment.queryRangeHandler = completeHandler;
        
        [item addFragment:fragment];
    });
}

///MARK:正文数据
- (void)dataForRange:(NSRange)range identifier:(NSString *)identifier onReadNewData:(void (^)(NSData * _Nonnull))readDataHandler onComplete:(BECacheHandler)handler {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        [ws internalDataForRange:range identifier:identifier onReadNewData:readDataHandler onComplete:handler];
    });
}

- (void)updateData:(NSData *)data range:(NSRange)range identifier:(NSString *)identifier totalLenght:(uint64_t)totalLenght onComplete:(nullable BECacheHandler)handler {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        [ws internalUpdateData:data range:range identifier:identifier totalLenght:totalLenght info:nil onComplete:handler];
    });
}

///MARK: 摘要信息
- (void )updateContentInfo:(NSDictionary * _Nullable)info identifier:(NSString *)identifier onComplete:(BECacheHandler )handler {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        [ws internalUpdateData:nil range:NSMakeRange(0, 0) identifier:identifier totalLenght:0 info:info onComplete:handler];
    });
    
}

- (NSDictionary *)contentInfo:(NSString *)identifier {
    
    BECacheItem* item = [self itemForIdentifier:identifier];
    
    return item.info;
}

///MARK:Data Clean
+ (uint64_t)cacheSize {
    
    NSString* path = [self pathForKey:nil extension:nil];
    
    BOOL isDir = YES;
    
    NSFileManager* manager = [BECache fileMgr];
    
    if ([manager fileExistsAtPath:path isDirectory:&isDir]) {
        
        __block uint64_t size = 0;
        
        NSArray* files = [manager contentsOfDirectoryAtPath:path error:nil];
        
        [files enumerateObjectsUsingBlock:^(NSString*  _Nonnull subPath, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (![subPath hasPrefix:@"."]) {
                
                size += [[manager attributesOfItemAtPath:[path stringByAppendingPathComponent:subPath] error:nil] fileSize];
            }
        }];
        
        return size;
    }
    return 0;
}

+ (void )cleanAll {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self cleanCacheFiles:nil orGroups:nil onComplete:^{
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 200*NSEC_PER_MSEC));
}

+ (void )cleanAll:(void(^)(void))onComplete {
    
    [self cleanCacheFiles:nil orGroups:nil onComplete:onComplete];
}

+ (void)cleanCacheFiles:(NSArray *)files orGroups:(NSArray *)groups {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self cleanCacheFiles:files orGroups:groups onComplete:^{
        
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 200*NSEC_PER_MSEC));
}

+ (void)cleanCacheFiles:(NSArray * _Nullable )files orGroups:(NSArray * _Nullable )groups onComplete:(void (^)(void))onComplete{
    
    __weak typeof(self) ws = self;

    dispatch_async(SerialQueue(), ^{

        [ws _internalCleanCacheFiles:files orGroups:groups onComplete:onComplete];
    });
}


#pragma mark - Internal

+ (void)_internalCleanCacheFiles:(NSArray *)files orGroups:(NSArray *)groups onComplete:(void (^)(void))onComplete {
    
    NSMutableDictionary* fileAndGroups = [[NSMutableDictionary alloc] init];

    NSMutableDictionary* toRmFileKeyMap = [[NSMutableDictionary alloc] initWithCapacity:files.count];
    
    if ([files isKindOfClass:[NSArray class]] && files.count) {
        
        for (NSString *obj in files) {
            
            NSString* identifier = [BETool md5:obj];
            
            NSString* fileName = [identifier stringByAppendingPathExtension:@"idx"];
            
            [toRmFileKeyMap setValue:identifier forKey:fileName];// fileName为Key，identifier为值
        }
        [fileAndGroups setObject:toRmFileKeyMap forKey:@"files"];
    }
    
    if ([groups isKindOfClass:[NSArray class]] && groups.count) {
        
        NSMutableDictionary* tmp = [[NSMutableDictionary alloc] initWithCapacity:groups.count];
        
        for (NSString *obj in groups) {
            
            [tmp setValue:@YES forKey:obj];
        }
        [fileAndGroups setObject:tmp forKey:@"groups"];
    }
    /////
    NSFileManager* manager = [BECache fileMgr];
    
    NSString* mediaPath = [BECache pathForKey:nil extension:nil];
    
    if (fileAndGroups.count > 0) {
        
        NSArray* items = [manager contentsOfDirectoryAtPath:mediaPath error:nil];
        
        //1、取消暂无缓存文件且有可能已经在队列中的 [任务]和[组]
        NSMutableSet* willCanceledFiles = [NSMutableSet setWithArray:[toRmFileKeyMap allKeys]];

        [willCanceledFiles minusSet:[NSMutableSet setWithArray:items]];

        NSMutableArray* identifiers = [toRmFileKeyMap objectsForKeys:willCanceledFiles.allObjects notFoundMarker:@"-"].mutableCopy;
        
        [identifiers removeObject:@"-"];
        
        NSMutableDictionary* object = [NSMutableDictionary new];
        
        if (identifiers.count > 0) {
            
            [object setValue:identifiers forKey:@"identifiers"];
        }
        
        if (groups.count > 0) {
            
            [object setValue:groups forKey:@"groups"];
        }
        
        if (object.count > 0) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BECache_clean_cache" object:object];
        }
        
        //2、取消有缓存文件（已下载/正在下载）的任务后，再清除
        for (NSString* component in items) {
            
            if ([[component pathExtension] isEqualToString:@"idx"] && ![component hasPrefix:@"."]) {
                
                NSString* identifier = [component stringByDeletingPathExtension];
                
                NSMutableDictionary* info = [[NSMutableDictionary alloc] initWithDictionary:[[self share] contentInfo:identifier] copyItems:YES];
                
                BOOL toDel = NO;
                
                NSMutableArray* groupNames = [NSMutableArray arrayWithArray:[info[@"group"] componentsSeparatedByString:@","]];
                
                NSMutableSet* groupNamesSet = [NSMutableSet setWithArray:groupNames];
                
                NSMutableSet* toRmSet = [NSMutableSet setWithArray:[fileAndGroups[@"groups"] allKeys]];
                
                //删除交集中元素
                [groupNamesSet minusSet:toRmSet];
                
                [groupNames removeAllObjects];
                
                [groupNames addObjectsFromArray:groupNamesSet.allObjects];
                
                if (groupNames.count > 0) {
                    
                    info[@"group"] = [groupNames componentsJoinedByString:@","];
                    
                    [[self share] updateContentInfo:info identifier:identifier onComplete:^(NSData * _Nullable data, NSString * _Nullable identifier, BEMCFlagType flag) {}];
                }
                
                if (groupNames.count == 0) {
                    
                    toDel = YES;
                }
                
                if(fileAndGroups[@"files"][[identifier stringByAppendingPathExtension:@"idx"]]){
                    
                    toDel = YES;
                }
                
                if (toDel) {
                    
                    [BECache cancelAndClean:identifier onComplete:^{
                        
                        [[BECache share].buffer removeObjectForKey:identifier];
                    }];
                }
            }
        }
        
        if (onComplete) {
            
            onComplete();
        }
        
    }else if(!files && !groups){
        
        [BECache cancelAndClean:nil onComplete:^{
            
            NSError* error = NULL;
            
            [manager removeItemAtPath:[mediaPath stringByDeletingLastPathComponent] error:&error];//删除~/Library/Caches/MediaCache
            
            [[BECache share].buffer removeAllObjects];
            
            if (onComplete) {
                
                onComplete();
            }
        }];
    }
}

- (void)internalUpdateData:(NSData *)data range:(NSRange)range identifier:(NSString *)identifier totalLenght:(uint64_t)totalLenght info:(NSDictionary *)info onComplete:(BECacheHandler)handler {
    
    if (!data && !info) {
        
        [self removeItemForIdentifier:identifier];
        
        return;
    }
    
    //
    BECacheItemFragment* fragment = [BECacheItemFragment new];
    
    fragment.action = BECacheActionWrite;
    
    fragment.data = data;
    
    fragment.range = range;
    
    fragment.identifier = identifier;
    
    fragment.completeHandler = handler;
    
    //
    BECacheItem* item = [self itemForIdentifier:identifier];
    
    if (info && ![item.info.description isEqualToString:info.description]) {
        
        item.info = info;
        
        item.extension = info[@"extension"];
        
        fragment.action = BECacheActionWriteInfo;
    }
    
    [item addFragment:fragment];
}

- (void)internalDataForRange:(NSRange)range identifier:(NSString *)identifier onReadNewData:(void (^)(NSData * _Nonnull))readDataHandler onComplete:(BECacheHandler)handler {
    
    BECacheItemFragment* fragment = [BECacheItemFragment new];
    
    fragment.action = BECacheActionRead;
    
    fragment.readNewDataHandler = readDataHandler;
    
    fragment.completeHandler = handler;
    
    fragment.identifier = identifier;
    
    fragment.range = range;
    
    BECacheItem* item = [self itemForIdentifier:identifier];
    
    [item addFragment:fragment];
}

- (BECacheItem *)itemForIdentifier:(NSString *)identifier {
    
    BECacheItem* item = self.buffer[identifier];
    
    if (!item) {
        
        item = [BECacheItem new];
        
        item.identifier = identifier;
        
        self.buffer[identifier] = item;
    }
    return item;
}

- (void)removeItemForIdentifier:(NSString *)identifier {
    
    if (![identifier isKindOfClass:[NSString class]]) {
        
        [self.buffer removeAllObjects];
    }else{
        
        [self.buffer removeObjectForKey:identifier];
    }
}

+ (void)cancelAndClean:(NSString *)identifier onComplete:(void (^)(void))onComplete {
    
    void (^onCanceled)(void) = ^{
        
        if (identifier) {
            
            [BECache deleteFileWithIdentifier:identifier];
        }
        
        dispatch_async(SerialQueue(), ^{
            
            if (onComplete) {
                
                onComplete();
            }
        });
    };
    
    //兜底,3s不返回，强制执行
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), SerialQueue(), ^{
        
        onCanceled();
    });
    
    if (identifier) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BECache_clean_cache" object:@{@"identifier":identifier, @"onCanceled": onCanceled}];
    }else{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BECache_cleanAll" object:@{@"onCanceled":onCanceled}];
    }
}

#pragma mark - Notify

- (void)memoryWarning:(NSNotification *)notify {
    
    __weak typeof(self.buffer) wb = self.buffer;
    
    dispatch_async(SerialQueue(), ^{
        
        for (NSString* identifier in [wb allKeys]) {
            
            if (wb[identifier].isIdle) {
                
                [wb removeObjectForKey:identifier];
            }
        }
    });
}


@end

@implementation BECache (File)

+ (NSString *)pathForKey:(nullable NSString *)key extension:(nullable NSString *)extension {
    
    NSString* path = [[BECache share] pathForIdentifier:key];
    
    if (extension.length) {
        
        path = [path stringByAppendingPathExtension:extension];
    }
    
    return path;
}

+ (NSFileManager *)fileMgr {
    
    return [BECache share].fileMgr;
}

+ (uint64_t)deleteFileWithIdentifier:(NSString *)identifier {
    
    uint64_t freedSize = 0;
    
    if ([identifier isKindOfClass:[NSString class]] && identifier.length > 0) {
        
        NSString* idxPath = [self pathForKey:identifier extension:@"idx"];
        
        NSDictionary* info = [[self share] contentInfo:identifier];
        
        NSString* filePath = [self pathForKey:identifier extension:info[@"extension"]];
        
        uint64_t idxSize = [[BETool fileAttribute:idxPath][@"fileSize"] unsignedLongLongValue];
        
        uint64_t fileSize = [[BETool fileAttribute:filePath][@"fileSize"] unsignedLongLongValue];
        
        if ([[self fileMgr] removeItemAtPath:idxPath error:nil]) {
            
            freedSize += idxSize;
        }
        if ([[self fileMgr] removeItemAtPath:filePath error:nil]) {
            
            freedSize += fileSize;
        }
        [[self share] updateContentInfo:nil identifier:identifier onComplete:^(NSData * _Nullable data, NSString * _Nullable identifier, BEMCFlagType flag) {}];
    }
    
    return freedSize;
}

+ (void )enoughDiskSpaceForLength:(NSUInteger )expectLength onComplete:(void (^)(BOOL enoughSpace))onComplete {
    
    //======================= Start ======================
    
    NSFileManager* manager = [BECache fileMgr];
    
    NSString* mediaWorkPath = [BECache pathForKey:nil extension:nil];
    
    uint64_t totalFreeSpace = [[manager attributesOfFileSystemForPath:mediaWorkPath error:nil][NSFileSystemFreeSize] unsignedLongLongValue];
    
    uint64_t totalCacheSize = [BECache cacheSize];

    NSMutableArray* tmp = nil;
    
    if (!tmp) {
        
        tmp = [NSMutableArray new];
        
        //遍历工作目录
        NSArray* items = [manager contentsOfDirectoryAtPath:mediaWorkPath error:nil];
        
        for (NSString* fileName in items) {
            
            //查找.idx 文件，再获取对应下载文件
            if ([[fileName pathExtension] isEqualToString:@"idx"]) {
                
                NSString* identifier = [fileName stringByDeletingPathExtension];
                
                NSDictionary* info = [[self share] contentInfo:identifier];
                
                NSString* fName = [identifier stringByAppendingPathExtension:info[@"extension"]?:@""];
                
                NSArray* groups = [info[@"group"] componentsSeparatedByString:@","];
                
                //有且仅有默认组 || 组为空  则删除
                if (info && ((groups.count == 1 && [groups.firstObject isEqualToString:DEFAULT_GROUP]) || groups.count == 0)) {
                    
                    NSString* fullPath = [mediaWorkPath stringByAppendingPathComponent:fName];
                    
                    NSDictionary* attr = [BETool fileAttribute:fullPath];
                    
                    long itval = [attr[@"lastAccessTime"] longValue];
                    
                    [tmp addObject:@{@"tv":@(itval), @"identifier":identifier}];
                }
            }
        }
        
        NSArray* sortArr = [tmp sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tv" ascending:NO]]];
        
        tmp = [NSMutableArray arrayWithArray:sortArr];
    }
    
    //超出自限缓存阈值
    while (totalCacheSize > [BECache share].limitCacheSize && totalCacheSize > 1024 && tmp.lastObject) {
        
        uint64_t freedSize = [self deleteFileWithIdentifier:tmp.lastObject[@"identifier"]];
        
        [tmp removeObject:tmp.lastObject];
        
        totalCacheSize -= freedSize;
        
        totalFreeSpace += freedSize;
    }
    
    //剩余空间不足
    while ((totalFreeSpace < expectLength || totalFreeSpace < MiniDiskSpace) && tmp.lastObject) {
        
        uint64_t freedSize = [self deleteFileWithIdentifier:tmp.lastObject[@"identifier"]];
        
        [tmp removeObject:tmp.lastObject];
        
        totalCacheSize -= freedSize;
        
        totalFreeSpace += freedSize;
    }
    
    totalFreeSpace = [[manager attributesOfFileSystemForPath:mediaWorkPath error:nil][NSFileSystemFreeSize] unsignedLongLongValue];
    
    totalCacheSize = [BECache cacheSize];
    
    tmp = nil;
    
    BOOL enoughSpace = totalFreeSpace > expectLength + 1024;
    
    if (onComplete) {
        
        onComplete(enoughSpace);
    }
}


@end
