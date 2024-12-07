//
//  BEResourceLoader.m
//  BEPlayer
//
//  Created by bluegg on 2024/12/3.
//

#import "BEResourceLoader.h"
#import "Task/BEResourceTask.h"
#import "BETool.h"

static NSString* kBECacheScheme = @"BECachescheme";

@interface BEResourceLoader ()<BEResourceTaskDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, BEResourceTask* >* loadingTasks;

@end

@implementation BEResourceLoader

static dispatch_once_t onceToken;

+ (instancetype)share {

    __weak static BEResourceLoader *instance;
    
    __block BEResourceLoader *strongInstance = instance;

    dispatch_once(&onceToken, ^{
       
        if (!strongInstance) {
            
            strongInstance = [BEResourceLoader new];
            
            instance = strongInstance;
        }
    });
    return strongInstance;
}


- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BECache_clean_cache" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BECache_cleanAll" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BEPlayerWillPlayNewItem" object:nil];
    
    _loadingTasks = nil;
    
    onceToken = 0;
    
    printf("%s\n", __func__);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _loadingTasks = [NSMutableDictionary new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAndCleanCache:) name:@"BECache_clean_cache" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAndCleanCache:) name:@"BECache_cleanAll" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willPlayNewItem:) name:@"BEPlayerWillPlayNewItem" object:nil];
    }
    return self;
}

- (void)cancelAndCleanCache:(NSNotification *)notify {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        if (notify.object) {
            
            NSString* key = notify.object[@"identifier"];
            
            BEResourceTask* task = ws.loadingTasks[key];
            
            if (task.isIdle) {
                
                [task cancelRequest:nil forResourceLoaderIdentifier:nil];
                
                [ws.loadingTasks removeObjectForKey:key];
            }
        }else{
            
            for (NSString* key in self.loadingTasks.allKeys) {
                
                BEResourceTask* task = ws.loadingTasks[key];
                
                [task cancelRequest:nil forResourceLoaderIdentifier:nil];
            }
            [ws.loadingTasks removeAllObjects];
        }
        //无取消返回，暂时直接调用
        void (^onCanceled)(void) = (void(^)(void))notify.object[@"onCanceled"] ? : ^{};
        
        onCanceled();
    });
}

- (void)willPlayNewItem:(NSNotification *)notify {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        NSDictionary* object = notify.object;
        
        NSString* oldUrl = object[@"oldUrl"];
        
        if (oldUrl) {
            
            NSString* key = [BETool md5:[ws fixScheme:[NSURL URLWithString:oldUrl]].absoluteString];
            
            BEResourceTask* task = ws.loadingTasks[key];
            
            [task cancelRequest:nil forResourceLoaderIdentifier:[NSString stringWithFormat:@"%p",object[@"oldResourceLoader"]]];
        }
    });
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    if (resourceLoader && loadingRequest.dataRequest && [loadingRequest.request.URL.absoluteString hasPrefix:kBECacheScheme]) {
        
        __weak typeof(self) ws = self;
        
        dispatch_async(SerialQueue(), ^{
            
            [ws ae_resourceLoader:resourceLoader shouldWaitForLoadingOfRequestedResource:loadingRequest];
        });
        
        return YES;
    }else{
        printf("resource loader something error\n");
    }
    return NO;
}

- (void)ae_resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    NSString* key = [BETool md5:[self fixScheme:loadingRequest.request.URL].absoluteString];
    
    BEResourceTask* task = self.loadingTasks[key];
    
    if (!task) {
        
        BEResourceTask* newTask = [[BEResourceTask alloc] init];
        
        newTask.delegate = self;
        
        newTask.identifier = key;
        
        newTask.isIdle = NO;
    
        self.loadingTasks[key] = newTask;
        
        task = newTask;
    }
    
    [task addRequest:loadingRequest forResourceLoaderIdentifier:[NSString stringWithFormat:@"%p",resourceLoader]];
}


- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    __weak typeof(self) ws = self;
    
    dispatch_async(SerialQueue(), ^{
        
        NSString* key = [BETool md5:[ws fixScheme:loadingRequest.request.URL].absoluteString];

        BEResourceTask* task = ws.loadingTasks[key];

        if (task) {

            [task cancelRequest:loadingRequest forResourceLoaderIdentifier:[NSString stringWithFormat:@"%p",resourceLoader]];
        }else{
            printf("resource loader cancel nil\n");
        }
    });
}

#pragma mark - BEResourceTaskDelegate

- (void)mediaResourceTaskFinished:(BEResourceTask *)task {
    
    [task cancelRequest:nil forResourceLoaderIdentifier:nil];
    
    task.isIdle = YES;
}

- (void)mediaResourceTaskSuspend:(BEResourceTask *)task{}

- (void)mediaResourceTaskCanceled:(BEResourceTask *)task {}

//替换协议
- (NSURL* )fixScheme:(NSURL *)url {
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    
    components.scheme = [components.scheme stringByReplacingOccurrencesOfString:@"BECachescheme" withString:@"http"];
    
    NSURL* httpURL = [components URL];
    
    return httpURL;
}
@end
