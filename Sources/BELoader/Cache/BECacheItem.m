//
//  BECacheItem.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BECacheItem.h"
#import "../BETool.h"
#import "BECache.h"
#import "../BEResourceLoaderConstants.h"

static NSUInteger RWBufferSize;

BOOL RangeMergeable(NSRange range1, NSRange range2) {
    return (NSMaxRange(range1) == range2.location) || (NSMaxRange(range2) == range1.location) || NSIntersectionRange(range1, range2).length > 0;
}

BOOL ContainRange(NSRange srcRange, NSRange dstRange) {
    return srcRange.location <= dstRange.location && NSMaxRange(srcRange) >= NSMaxRange(dstRange);
}


@interface BECacheItem () {
    dispatch_queue_t ioQueue;
    
    dispatch_queue_t serialQueue;
    
    dispatch_block_t idxsArchiveTask;
}

@property(nonatomic, strong) NSMutableDictionary* idxs;

@property(nonatomic, assign) uint64_t contentLength;

@property(nonatomic, strong) NSMutableArray* fragmentBuffer;

@end


@implementation BECacheItem

@synthesize info = _info;

- (void)dealloc{
    
//    printf("%s\n", __func__);
    
    [_fileHandle closeFile];
    
    _fileHandle = nil;
    
    ioQueue = NULL;
    
    idxsArchiveTask = NULL;
    
    _fragmentBuffer = nil;
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        ioQueue = IOQueue();
        
        serialQueue = SerialQueue();
        
        RWBufferSize = [BETool diskBlockSzie];
        
        _fragmentBuffer = [NSMutableArray new];
    }
    
    return self;
}

#pragma mark - File Opt

- (BOOL )checkWorkPath {
    
    NSString* path = [BECache pathForKey:nil extension:nil];
    
    NSFileManager* manager = [BECache fileMgr];
    
    BOOL isDir = YES;
    
    NSError* error;
    //(不存在 && 创建)
    if(!(![manager fileExistsAtPath:path isDirectory:&isDir] && [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error])) {
        
        if (error) {
            
            printf("create dir is error\n");
            
            return NO;
        }
    }
    
    return YES;
}

- (NSString* )checkFile:(NSString *)identifier autoCreate:(BOOL )isAutoCreate{
    
    static NSFileManager* manager = NULL;
    
    if (!manager) {
        
        manager = [BECache fileMgr];
    }
    
    if (![self checkWorkPath]) { return nil; }
    
    NSString* path = [BECache pathForKey:identifier extension:nil];//
    
    BOOL existed;
    
    if (!(existed = [manager fileExistsAtPath:path])) {
        
        if (isAutoCreate) {
            
            if (!(existed =[manager createFileAtPath:path contents:nil attributes:nil])) {
                
                //不存在且创建失败
                if (!existed) {
                    
                    return nil;
                }
            }
        }else{
            return nil;
        }
    }
    return path;
}

#pragma mark - GET/SET

- (NSFileHandle *)fileHandle {
    
    if (!_fileHandle) {
        
        NSString* path = [BECache pathForKey:self.identifier extension:self.extension];
        
        _fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];
    }
    return _fileHandle;
}

- (NSMutableDictionary *)idxs {
    
    if (!_idxs) {
        
        NSData* data = [[BECache fileMgr] contentsAtPath:[BECache pathForKey:[self.identifier stringByAppendingString:@".idx"] extension:nil]];//

        if (data.length) {

            id tmp = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            
            if ([tmp isKindOfClass:[NSDictionary class]] && [(NSDictionary *)tmp count]) {
                
                _idxs = [[NSMutableDictionary alloc] initWithCapacity:2];
                
                [_idxs addEntriesFromDictionary:tmp];
            }
        }else if (_info){
            
            _idxs = [[NSMutableDictionary alloc] initWithCapacity:2];
            
            _idxs[@"contentInfo"] = _info;
        }
    }
    return _idxs;
}

- (void)setIdentifier:(NSString *)identifier {
    
    if (identifier) {
        
        _identifier = identifier;
        
        [self fileName];
        
        [self contentLength];
    }
}

- (void)setInfo:(NSDictionary *)info {
    
    _info = info;
    
    self.idxs[@"contentInfo"] = info;
}

- (NSDictionary *)info {
    
    _info = self.idxs[@"contentInfo"];
    
    return _info;
}

- (NSString *)extension {
    
    if (_extension.length == 0) {
        
        _extension = self.info[@"extension"]?:@"";
    }
    return _extension;
}

- (NSString *)fileName {
    
    _fileName = [self.identifier stringByAppendingPathExtension:self.extension];
    
    return _fileName;
}


- (uint64_t)contentLength {
    
    _contentLength = [self.info[@"contentLength"] unsignedLongLongValue];
    
    return _contentLength;
}

#pragma mark - Public

//cache任务分发
- (void)addFragment:(BECacheItemFragment *)fragment {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(serialQueue, ^{
       
        __strong typeof(ws) ss = ws;
        
        if (!ss) {
            
            return;
        }
        
        fragment.running = YES;
        
        [ss.fragmentBuffer insertObject:fragment atIndex:0];
        
        BECacheHandler originCompleteHandler = fragment.completeHandler;
        
        __weak BECacheItemFragment* wf = fragment;
        
        fragment.completeHandler = ^(NSData * _Nullable data, NSString * _Nullable identifier, BEMCFlagType flag) {
            
            if (originCompleteHandler) {
                
                originCompleteHandler(data, identifier, flag);
            }
            
            [ss.fragmentBuffer removeObject:wf];
            
            if (ss.fragmentBuffer.count == 0) {
                
                ss.idle = YES;
            }
        };
        
        switch (fragment.action) {
                
            case BECacheActionWriteInfo:
            {
                ss.idle = NO;
                
                [ss updateContentInfo:fragment];
            }
                break;
            case BECacheActionWrite:
            {
                ss.idle = NO;
                
                [ss write:fragment];
            }
                break;
                
            case BECacheActionRead:
            {
                ss.idle = NO;
                
                [ss read:fragment];
            }
                break;
                
            case BECacheActionReadRanges:
            {
                ss.idle = NO;
                
                [ss queryCacheRanges:fragment];
            }
                break;
            default:
            {}
                break;
        }
    });
}

#pragma mark - Internal

- (void)updateContentInfo:(BECacheItemFragment *)fragment {
    
    NSMutableDictionary* idxs = [self indexsForIdentifier:fragment.identifier];
    
    idxs[@"contentInfo"] = self.info;
    
    NSUInteger expectLen = [self.info[@"contentLength"] unsignedLongLongValue];
    
    __block BEMCFlagType flag = BEMCFlagTypeSuccess;
    
    __block BOOL archivingIdx = YES;
    
    __weak typeof(self) ws = self;
    
    if (![self checkFile:self.fileName autoCreate:NO]) {
        
        [BECache enoughDiskSpaceForLength:expectLen onComplete:^(BOOL enoughSpace) {
            
            if (enoughSpace) {
                
                if ([ws checkFile:ws.fileName autoCreate:YES]) {
                    
                    [ws.fileHandle truncateFileAtOffset:ws.contentLength];
                    
                    archivingIdx = YES;
                    
                }else{
                    
                    archivingIdx = NO;
                    
                    flag = BEMCFlagTypeCreateFileFailed;
                }
            }else{
                
                archivingIdx = NO;
                
                flag = BEMCFlagTypeNotEnoughSpace;
            }
            
            ///是否归档索引文件
            if (archivingIdx) {
                
                [ws archiveIdxsForIdentifier:fragment.identifier onComplete:^(NSData *data, NSString *identifier, BEMCFlagType flag) {
                    
                    if (fragment.completeHandler) {
                        
                        fragment.completeHandler(data, identifier, flag);
                    }
                }];
            }else{
                
                if (fragment.completeHandler) {
                    
                    fragment.completeHandler(nil, fragment.identifier, flag);
                }
            }
        }];
        
//        if ([BECache enoughDiskSpaceForLength:expectLen]) {
//
//            if ([self checkFile:self.fileName autoCreate:YES]) {
//
//                [self.fileHandle truncateFileAtOffset:self.contentLength];
//
//                archivingIdx = YES;
//
//            }else{
//
//                archivingIdx = NO;
//
//                flag = BEMCFlagTypeCreateFileFailed;
//            }
//        }else{
//
//            archivingIdx = NO;
//
//            flag = BEMCFlagTypeNotEnoughSpace;
//        }
    }
    
//    if (archivingIdx) {
//
//        [self archiveIdxsForIdentifier:fragment.identifier onComplete:^(NSData *data, NSString *identifier, BEMCFlagType flag) {
//
//            if (fragment.completeHandler) {
//
//                fragment.completeHandler(data, identifier, flag);
//            }
//        }];
//    }else{
//
//        if (fragment.completeHandler) {
//
//            fragment.completeHandler(nil, fragment.identifier, flag);
//        }
//    }
}

- (void)write:(BECacheItemFragment *)fragment {

    __weak typeof(self) weakSelf = self;
    
    dispatch_block_t writeTask = dispatch_block_create(DISPATCH_BLOCK_BARRIER, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (!strongSelf) { return; }
        
        if (![strongSelf checkFile:strongSelf.fileName autoCreate:NO]) {
            
            if (fragment.completeHandler) {
                
                dispatch_async(strongSelf->serialQueue, ^{
                    
                    fragment.completeHandler(nil, fragment.identifier, BEMCFlagTypeWriteFailed);
                });
            }
            return;
        }
        
        BEMCFlagType flag = BEMCFlagTypeSuccess;
        
        [weakSelf.fileHandle seekToFileOffset:fragment.range.location];
        
        fragment.counter = weakSelf.fileHandle.offsetInFile;
        
        @try {
            
            NSUInteger q = fragment.range.length / RWBufferSize;
            
            NSUInteger r = fragment.range.length % RWBufferSize;
            
            NSUInteger counter = 0;
            
            for (int i = 0; i < q; i++) {
                
                @autoreleasepool {
                    
                    NSData* dataBlock = [fragment.data subdataWithRange:NSMakeRange(counter*RWBufferSize, RWBufferSize)];
                    
                    [weakSelf.fileHandle writeData:dataBlock];
                    
                    dataBlock = nil;
                    
                    counter += RWBufferSize;
                }
            }
            
            if (r != 0) {
                
                NSData* dataBlock = [fragment.data subdataWithRange:NSMakeRange(counter, r)];
                
                [weakSelf.fileHandle writeData:dataBlock];
                
                dataBlock = nil;
                
                counter += RWBufferSize;
            }

        } @catch (NSException *exception) {
            
            printf("write data exception \n%s\n", exception.description.UTF8String);
            
            flag = BEMCFlagTypeWriteFailed;
            
        } @finally {}
        
        if (flag == BEMCFlagTypeSuccess) {
            
            fragment.counter = weakSelf.fileHandle.offsetInFile - fragment.counter;
            
            if (fragment.counter != fragment.range.length) {
                
                fragment.range = NSMakeRange(fragment.range.location, fragment.counter);
                
                printf("write execption\n");
            }
            
            dispatch_async(strongSelf->serialQueue, ^{
                
                [strongSelf updateRange:fragment.range identifier:fragment.identifier];
            });
        }
        
        if (fragment.completeHandler) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (!strongSelf) { return; }
            
            dispatch_async(strongSelf->serialQueue, ^{
                
                fragment.completeHandler(fragment.data, fragment.identifier, flag);
            });
        }
    });

    if (![self checkRange:fragment.range identifier:fragment.identifier]) {
        
        dispatch_barrier_async(self->ioQueue, writeTask);
    }
}

- (void)read:(BECacheItemFragment *)fragment {
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(ioQueue, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (!strongSelf) { return; }
        
        BEMCFlagType flag = BEMCFlagTypeSuccess;
        
        if (![weakSelf checkRange:fragment.range identifier:fragment.identifier]) {
            
            flag = BEMCFlagTypeReadNothing;
            
        }else{
            
            if ([weakSelf checkFile:strongSelf.fileName autoCreate:NO]) {
                
                @autoreleasepool {
                    
                    NSError* error = NULL;
                    
                    NSString* path = [BECache pathForKey:weakSelf.fileName extension:nil];//
                    
                    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe|NSDataReadingUncached error:&error];
                    
                    if (!error && data.length >= (fragment.range.location + fragment.range.length)) {
                        
                        NSUInteger q = fragment.range.length / RWBufferSize;
                        
                        NSUInteger r = fragment.range.length % RWBufferSize;
                        
                        for (int i = 0; i < q; i++) {
                            
                            @autoreleasepool {
                                
                                NSData *tmp = [data subdataWithRange:NSMakeRange(fragment.range.location + fragment.counter, RWBufferSize)];
                                
                                fragment.counter += tmp.length;
                                
                                if (fragment.readNewDataHandler) {
                                    
                                    dispatch_async(strongSelf->serialQueue, ^{
                                        
                                        fragment.readNewDataHandler(tmp);
                                    });
                                }
                            }
                        }
                        
                        if (r != 0) {
                            
                            NSData* tmp = [data subdataWithRange:NSMakeRange(fragment.range.location + fragment.counter, r)];
                            
                            fragment.counter += tmp.length;
                            
                            if (fragment.readNewDataHandler) {
                                
                                dispatch_async(strongSelf->serialQueue, ^{
                                    
                                    fragment.readNewDataHandler(tmp);
                                });
                            }
                        }
                    }else{
                        
                        flag = BEMCFlagTypeReadFailed;
                    }
                    
                    BOOL rc = (fragment.counter == fragment.range.length) && fragment.counter != 0 && flag == BEMCFlagTypeSuccess;
                    
                    fragment.data = rc ? [NSData data] : nil;
                }
            }else{
                
                flag = BEMCFlagTypeReadFailed;
            }
        }
        
        if (fragment.completeHandler) {
            
            dispatch_async(strongSelf->serialQueue, ^{
                
                fragment.completeHandler(fragment.data, fragment.identifier, flag);
            });
        }
    });
}

- (void)queryCacheRanges:(BECacheItemFragment *)fragment {
    
    NSMutableDictionary* indexs = self.idxs;
    
    uint64_t totalLength = [indexs[@"contentInfo"][@"contentLength"] unsignedLongLongValue];
    
    NSArray* idxs = indexs[@"idxs"];
    
    NSMutableArray* pending = [NSMutableArray new];
    
    if (idxs.count > 0) {
        
        uint64_t flag = 0;
        
        for (int i = 0; i < idxs.count; i++) {
            
            NSRange range = [idxs[i] rangeValue];
            //Normal
            if (range.location > flag) {
                
                NSUInteger length = range.location - flag;
                
                [pending addObject:[NSValue valueWithRange:NSMakeRange(flag, length)]];
            }
            
            flag = range.location + range.length;
            
            if (i == idxs.count - 1 && flag < totalLength) {
                
                [pending addObject:[NSValue valueWithRange:NSMakeRange(flag, totalLength - flag)]];
            }
        }
    }else{
        
        if (totalLength > 0) {
            
            [pending addObject:[NSValue valueWithRange:NSMakeRange(0, totalLength)]];
        }else{
            
            pending = nil;
        }
    }
    
    __weak typeof(self) ws = self;
    
    if (fragment.queryRangeHandler) {
        
        dispatch_async(serialQueue, ^{
            
            fragment.queryRangeHandler(totalLength, [idxs copy], [pending copy], ws.info);
        });
    }
    
    if (fragment.completeHandler) {
        
        dispatch_async(serialQueue, ^{
            
            fragment.completeHandler(nil, fragment.identifier, BEMCFlagTypeSuccess);
        });
    }
}

#pragma mark - Indexs

- (NSMutableDictionary *)indexsForIdentifier:(NSString *)identifier {
    
    if (!self.idxs) {
        
        self.idxs = [NSMutableDictionary dictionaryWithCapacity:2];
    }
    return self.idxs;
}

- (void)archiveIdxsForIdentifier:(NSString *)identifier onComplete:(BECacheHandler )handler {
    
    if (idxsArchiveTask) {
        
        dispatch_block_cancel(idxsArchiveTask);
        
        idxsArchiveTask = NULL;
    }
    
    NSDictionary* tmp = [[NSDictionary alloc] initWithDictionary:self.idxs copyItems:YES];
    
    idxsArchiveTask = dispatch_block_create(0, ^{
        
        NSString *idxPath = [[BECache pathForKey:identifier extension:nil] stringByAppendingPathExtension:@"idx"];//
        
        NSData* idxData = [[NSData alloc] initWithData:[NSKeyedArchiver archivedDataWithRootObject:tmp]];
        
        if ([[BECache fileMgr] createFileAtPath:idxPath contents:idxData attributes:nil]) {
            
            handler(nil, identifier, BEMCFlagTypeSuccess);
            
        }else{
            handler(nil, identifier, BEMCFlagTypeWriteFailed);
        }
    });
    dispatch_async(ioQueue, idxsArchiveTask);
}

#pragma mark - Internal Idx Opt

- (BOOL )checkRange:(NSRange )range identifier:(NSString *)identifier {
    
    NSArray* idxs = [[self indexsForIdentifier:identifier] objectForKey:@"idxs"];
    
    BOOL hasData = NO;
    
    for (NSValue* rangeValue in idxs) {
        
        if (ContainRange([rangeValue rangeValue], range)) {
            
            hasData = YES;
            
            break;
        }
    }
    return hasData;
}

- (void)updateRange:(NSRange )range identifier:(NSString *)identifier {
    
    NSMutableArray* idxs = [NSMutableArray arrayWithArray:self.idxs[@"idxs"]?:@[]];
    
    if (idxs.count) {
        
        NSInteger flag = -1;//
        
        for ( int i = 0; i < idxs.count; i++ ) {
            
            @autoreleasepool {
                
                NSRange idxRange = [idxs[i] rangeValue];
                
                switch (flag) {
                        
                    case -1://寻找插入点
                    {
                        if (range.location <= idxRange.location) {
                            
                            [idxs insertObject:[NSValue valueWithRange:range] atIndex:i];
                            
                            //插入后，进入向后合并检查
                            flag = 1;
                            
                            i--;
                            
                        }else{
                            
                            if (RangeMergeable(range, idxRange)) {//可合并
                                
                                [idxs replaceObjectAtIndex:i withObject:[NSValue valueWithRange:NSUnionRange(range, idxRange)]];
                                
                                //合并后，进行向后合并检查
                                flag = 1;
                                
                                i--;
                            }
                        }
                    }
                        break;
                        
                    case 1://向后检查是否可合并，是则合并，否则结束
                    {
                        //如果是最后一个，无需合并
                        if (!(i+1 < idxs.count)) { break; }
                        
                        NSRange rangeAfter = [idxs[i+1] rangeValue];
                        
                        if (RangeMergeable(idxRange, rangeAfter)) {
                            
                            NSRange mergeRange = NSUnionRange(idxRange, rangeAfter);
                            
                            [idxs removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i, 2)]];
                            
                            [idxs insertObject:[NSValue valueWithRange:mergeRange] atIndex:i];
                            
                            //i和i+1合为n,需要检查 n与i+2是否可合并,再来一次
                            //(其他地方 i-- 同理)
                            i--;
                            
                        }else{
                            
                            flag = 2;
                            
                            break;
                        }
                    }
                        break;
                        
                    case 2://向后合并结束
                    {
                        //干点啥
                    }
                }
            }
        }
        
        if (flag == -1) {
            
            [idxs addObject:[NSValue valueWithRange:range]];
        }
    }else{
        
        [idxs addObject:[NSValue valueWithRange:range]];
    }
    
    self.idxs[@"idxs"] = idxs;
    
    [self archiveIdxsForIdentifier:identifier onComplete:^(NSData *data, NSString *identifier, BEMCFlagType flag) {}];
}

@end


@implementation BECacheItemFragment

- (void)dealloc {
    
    _completeHandler = nil;
    
    _readNewDataHandler = nil;
}

- (instancetype)init{
    
    if (self = [super init]) {
        
        _counter = 0;
    }
    return self;
}

@end
