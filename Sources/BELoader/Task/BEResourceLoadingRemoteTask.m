//
//  BEResourceLoadingRemoteTask.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEResourceLoadingRemoteTask.h"
#import "BEResourceTaskModel.h"
#import "../BETool.h"
#import "../Cache/BECache.h"
#import "../BEResourceLoaderConstants.h"

@interface BEResourceLoadingRemoteTask() {
    uint64_t _totalLength;
}

@property(nonatomic, strong) NSURLSession* session;

@property(nonatomic, strong) NSMutableDictionary<NSURLSessionDataTask*, BEResourceTaskModel* >* requestBuffer;

@end

@implementation BEResourceLoadingRemoteTask

- (void)dealloc {
    
    _MediaRemoteTaskDidResponse = nil;
    
    _MediaRemoteTaskAllDidComplete = nil;
    
    _session = nil;
    
    printf("%s\n", __func__);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _requestBuffer = [NSMutableDictionary new];
        
        _totalLength = -1;
        
        _cacheToDisk = YES;
    }
    return self;
}

#pragma mark - GET/SET

- (NSURLSession *)session {
    
    if (!_session) {
        
        NSURLSessionConfiguration* cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        cfg.HTTPMaximumConnectionsPerHost = 32;
        
        _session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

#pragma mark - NSURLSessionDelegate && NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    NSURLCredential *card = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
    
    completionHandler(NSURLSessionAuthChallengeUseCredential,card);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        [ws ae_Session:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    });
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        [ws ae_Session:session dataTask:dataTask didReceiveData:data];
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDataTask *)dataTask didCompleteWithError:(NSError *)error {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        [ws ae_Session:session task:dataTask didCompleteWithError:error];
    });
}

#pragma mark - __NSURLSessionDataDelegate

- (void)ae_Session:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    [self fillContentInfo:response task:dataTask];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)ae_Session:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    BEResourceTaskModel* fragment = [self.requestBuffer objectForKey:dataTask];
    
    if (fragment) {
        
        [fragment.loadingRequest.dataRequest respondWithData:data];
        
        NSRange range = NSMakeRange(fragment.range.location + fragment.bufferOffset, data.length);
        
        [self cacheData:data range:range onComplete:nil];
        
        fragment.bufferOffset += data.length;
    }
}

- (void)ae_Session:(NSURLSession *)session task:(NSURLSessionDataTask *)dataTask didCompleteWithError:(NSError *)error {
    
    BEResourceTaskModel* fragment = [self.requestBuffer objectForKey:dataTask];
    
    if (fragment) {
        
        [fragment finishedWithError:error];
    }
    
    [self.requestBuffer removeObjectForKey:dataTask];
    
    if (self.requestBuffer.count == 0) {
        
        if (self.MediaRemoteTaskAllDidComplete) {
            
            self.MediaRemoteTaskAllDidComplete();
        }
    }
}

#pragma mark - Public

- (void)addRemoteTaskURL:(NSURL *)url range:(NSRange)range loadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest resourceLoaderIdentifier:(NSString *) resourceLoadingIdentifier {
    
    uint64_t location = range.location;
    
    uint64_t end = range.location + range.length - 1;
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];

    NSString* requestRange = [NSString stringWithFormat:@"bytes=%llu-%llu", location, end];
    
    [request setValue:requestRange forHTTPHeaderField:@"Range"];
    
    NSURLSessionDataTask* dataTask = [self.session dataTaskWithRequest:request];
    
    BEResourceTaskModel* fragment = [BEResourceTaskModel new];
    
    fragment.loadingRequest = loadingRequest;
    
    fragment.resourceLoaderIdentifier = resourceLoadingIdentifier;
    
    fragment.dataTask = dataTask;
    
    fragment.range = range;
    
    fragment.taskType = BETaskTypeRemote;
    
    [self.requestBuffer setObject:fragment forKey:dataTask];
    
    [fragment start];
}

- (void)cancelRemoteTaskForLoadingRequest:(nullable AVAssetResourceLoadingRequest *)loadingRequest orResourceLoaderIdentifier:(nullable NSString *)identifier {
    
    __weak typeof(self )ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        __strong typeof(ws) ss = ws;
        
        if (!ss) {
            
            return;
        }
        
        if (loadingRequest || identifier) {
            
            NSMutableArray* toCanceled = [NSMutableArray new];
            
            for (NSURLSessionDataTask* key in ws.requestBuffer) {
                
                BEResourceTaskModel* obj = ws.requestBuffer[key];
                
                if (loadingRequest == obj.loadingRequest && (identifier && [identifier isEqualToString:obj.resourceLoaderIdentifier])) {
                    
                    [obj cancel];
                    
                    [toCanceled addObject:obj.dataTask];

                    break;
                }
            }
            [self.requestBuffer removeObjectsForKeys:toCanceled];
        }else{
            
            for (NSURLSessionDataTask* key in ws.requestBuffer) {
                
                BEResourceTaskModel* obj = ws.requestBuffer[key];
                
                [obj cancel];
            }
            
            [ws.requestBuffer removeAllObjects];
            
            [ws.session finishTasksAndInvalidate];
        }
    });
    
    
}

#pragma mark - Internal

- (void)cacheData:(NSData *)data range:(NSRange )range onComplete:(void (^)(NSData *data, NSString *identifier, BEMCFlagType flag)) onComplete{
    
    if (self.cacheToDisk) {
        
        [[BECache share] updateData:data range:range identifier:self.remoteIdentifier totalLenght:_totalLength onComplete:onComplete];
    }
}

- (void)fillContentInfo:(NSURLResponse *)response task:(NSURLSessionDataTask* )dataTask {
    
    NSError* error = NULL;
    
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary:[BETool cacheInfoByResponse:response task:dataTask error:&error]];
    
    NSString* contentType = info[@"contentType"];
    
    long long contentLength = [info[@"contentLength"] longLongValue];
    
    BOOL byteRangeAccessSupported = [info[@"byteRangeAccessSupported"] boolValue];
    
    
    AVAssetResourceLoadingRequest* loadingRequest = [self.requestBuffer objectForKey:dataTask].loadingRequest;
    
    AVAssetResourceLoadingContentInformationRequest* contentInformationRequest = loadingRequest.contentInformationRequest;
    
    if (!contentInformationRequest.contentType) {
        
        contentInformationRequest.contentType = contentType;
        
        contentInformationRequest.contentLength = contentLength;
        
        contentInformationRequest.byteRangeAccessSupported = byteRangeAccessSupported;
        
        // 变更：只要有一个满足即认为支持 Range 请求
        if ((byteRangeAccessSupported || contentLength > 0) && _totalLength == -1) {
            
            [[BECache share] updateContentInfo:[info copy] identifier:self.remoteIdentifier onComplete:^(NSData *data, NSString *identifier, BEMCFlagType flag) {}];
        }
    }
    
    if (_totalLength == -1 && contentLength > 0) {
        
        _totalLength = contentLength;
        
        if (self.MediaRemoteTaskDidResponse) {
            
            self.MediaRemoteTaskDidResponse([info copy]);
        }
    }
}
@end
