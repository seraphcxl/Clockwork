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
typedef void (^DCCDSMOCConfigureBlock)(NSManagedObjectContext *moc, BOOL *stop);
typedef void (^DCCDSMOCActionBlock)(NSManagedObjectModel *model, NSManagedObjectContext *moc, BOOL *stop);

@class DCCoreDataStore;

@interface DCCoreDataStore : NSObject {
}

@property (nonatomic, copy) DCCDSQueryPSCURLBlock queryPSCURLBlock;
@property (nonatomic, copy) DCCDSConfigureEntityBlock configureEntityBlock;
@property (nonatomic, SAFE_ARC_PROP_STRONG, readonly) NSManagedObjectContext *mainManagedObjectContext;

- (id)initWithQueryPSCURLBlock:(DCCDSQueryPSCURLBlock)aQueryPSCURLBlock andConfigureEntityBlock:(DCCDSConfigureEntityBlock)aConfigureEntityBlock;
- (NSString *)urlString;
- (int)saveMainManagedObjectContext;

- (int)syncAction:(DCCDSMOCActionBlock)aMOCActionBlock withConfigureBlock:(DCCDSMOCConfigureBlock)aMOCConfigureBlock;
- (int)asyncAction:(DCCDSMOCActionBlock)aMOCActionBlock withConfigureBlock:(DCCDSMOCConfigureBlock)aMOCConfigureBlock;

@end
