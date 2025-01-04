//
//  BEResourceTaskModel.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/2.
//

#import "BEResourceTaskModel.h"

@implementation BEResourceTaskModel

- (void)dealloc{
    
    printf("%s\n", __func__);
}
- (instancetype)init {
    
    if (self = [super init]) {
        
        _dataBuffer = [NSMutableData new];
        
        _bufferLimitSize = 1024*1024;
        
        _status = BEResourceTaskStatusPending;
    }
    return self;
}

- (void)setStatus:(BEResourceTaskStatus)status {
    
    if (_status == status) {
        
        return;
    }
    _status = status;
    
    switch (status) {
        case BEResourceTaskStatusPending:
            
            break;
        case BEResourceTaskStatusRunning:
        {
            [self.dataTask resume];
        }
            break;
            
        case BEResourceTaskStatusSuspend:
        {
            [self.dataTask suspend];
        }
            break;
        case BEResourceTaskStatusCancelled:
        {
            [self.dataTask cancel];
        }
            break;
        case BEResourceTaskStatusCompleted:
            
            break;
            
        default:
            break;
    }
}

- (void)start {
    
    if (self.taskType == BETaskTypeRemote) {
        
        if (self.dataTask.state != NSURLSessionTaskStateRunning) {
            
            [self.dataTask resume];
        }
    }
    
    self.status = BEResourceTaskStatusRunning;
}

- (void)cancel {
    
    if (self.taskType == BETaskTypeRemote) {
        
        [self.dataTask cancel];
    }else{
        
    }
    
    self.status = BEResourceTaskStatusCancelled;
}

- (void)finishedWithError:(NSError *)error {
    
    if (self.taskType == BETaskTypeRemote) {
        
        if (error) {
            
            [self.loadingRequest finishLoadingWithError:error];
        }else{
            
            [self.loadingRequest finishLoading];
        }
    }
    
    self.status = error.code == NSURLErrorCancelled ? BEResourceTaskStatusCancelled : BEResourceTaskStatusCompleted;
    
    _bufferOffset = 0;
    
    _dataBuffer = nil;
    
    _dataTask = nil;
    
    _loadingRequest = nil;
}

@end
