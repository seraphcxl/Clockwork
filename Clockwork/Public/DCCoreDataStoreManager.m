//
//  DCCoreDataStoreManager.m
//  Clockwork
//
//  Created by Derek Chen on 13-9-25.
//  Copyright (c) 2013年 CaptainSolid Studio. All rights reserved.
//

#import "DCCoreDataStoreManager.h"
#import "DCCoreDataStore.h"

@interface DCCoreDataStoreManager () {
}

@property (nonatomic, strong) NSMutableDictionary *dataStorePool;  // key:(NSString *) value:(DCCoreDataStore *)

- (void)cleanDataStorePool;

@end

@implementation DCCoreDataStoreManager
#pragma mark - DCDataStoreManager - Public method
@synthesize dataStorePool = _dataStorePool;
DEFINE_SINGLETON_FOR_CLASS(DCCoreDataStoreManager)

- (id)init {
    @synchronized(self) {
        self = [super init];
        if (self) {
            [self cleanDataStorePool];
            
            self.dataStorePool = [[NSMutableDictionary dictionary] threadSafe_init];
        }
        return self;
    }
}

- (void)dealloc {
    do {
        @synchronized(self) {
            [self cleanDataStorePool];
        }
        SAFE_ARC_SUPER_DEALLOC();
    } while (NO);
}

- (void)addDataStore:(DCCoreDataStore *)aDataStore {
    do {
        if (!aDataStore || !_dataStorePool) {
            break;
        }
        [_dataStorePool threadSafe_setObject:aDataStore forKey:[aDataStore urlString]];
    } while (NO);
}

- (void)removeDataStore:(DCCoreDataStore *)aDataStore {
    do {
        if (!aDataStore || !_dataStorePool) {
            break;
        }
        
        [aDataStore resign];
        
        [_dataStorePool threadSafe_removeObjectForKey:[aDataStore urlString]];
    } while (NO);
}

- (void)removeDataStoreByURL:(NSString *)aURL {
    do {
        if (!aURL || !_dataStorePool) {
            break;
        }
        
        DCCoreDataStore *store = [self getDataSource:aURL];
        [store resign];
        
        [_dataStorePool threadSafe_removeObjectForKey:aURL];
    } while (NO);
}

- (void)removeAllDataStores {
    do {
        if (!_dataStorePool) {
            break;
        }
        
        [self saveAllDataStoresInMainThread];
        
        NSArray *allDataStores = [_dataStorePool threadSafe_allValues];
        for (DCCoreDataStore *dataStore in allDataStores) {
            [dataStore resign];
        }
        
        [_dataStorePool threadSafe_removeAllObjects];
    } while (NO);
}

- (DCCoreDataStore *)getDataSource:(NSString *)aURLString {
    DCCoreDataStore *result = nil;
    do {
        if (!aURLString || !_dataStorePool) {
            break;
        }
        result = [_dataStorePool threadSafe_objectForKey:aURLString];
    } while (NO);
    return result;
}

- (void)saveAllDataStoresInMainThread {
    do {
        if (!_dataStorePool) {
            break;
        }
        
        if (![NSThread isMainThread]) {
            break;
        }
        
        NSArray *allDataStores = [_dataStorePool threadSafe_allValues];
        for (DCCoreDataStore *dataStore in allDataStores) {
            [dataStore saveManagedObjectContext];
        }
    } while (NO);
}

#pragma mark - DCDataStoreManager - Private method
- (void)cleanDataStorePool {
    do {
        @synchronized(self) {
            if (_dataStorePool) {
                [self removeAllDataStores];
                self.dataStorePool = nil;
            }
        }
    } while (NO);
}

@end
