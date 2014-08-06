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
            
            _dataStorePool = [[NSMutableDictionary dictionary] threadSafe_init];
            SAFE_ARC_RETAIN(_dataStorePool);
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
        if (!aDataStore || !self.dataStorePool) {
            break;
        }
        [self.dataStorePool threadSafe_setObject:aDataStore forKey:[aDataStore urlString]];
    } while (NO);
}

- (void)removeDataStore:(DCCoreDataStore *)aDataStore {
    do {
        if (!aDataStore || !self.dataStorePool) {
            break;
        }
        [self.dataStorePool threadSafe_removeObjectForKey:[aDataStore urlString]];
    } while (NO);
}

- (void)removeAllDataStores {
    do {
        if (!self.dataStorePool) {
            break;
        }
        [self saveAllDataStores];
        
        [self.dataStorePool threadSafe_removeAllObjects];
    } while (NO);
}

- (DCCoreDataStore *)getDataSource:(NSString *)aURLString {
    DCCoreDataStore *result = nil;
    do {
        if (!aURLString || !self.dataStorePool) {
            break;
        }
        result = [self.dataStorePool threadSafe_objectForKey:aURLString];
    } while (NO);
    return result;
}

- (void)saveAllDataStores {
    do {
        if (!self.dataStorePool) {
            break;
        }
        NSArray *allDataStores = [self.dataStorePool threadSafe_allValues];
        for (DCCoreDataStore *dataStore in allDataStores) {
            [dataStore saveMainManagedObjectContext];
        }
    } while (NO);
}

#pragma mark - DCDataStoreManager - Private method
- (void)cleanDataStorePool {
    do {
        @synchronized(self) {
            if (_dataStorePool) {
                [self removeAllDataStores];
                SAFE_ARC_SAFERELEASE(_dataStorePool);
            }
        }
    } while (NO);
}

@end
