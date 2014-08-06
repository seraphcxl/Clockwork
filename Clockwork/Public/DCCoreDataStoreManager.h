//
//  DCCoreDataStoreManager.h
//  Clockwork
//
//  Created by Derek Chen on 13-9-25.
//  Copyright (c) 2013年 CaptainSolid Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Tourbillon/DCTourbillon.h"

@class DCCoreDataStore;

@interface DCCoreDataStoreManager : NSObject {
}

@property (nonatomic, SAFE_ARC_PROP_STRONG, readonly) NSMutableDictionary *dataStorePool;  // key:(NSString *) value:(DCCoreDataStore *)

DEFINE_SINGLETON_FOR_HEADER(DCCoreDataStoreManager)

- (void)addDataStore:(DCCoreDataStore *)aDataStore;
- (void)removeDataStore:(DCCoreDataStore *)aDataStore;
- (void)removeAllDataStores;
- (DCCoreDataStore *)getDataSource:(NSString *)aURLString;
- (void)saveAllDataStores;

@end
