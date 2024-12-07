//
//  Header.h
//  BEPlayer
//
//  Created by bluegg on 2024/12/3.
//

#ifndef Header_h
#define Header_h


#define BE_Resource_Loader_Version @"0.1.0"

#define DEFAULT_GROUP @"default_0x000000017026ff80"

static NSString* _Nonnull MediaCacheWorkRootPath = @"MediaCache";

static uint64_t MiniDiskSpace = 1024*1024*1024;//1G

typedef NS_ENUM(NSInteger, BEMCFlagType) {
    BEMCFlagTypeSuccess = 0,
    BEMCFlagTypeNotEnoughSpace = 100,
    BEMCFlagTypeCreateFileFailed,
    BEMCFlagTypeReadFailed,
    BEMCFlagTypeReadNothing,
    BEMCFlagTypeWriteFailed,
    BEMCFlagTypeWriteExisted
};

typedef NS_ENUM(NSUInteger, BECacheAction) {
    BECacheActionNone,
    BECacheActionRead,
    BECacheActionReadRanges,
    BECacheActionWrite,
    BECacheActionWriteInfo
};

#endif /* Header_h */
