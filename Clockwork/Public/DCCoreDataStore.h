//
//  DCCoreDataStore.h
//  Clockwork
//
//  Created by Derek Chen on 13-9-25.
//  Copyright (c) 2013年 CaptainSolid Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Tourbillon/DCTourbillon.h"

typedef NSURL *(^DCCDSQueryPSCURLBlock)(void);
typedef void (^DCCDSConfigureEntityBlock)(NSManagedObjectModel *aModel);
typedef void (^DCCDSMOCConfigureBlock)(NSManagedObjectContext *moc, NSError **err);
typedef void (^DCCDSMOCActionBlock)(NSManagedObjectModel *model, NSManagedObjectContext *moc, BOOL *shouldCacheContext, NSError **err);

@class DCCoreDataStore;

@interface DCCoreDataStore : NSObject {
}

@property (nonatomic, copy) DCCDSQueryPSCURLBlock queryPSCURLBlock;
@property (nonatomic, copy) DCCDSConfigureEntityBlock configureEntityBlock;
@property (nonatomic, strong, readonly) NSManagedObjectContext *mainManagedObjectContext;

- (id)initWithQueryPSCURLBlock:(DCCDSQueryPSCURLBlock)aQueryPSCURLBlock configureEntityBlock:(DCCDSConfigureEntityBlock)aConfigureEntityBlock andContextCacheLimit:(NSUInteger)contextCacheLimit;
- (NSString *)urlString;
- (int)saveManagedObjectContext;
- (void)resign;

- (int)syncAction:(DCCDSMOCActionBlock)aMOCActionBlock withConfigureBlock:(DCCDSMOCConfigureBlock)aMOCConfigureBlock;
- (int)asyncAction:(DCCDSMOCActionBlock)aMOCActionBlock withConfigureBlock:(DCCDSMOCConfigureBlock)aMOCConfigureBlock;

@end
