//
//  BEResourceTask.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEResourceTask.h"
#import "BEResourceLoadingLocalTask.h"
#import "BEResourceLoadingRemoteTask.h"
#import "../BEResourceLoaderConstants.h"

@interface BEResourceTask ()

@property (nonatomic, strong) BEResourceLoadingLocalTask* localTask;

@property (nonatomic, strong) BEResourceLoadingRemoteTask* remoteTask;

@property (nonatomic, assign) NSUInteger totalLength;

@end

@implementation BEResourceTask

- (void)dealloc{
    
    [_remoteTask cancelRemoteTaskForLoadingRequest:nil orResourceLoaderIdentifier:nil];
    
    _localTask = nil;
    
    _remoteTask = nil;
    
//    printf("%s\n", __func__);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _totalLength = NSUIntegerMax;
        
        _localTask = [BEResourceLoadingLocalTask new];
        
        _remoteTask = [BEResourceLoadingRemoteTask new];
    }
    return self;
}

#pragma mark - SET/GET

- (void)setKey:(NSString *)key {
    
    _key = key;
    
    _localTask.localIdentifier = _remoteTask.remoteIdentifier = key;
}

#pragma mark - Public

- (void)addRequest:(AVAssetResourceLoadingRequest *)loadingRequest forResourceLoaderIdentifier:(NSString *)resourceLoaderIdentifier {
    
    AVAssetResourceLoadingDataRequest* dataRequest = loadingRequest.dataRequest;

    NSRange range = [self requestRange:dataRequest];
    
    __weak typeof(self) weakSelf = self;

    //分段读取数据回调
    if (!self.localTask.MediaLocalTaskDidResponseData) {

        self.localTask.MediaLocalTaskDidResponseData = ^(AVAssetResourceLoadingRequest *loadingRequest, NSData *data) {

            if (data) {

                [loadingRequest.dataRequest respondWithData:data];
            }
        };
    }
    //单个任务完成回调
    if (!self.localTask.MediaLocalTaskDidFinished) {

        self.localTask.MediaLocalTaskDidFinished = ^(AVAssetResourceLoadingRequest *loadingRequest, NSRange range, NSError *error) {

            if (!error) {
                
                [loadingRequest finishLoading];
            }else{
                //读取本地数据出错或不存在直接走网络
                [weakSelf startRemoteTastWithLoadingRequest:loadingRequest range:range resourceLoaderIdentifier:resourceLoaderIdentifier];
            }
            weakSelf.remoteTask.cacheToDisk = error.code == BEMCFlagTypeNotEnoughSpace ? NO : YES;
        };
    }

    //所有任务完成回调
    if (!self.localTask.MediaLocalTaskFinishedAll) {

        __strong BEResourceTask* strongSelf = weakSelf;

        if (!strongSelf) { return ; }

        self.localTask.MediaLocalTaskFinishedAll = ^(void){
            //Local Ok
        };
    }

    [self.localTask addLocalTaskURL:loadingRequest.request.URL range:range loadingRequest:loadingRequest resourceLoaderIdentifier:resourceLoaderIdentifier];
}


- (void)cancelRequest:(AVAssetResourceLoadingRequest *)loadingRequest forResourceLoaderIdentifier:(NSString *)resourceLoaderIdentifier{
    
    [self.remoteTask cancelRemoteTaskForLoadingRequest:loadingRequest orResourceLoaderIdentifier:resourceLoaderIdentifier];
    
    [self.localTask cancelLocalTaskForLoadingRequest:loadingRequest orResourceLoaderIdenifier:resourceLoaderIdentifier];
}

#pragma mark - Internal

- (void)startRemoteTastWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest range:(NSRange )range resourceLoaderIdentifier:(NSString *)resourceLoaderIdentifier {
    //替换协议
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:loadingRequest.request.URL resolvingAgainstBaseURL:NO];
    
    components.scheme = [components.scheme stringByReplacingOccurrencesOfString:@"BECachescheme" withString:@"http"];
    
    NSURL* httpURL = [components URL];
    
    __weak typeof(self) weakSelf = self;
    
    //完成回调
    if (!self.remoteTask.MediaRemoteTaskAllDidComplete) {
        
        self.remoteTask.MediaRemoteTaskAllDidComplete = ^{
            //Remote Ok
        };
    }
    //响应回调
    if (!self.remoteTask.MediaRemoteTaskDidResponse) {

        self.remoteTask.MediaRemoteTaskDidResponse = ^(NSDictionary* contentInfo) {
            
            if (weakSelf.totalLength == NSUIntegerMax) {
                
                weakSelf.totalLength = [contentInfo[@"contentLength"] longLongValue];
            }
            
            AVAssetResourceLoadingContentInformationRequest* contentInformationRequest = loadingRequest.contentInformationRequest;
            
            contentInformationRequest.contentType = contentInfo[@"contentType"];
            
            contentInformationRequest.contentLength = weakSelf.totalLength;
            
            contentInformationRequest.byteRangeAccessSupported = [contentInfo[@"byteRangeAccessSupported"] boolValue];
        };
    }
    
    [self.remoteTask addRemoteTaskURL:httpURL range:range loadingRequest:loadingRequest resourceLoaderIdentifier:resourceLoaderIdentifier];
}

#pragma mark - Utility

//请求范围
- (NSRange )requestRange:(AVAssetResourceLoadingDataRequest *)dataRequest {
    
    return NSMakeRange(dataRequest.requestedOffset, dataRequest.requestedLength);
}

@end
