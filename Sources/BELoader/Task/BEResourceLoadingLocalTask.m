//
//  BEResourceLoadingLocalTask.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEResourceLoadingLocalTask.h"
#import "BEResourceTaskModel.h"
#import "../Cache/BECache.h"
#import "../BEResourceLoaderConstants.h"
#import "../BETool.h"

@interface BEResourceLoadingLocalTask()

@property(nonatomic, strong) NSMutableArray<BEResourceTaskModel *> *requestOrderedBuffer;

@end

@implementation BEResourceLoadingLocalTask

- (void)dealloc{
    
    _MediaLocalTaskDidFinished = nil;
    
    _MediaLocalTaskDidResponseData = nil;
    
    _MediaLocalTaskFinishedAll = nil;
    
//    printf("%s\n", __func__);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _requestOrderedBuffer = [NSMutableArray new];
    }
    return self;
}

- (void)addLocalTaskURL:(NSURL *)url range:(NSRange )range loadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest resourceLoaderIdentifier:(NSString *)resourceLoaderIdentifier {

    NSDictionary* info = [[BECache share] contentInfo:self.localIdentifier];
    
    if (info.allKeys.count) {
        
        long long contentLength = [info[@"contentLength"] longLongValue];
        
        loadingRequest.contentInformationRequest.contentLength = contentLength;
        
        loadingRequest.contentInformationRequest.contentType = info[@"contentType"];

        loadingRequest.contentInformationRequest.byteRangeAccessSupported = [info[@"byteRangeAccessSupported"] boolValue];
        
        if (range.length == NSUIntegerMax && contentLength != 0) {
            
            range.length = (NSUInteger )contentLength - range.location;
        }
    }
    BEResourceTaskModel* fragment = [BEResourceTaskModel new];
    
    fragment.loadingRequest = loadingRequest;
    
    fragment.resourceLoaderIdentifier = resourceLoaderIdentifier;
    
    fragment.range = range;
    
    fragment.taskType = BETaskTypeLocal;
    
    [self updateBuffer:fragment action:YES];
    
    [self startTask:fragment];
}

- (void)cancelLocalTaskForLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest orResourceLoaderIdenifier:(NSString *)resourceLoaderIdentifier {
    
    if (!loadingRequest) {
        
        [self.requestOrderedBuffer enumerateObjectsUsingBlock:^(BEResourceTaskModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [obj cancel];
        }];
        [self updateBuffer:nil action:YES];
        
    }else{
        
        __block BEResourceTaskModel* tmp;
        
        [self.requestOrderedBuffer enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(BEResourceTaskModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ((loadingRequest == obj.loadingRequest) && (resourceLoaderIdentifier && [obj.resourceLoaderIdentifier isEqualToString:obj.resourceLoaderIdentifier])) {
                
                [obj cancel];
                
                tmp = obj;
                
                *stop = YES;
            }else{
                
                [obj cancel];
            }
        }];
        if (tmp) { [self updateBuffer:tmp action:NO]; }
    }
}

- (void)startTask:(BEResourceTaskModel* )fragment {
    
    typeof(self) weakSelf = self;
    
    fragment.status = BEResourceTaskStatusRunning;
    
    [[BECache share] dataForRange:fragment.range identifier:self.localIdentifier onReadNewData:^(NSData *nData) {
        
        if (weakSelf.MediaLocalTaskDidResponseData && fragment.status != BEResourceTaskStatusCancelled) {
            
            weakSelf.MediaLocalTaskDidResponseData(fragment.loadingRequest, nData);
        }
    } onComplete:^(NSData *data, NSString *identifier, BEMCFlagType flag) {
        
        if (weakSelf.MediaLocalTaskDidFinished) {
            
            NSError* error = nil;
            
            if (flag != BEMCFlagTypeSuccess) {
                
                if (fragment.status == BEResourceTaskStatusCancelled) {
                    
                    error = [NSError errorWithDomain:@"fun.bluegg.mediacache" code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:@"beCancelled", NSURLErrorFailingURLStringErrorKey:fragment.loadingRequest.request.URL}];
                }else{
                    
                    if (flag == BEMCFlagTypeNotEnoughSpace) {
                        
                        error = [NSError errorWithDomain:@"fun.bluegg.mediacache" code:BEMCFlagTypeNotEnoughSpace userInfo:@{NSLocalizedDescriptionKey:@"may be not enough space"}];
                        
                    }else{
                        error = [NSError errorWithDomain:@"fun.bluegg.mediacache" code:NSURLErrorUnknown userInfo:@{NSLocalizedDescriptionKey:@"may be no cache data"}];
                    }
                }
            }

            weakSelf.MediaLocalTaskDidFinished(fragment.loadingRequest, fragment.range, flag == BEMCFlagTypeSuccess ? nil:error);
        }
        
        [weakSelf updateBuffer:fragment action:NO];
    }];
}

- (void)updateBuffer:(BEResourceTaskModel* )obj action:(BOOL )isAdd {
    
    __weak BEResourceLoadingLocalTask* weakSelf = self;
    
    dispatch_async(SerialQueue(), ^{
        
        if (obj) {
            
            if (isAdd) {
                
                [weakSelf.requestOrderedBuffer addObject:obj];
            }else{
                
                [weakSelf.requestOrderedBuffer removeObject:obj];
            }
        }else{
            
            [weakSelf.requestOrderedBuffer removeAllObjects];
        }
        
        if (weakSelf.requestOrderedBuffer.count == 0) {
            
            if (weakSelf.MediaLocalTaskFinishedAll) {
                
                weakSelf.MediaLocalTaskFinishedAll();
            }
        }
    });
}
@end
