//
//  BEDownloaderTask.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEDownloaderTask.h"
#import "BEDownloaderTaskModel.h"
#import "../BETool.h"
#import "../Cache/BECache.h"
#import "../BEResourceLoaderConstants.h"


#define D2T(date) ([date timeIntervalSince1970])

static NSDictionary* ntMap;

@interface BEDownloaderTask ()
{
    NSUInteger _bufferLimitSize;
    
    NSMutableData* _dataBuffer;
    
    unsigned long long _offset;
}
@property(nonatomic, strong) NSURLSession* session;

@property(nonatomic, strong) NSMutableArray<NSURLSessionDataTask *>* taskBuffer;

@end

@implementation BEDownloaderTask

- (void)dealloc {
    
//    _taskFinishedBlock = nil;
    
    _model = nil;
    
//    printf("%s\n", __func__);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        if (!ntMap) {
            
            ntMap = @{
                @"tls_version":@{
                        @(tls_protocol_version_TLSv10):@"TLS 1.0",
                        @(tls_protocol_version_TLSv11):@"TLS 1.1",
                        @(tls_protocol_version_TLSv12):@"TLS 1.2",
                        @(tls_protocol_version_TLSv13):@"TLS 1.3",
                        @(tls_protocol_version_DTLSv10):@"DTLS 1.0",
                        @(tls_protocol_version_DTLSv12):@"DTLS 1.2"
                },
                @"tls_suite":@{
                        @(tls_ciphersuite_RSA_WITH_3DES_EDE_CBC_SHA):@"RSA_3DES_EDE_CBC_SHA",
                        @(tls_ciphersuite_RSA_WITH_AES_128_CBC_SHA):@"RSA_AES_128_CBC_SHA",
                        @(tls_ciphersuite_RSA_WITH_AES_256_CBC_SHA):@"RSA_AES_256_CBC_SHA",
                        @(tls_ciphersuite_RSA_WITH_AES_128_GCM_SHA256):@"RSA_AES_128_GCM_SHA256",
                        @(tls_ciphersuite_RSA_WITH_AES_256_GCM_SHA384):@"RSA_AES_256_GCM_SHA384",
                        @(tls_ciphersuite_RSA_WITH_AES_128_CBC_SHA256):@"RSA_AES_128_CBC_SHA256",
                        @(tls_ciphersuite_RSA_WITH_AES_256_CBC_SHA256):@"RSA_AES_256_CBC_SHA256",
                        @(tls_ciphersuite_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA):@"ECDHE_ECDSA_3DES_EDE_CBC_SHA",
                        @(tls_ciphersuite_ECDHE_ECDSA_WITH_AES_128_CBC_SHA):@"ECDHE_ECDSA_AES_128_CBC_SHA",
                        @(tls_ciphersuite_ECDHE_ECDSA_WITH_AES_256_CBC_SHA):@"ECDHE_ECDSA_AES_256_CBC_SHA",
                        @(tls_ciphersuite_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA):@"ECDHE_RSA_3DES_EDE_CBC_SHA",
                        @(tls_ciphersuite_ECDHE_RSA_WITH_AES_128_CBC_SHA):@"ECDHE_RSA_AES_128_CBC_SHA",
                        @(tls_ciphersuite_ECDHE_RSA_WITH_AES_256_CBC_SHA):@"ECDHE_RSA_AES_256_CBC_SHA",
                        @(tls_ciphersuite_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256):@"ECDHE_ECDSA_AES_128_CBC_SHA256",
                        @(tls_ciphersuite_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384):@"ECDHE_ECDSA_AES_256_CBC_SHA384",
                        @(tls_ciphersuite_ECDHE_RSA_WITH_AES_128_CBC_SHA256):@"ECDHE_RSA_AES_128_CBC_SHA256",
                        @(tls_ciphersuite_ECDHE_RSA_WITH_AES_256_CBC_SHA384):@"ECDHE_RSA_AES_256_CBC_SHA384",
                        @(tls_ciphersuite_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256):@"ECDHE_ECDSA_AES_128_GCM_SHA256",
                        @(tls_ciphersuite_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384):@"ECDHE_ECDSA_AES_256_GCM_SHA384",
                        @(tls_ciphersuite_ECDHE_RSA_WITH_AES_128_GCM_SHA256):@"ECDHE_RSA_AES_128_GCM_SHA256",
                        @(tls_ciphersuite_ECDHE_RSA_WITH_AES_256_GCM_SHA384):@"ECDHE_RSA_AES_256_GCM_SHA384",
                        @(tls_ciphersuite_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256):@"ECDHE_RSA_CHACHA20_POLY1305_SHA256",
                        @(tls_ciphersuite_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256):@"ECDHE_ECDSA_CHACHA20_POLY1305_SHA256",
                        @(tls_ciphersuite_AES_128_GCM_SHA256):@"AES_128_GCM_SHA256",
                        @(tls_ciphersuite_AES_256_GCM_SHA384):@"AES_256_GCM_SHA384",
                        @(tls_ciphersuite_CHACHA20_POLY1305_SHA256):@"CHACHA20_POLY1305_SHA256"
                },
                @"fetch_type":@{
                        @(0):@"Unknown",
                        @(1):@"NetworkLoad",
                        @(2):@"ServerPush",
                        @(3):@"LocalCache"
                },
                @"dns_protocol":@{
                        @0:@"Unknown",
                        @1:@"UDP",
                        @2:@"TCP",
                        @3:@"TLS",
                        @4:@"HTTPS"
                }
            };
        }
        _bufferLimitSize = 3 * 1024;
        
        _offset = 0;
        
        _dataBuffer = [NSMutableData new];
        
        _taskBuffer = [NSMutableArray new];
        
        _model = [BEDownloaderTaskModel new];
    }
    return self;
}


- (void)start {
    
    if (self.model.status == BEDownloaderTaskStatusRunning || self.model.status == BEDownloaderTaskStatusFinished || self.model.status == BEDownloaderTaskStatusCancelled) {
        
        return;
    }
    self.model.status = BEDownloaderTaskStatusRunning;
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(SerialQueue(), ^{
        
        [weakSelf scheduleTask];
    });
}

- (void)cancel {
    
    if (self.model.status == BEDownloaderTaskStatusRunning) {
        
        [self.session invalidateAndCancel];
        
        _session = nil;
        
    }else{
        
        [self taskFinishedWithKey:self.model.key path:nil error:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:@{}]];
    }
}

- (void)scheduleTask {
    
    __weak typeof(self) ws = self;
    
    [[BECache share] queryCacheRanges:self.model.key onComplete:^(unsigned long long totalLenght, NSArray *loadedRanges, NSArray *pendingRanges, NSDictionary* info) {
        
        BEDownloaderTask* ss = ws;
        
        ss.model.localPath = [BECache pathForKey:ss.model.key extension:info[@"extension"]?:@""];
        
        ss.model.totalLength = totalLenght;
        
        if (!loadedRanges && ss.model.totalLength == 0) {//无缓存数据
            
            //只请求2字节，取文件信息
            [[ss taskForRange:NSMakeRange(0, 2)] resume];
            
        }else if (pendingRanges.count > 0) {//有缓存数据，且待下载数据不为空
            
            for (NSValue* obj in loadedRanges) {
                
                NSRange range = [obj rangeValue];
                
                ss.model.loadedLength += range.length;
            }
            
            for (int i = 0; i < pendingRanges.count; i++) {
                
                NSRange range = [pendingRanges[i] rangeValue];
                
                NSUInteger destination = range.location+range.length;
                
                unsigned long long limitLenght = ss.model.expectedPercent * totalLenght;
                
                if (limitLenght >= destination) {

                    [ss.taskBuffer addObject:[ss taskForRange:range]];
                }else{
                    
                    [ss.taskBuffer addObject:[ss taskForRange:NSMakeRange(range.location, limitLenght - range.location)]];
                    
                    break;
                }
            }
            [self tryNextDataTask];
            
        } else{//全部下载完成
            
            [ss taskFinishedWithKey:ss.model.key path:ss.model.localPath error:nil];
        }
    }];
}

#pragma mark - SET/GET

- (NSURLSession *)session {
    
    if (!_session) {
        
        NSURLSessionConfiguration* cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        static NSOperationQueue* delegateQueue;
        
        if (!delegateQueue) {
            
            delegateQueue = [[NSOperationQueue alloc] init];
            
            delegateQueue.name = @"BEDownloaderTaskSessionDelegateQueue";
            
            delegateQueue.maxConcurrentOperationCount = 1;
        }
        
        _session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:delegateQueue];
    }
    return _session;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    
    NSURLCredential *card = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential,card);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        [ws aeSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    });
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        [ws aeSession:session dataTask:dataTask didReceiveData:data];
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics  API_AVAILABLE(ios(10.0)){
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        [ws aeSession:session task:task didFinishCollectingMetrics:metrics];
    });
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDataTask *)dataTask didCompleteWithError:(NSError *)error {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        [ws aeSession:session task:dataTask didCompleteWithError:error];
    });
}

#pragma mark - NSURLSessionDataDelegate Invoke
- (void)aeSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    if (self.model.totalLength == 0) {
        
        __weak typeof(self) ws = self;
        
        [self fillContentInfo:response task:dataTask onComplete:^(NSInteger code, NSString* msg) {
            
            if (code == 0) {
                
                [ws scheduleTask];
            }else{
                
                NSError* error = [NSError errorWithDomain:NSURLErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:msg}];
                
                [ws taskFinishedWithKey:self.model.key path:nil error:error];
            }
        }];
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)aeSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    [self.model.taskDesc newDataLength:data.length];
    
    NSRange requestRange = [BETool rangeOfRequest:dataTask.currentRequest];
    
    if (requestRange.location == 0 && requestRange.length == 2) { return; }
    
    [_dataBuffer appendData:data];
    
    if (_dataBuffer.length > _bufferLimitSize) {
        
        @autoreleasepool {
            
            NSRange range = NSMakeRange(0, _dataBuffer.length);
            
            NSData* data = [_dataBuffer subdataWithRange:range];
            
            [_dataBuffer replaceBytesInRange:range withBytes:NULL length:0];
            
            if (requestRange.location != NSNotFound) {
                
                [[BECache share] updateData:data range:NSMakeRange(requestRange.location + _offset, range.length) identifier:self.model.key totalLenght:self.model.totalLength onComplete:^(NSData * _Nullable data, NSString * _Nullable identifier, BEMCFlagType flag) {
                    //TODO:
//                    printf("write finish\n");
                }];
                
                _offset += range.length;
                
                self.model.loadedLength += range.length;
                
                if (self.model.progressBlock) {
                    
                    self.model.progressBlock(self.model.key, self.model.url, self.model.loadedLength, self.model.totalLength);
                }
            }
        }
    }
}

- (void)aeSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics  API_AVAILABLE(ios(10.0)){
    
    NSURLSessionTaskTransactionMetrics* metric = metrics.transactionMetrics.lastObject;
    
    NSMutableDictionary* result = [NSMutableDictionary new];
    
    [result setValue:self.model.url forKey:@"url"];
    
    [result setValue:[(NSHTTPURLResponse *)metric.response allHeaderFields][@"Content-Length"] forKey:@"length"];
    
    [result setValue:@([(NSHTTPURLResponse *)metric.response statusCode]) forKey:@"code"];
    
    [result setValue:NSStringFromRange([BETool rangeOfResponse:metric.response]) forKey:@"range"];
    
    [result setValue:@(metrics.redirectCount) forKey:@"redirect"];
    
    [result setValue:[NSString stringWithFormat:@"%.0f",metrics.taskInterval.duration*1000] forKey:@"duration"];
    
    [result setValue:[NSString stringWithFormat:@"%.0f",D2T(metric.fetchStartDate)*1000] forKey:@"ts"];
    
    [result setValue:[NSString stringWithFormat:@"%.2f", (D2T(metric.domainLookupEndDate) - D2T(metric.domainLookupStartDate))*1000] forKey:@"lookup"];
    
    [result setValue:[NSString stringWithFormat:@"%.2f",(D2T(metric.connectEndDate) - D2T(metric.connectStartDate))*1000] forKey:@"connect"];
    
    [result setValue:[NSString stringWithFormat:@"%.2f",(D2T(metric.secureConnectionEndDate) - D2T(metric.secureConnectionStartDate))*1000] forKey:@"secure_connect"];
    
    [result setValue:[NSString stringWithFormat:@"%.2f",(D2T(metric.requestEndDate) - D2T(metric.requestStartDate))*1000] forKey:@"req"];
    
    [result setValue:[NSString stringWithFormat:@"%.2f",(D2T(metric.responseEndDate) - D2T(metric.responseStartDate))*1000] forKey:@"resp"];
    
    [result setValue:metric.networkProtocolName forKey:@"protocol"];
    
    [result setValue:ntMap[@"fetch_type"][@(metric.resourceFetchType)]?:@(metric.resourceFetchType) forKey:@"fetch_type"];
    
    [result setValue:@(metric.isProxyConnection) forKey:@"proxy"];
    
    [result setValue:@(metric.isReusedConnection) forKey:@"reused"];
    
    if (@available(iOS 13.0, *)) {
        
        [result setValue:@(metric.countOfRequestHeaderBytesSent) forKey:@"req_header"];
        
        [result setValue:@(metric.countOfRequestBodyBytesBeforeEncoding) forKey:@"req_body_len"];
        
        [result setValue:@(metric.countOfRequestBodyBytesSent) forKey:@"req_body_sent"];
        
        [result setValue:@(metric.countOfResponseHeaderBytesReceived) forKey:@"resp_header"];
        
        [result setValue:@(metric.countOfResponseBodyBytesAfterDecoding) forKey:@"resp_body_len"];
        
        [result setValue:@(metric.countOfResponseBodyBytesReceived) forKey:@"resp_body_recv"];
        
        [result setValue:ntMap[@"tls_suite"][metric.negotiatedTLSCipherSuite]?:metric.negotiatedTLSCipherSuite forKey:@"tls_suite"];
        
        [result setValue:ntMap[@"tls_version"][metric.negotiatedTLSProtocolVersion]?:metric.negotiatedTLSProtocolVersion forKey:@"tls_version"];
        
        [result setValue:@(metric.cellular) forKey:@"cellular"];
        
        [result setValue:@(metric.expensive) forKey:@"expensive"];
        
        [result setValue:@(metric.isConstrained) forKey:@"constrained"];
        
        [result setValue:@(metric.multipath) forKey:@"multipath"];
        
        [result setValue:[NSString stringWithFormat:@"%@:%@",metric.remoteAddress, metric.remotePort] forKey:@"remote_addr"];
        
        [result setValue:[NSString stringWithFormat:@"%@:%@",metric.localAddress, metric.localPort] forKey:@"local_addr"];
    }
    
    if (@available(iOS 14.0, *)) {
        
        [result setValue:ntMap[@"dns_protocol"][@(metric.domainResolutionProtocol)]?:@(metric.domainResolutionProtocol) forKey:@"dns_protocol"];
    }
    [self.model.taskDesc.networkMetrics addObject:result];
    
//    NSMutableDictionary* info = [NSMutableDictionary new];
//
//    [info setValue:self.model.url forKey:@"url"];
//
//    [info setValue:metric.request.URL.absoluteString forKey:@"reqUrl"];
//
//    [info setValue:metric.response.URL.absoluteString forKey:@"respUrl"];
//
//    [info setValue:[(NSHTTPURLResponse *)metric.response allHeaderFields][@"Content-Length"] forKey:@"contentLength"];
//
//    [info setValue:@(metrics.redirectCount) forKey:@"redirectCount"];
//
//    [info setValue:@(metrics.taskInterval.duration) forKey:@"taskInterval"];
//
//    [info setValue:@(D2T(metric.fetchStartDate)) forKey:@"fetchStart"];
//
//    [info setValue:@(D2T(metric.domainLookupStartDate)) forKey:@"domainLookupStart"];
//    [info setValue:@(D2T(metric.domainLookupEndDate)) forKey:@"domainLookupEnd"];
//
//    [info setValue:@(D2T(metric.connectStartDate)) forKey:@"connectStart"];
//    [info setValue:@(D2T(metric.connectEndDate)) forKey:@"connectEnd"];
//
//    [info setValue:@(D2T(metric.secureConnectionStartDate)) forKey:@"secureConnectionStart"];
//    [info setValue:@(D2T(metric.secureConnectionEndDate)) forKey:@"secureConnectionEnd"];
//
//    [info setValue:@(D2T(metric.requestStartDate)) forKey:@"requestStart"];
//    [info setValue:@(D2T(metric.requestEndDate)) forKey:@"requestEndDate"];
//
//    [info setValue:@(D2T(metric.responseStartDate)) forKey:@"responseStart"];
//    [info setValue:@(D2T(metric.responseEndDate)) forKey:@"responseEnd"];
//
//    [info setValue:metric.networkProtocolName?:@"-" forKey:@"networkProtocolName"];
//
//    [info setValue:@(metric.resourceFetchType) forKey:@"resourceFetchType"];
//
//    [info setValue:@(metric.isProxyConnection) forKey:@"proxyConnection"];
//
//    [info setValue:@(metric.isReusedConnection) forKey:@"reusedConnection"];
//
//    if (@available(iOS 13.0, *)) {
//
//        [info setValue:@(metric.countOfRequestHeaderBytesSent) forKey:@"countOfRequestHeaderBytesSent"];
//        [info setValue:@(metric.countOfResponseHeaderBytesReceived) forKey:@"countOfResponseHeaderBytesReceived"];
//
//        [info setValue:@(metric.countOfRequestBodyBytesSent) forKey:@"countOfRequestBodyBytesSent"];
//        [info setValue:@(metric.countOfResponseBodyBytesReceived) forKey:@"countOfResponseBodyBytesReceived"];
//
//        [info setValue:metric.localAddress forKey:@"localAddress"];
//        [info setValue:metric.remoteAddress forKey:@"remoteAddress"];
//
//        [info setValue:metric.negotiatedTLSProtocolVersion forKey:@"negotiatedTLSProtocolVersion"];
//        [info setValue:metric.negotiatedTLSCipherSuite forKey:@"negotiatedTLSCipherSuite"];
//
//        [info setValue:@(metric.cellular) forKey:@"cellular"];
//
//        [info setValue:@(metric.expensive) forKey:@"expensive"];
//
//        [info setValue:@(metric.isConstrained) forKey:@"constrained"];
//
//        [info setValue:@(metric.multipath) forKey:@"multipath"];
//    }
//    if (@available(iOS 14.0, *)) {
//        [info setValue:@(metric.domainResolutionProtocol) forKey:@"domainResolutionProtocol"];
//    }
    
    
    
}

- (void)aeSession:(NSURLSession *)session task:(NSURLSessionDataTask *)dataTask didCompleteWithError:(NSError *)error {
    
    NSRange requestRange = [BETool rangeOfRequest:dataTask.currentRequest];
    
    NSInteger responseCode = [(NSHTTPURLResponse* )dataTask.response statusCode];
    
    if (responseCode >= 300) {
        
        if (!error) {
            
            error = [NSError errorWithDomain:NSURLErrorDomain code:responseCode userInfo:@{NSURLLocalizedTypeDescriptionKey:@"response exception"}];
        }
    }
    
    if (requestRange.location == 0 && requestRange.length == 2) {//标记
        
        if (error) {

            [self taskFinishedWithKey:self.model.key path:nil error:error];
        }
    }else {
        
        if(_dataBuffer.length > 0 && !error) {
            
            @autoreleasepool {
                
                NSRange range = NSMakeRange(0, _dataBuffer.length);
                
                NSData* data = [_dataBuffer subdataWithRange:range];
                
                [_dataBuffer replaceBytesInRange:range withBytes:NULL length:0];
                
                if (requestRange.location != NSNotFound) {
                    
                    [[BECache share] updateData:data range:NSMakeRange(requestRange.location + _offset, range.length) identifier:self.model.key totalLenght:self.model.totalLength onComplete:nil];
                    
                    self.model.loadedLength += range.length;
                }
                if (self.model.progressBlock) {
                    
                    self.model.progressBlock(self.model.key, self.model.url, self.model.loadedLength + range.length, self.model.totalLength);
                }
            }
        }
        
        _offset = 0;
        
        [self.taskBuffer removeObjectAtIndex:0];
        
        if (error) {
            
            [self taskFinishedWithKey:self.model.key path:nil error:error];
        }else{
            
            [self tryNextDataTask];
        }
    }
}



#pragma mark - Internal

- (void)tryNextDataTask {
    
    if (self.taskBuffer.count) {
        
        NSURLSessionDataTask* dataTask = [self.taskBuffer firstObject];
        
        if (dataTask.state == NSURLSessionTaskStateRunning) { return; }
        
        [dataTask resume];
    }else{
        
        [self taskFinishedWithKey:self.model.key path:self.model.localPath error:nil];
    }
}

- (NSURLSessionDataTask *)taskForRange:(NSRange )range {
    
    NSUInteger begin = range.location;
    
    NSUInteger end = range.location + range.length - 1;
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.model.url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
    
    NSString* requestRange = [NSString stringWithFormat:@"bytes=%llu-%llu", (unsigned long long)begin, (unsigned long long)end];
    
    [request setValue:requestRange forHTTPHeaderField:@"Range"];
    
    NSURLSessionDataTask* dataTask = [self.session dataTaskWithRequest:request];
    
    return dataTask;
}

- (void )fillContentInfo:(NSURLResponse *)response task:(NSURLSessionDataTask *)task onComplete:(void (^)(NSInteger code, NSString* msg))onComplete {
    
    NSError* error = NULL;
    
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary:[BETool cacheInfoByResponse:response task:task error:&error]];
    
    if (error) {
        
        if (onComplete) {
            
            onComplete(error.code, error.localizedDescription);
        }
    }else{
        
        if (self.model.groupName.length > 0) {
            
            [info setValue:self.model.groupName forKey:@"group"];
        }
        
        [[BECache share] updateContentInfo:[info copy] identifier:self.model.key onComplete:^(NSData * _Nullable data, NSString * _Nullable identifier, BEMCFlagType flag) {
            
            if (onComplete) {
                
                onComplete(flag, @"ok");
            }
        }];
    }
}

//结束所有请求
- (void)taskFinishedWithKey:(NSString *)key path:(NSString *)path error:(NSError *)error {
    
    self.model.error = error;
    
    for (NSURLSessionDataTask* obj in self.taskBuffer) {
        
        if (obj.state < NSURLSessionTaskStateCanceling) {
            
            [obj cancel];
        }
    }
    if (error.code == NSURLErrorCancelled) {

        [self.session invalidateAndCancel];
        
        self.model.status = BEDownloaderTaskStatusCancelled;
    }else{
        
        [self.session finishTasksAndInvalidate];
        
        self.model.status = BEDownloaderTaskStatusFinished;
    }

    _session = nil;
    
    if (self.model.finishedBlock) {
        
        NSDictionary* metric = @{@"metric":[self.model.taskDesc.metric copy], @"metricDetail":[self.model.taskDesc.networkMetrics copy]};
        
        self.model.finishedBlock(key, self.model.url, path, metric, error);
    }
    
    [_taskBuffer removeAllObjects];
    
    _taskBuffer = nil;
}

@end
