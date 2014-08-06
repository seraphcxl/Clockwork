//
//  DCCoreDataStore.m
//  Clockwork
//
//  Created by Derek Chen on 13-9-25.
//  Copyright (c) 2013年 CaptainSolid Studio. All rights reserved.
//

#import "DCCoreDataStore.h"

@interface DCCoreDataStore () {
}

@property (nonatomic, SAFE_ARC_PROP_STRONG) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, SAFE_ARC_PROP_STRONG) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)setupSaveNotification;
- (NSManagedObjectContext *)queryManagedObjectContextForCurrentThread;

@end

@implementation DCCoreDataStore
#pragma mark - DCCoreDataStore - Public Method
@synthesize queryPSCURLBlock = _queryPSCURLBlock;
@synthesize configureEntityBlock = _configureEntityBlock;
@synthesize mainManagedObjectContext = _mainManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (id)initWithQueryPSCURLBlock:(DCCDSQueryPSCURLBlock)aQueryPSCURLBlock andConfigureEntityBlock:(DCCDSConfigureEntityBlock)aConfigureEntityBlock {
    @synchronized(self) {
        if (aQueryPSCURLBlock == nil || aConfigureEntityBlock == nil) {
            return nil;
        }
        self = [super init];
        if (self) {
            self.queryPSCURLBlock = aQueryPSCURLBlock;
            self.configureEntityBlock = aConfigureEntityBlock;
            
            [self setupSaveNotification];
        }
        return self;
    }
}

- (void)dealloc {
    do {
        @synchronized(self) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
            
            SAFE_ARC_SAFERELEASE(_mainManagedObjectContext);
            SAFE_ARC_SAFERELEASE(_persistentStoreCoordinator);
            SAFE_ARC_SAFERELEASE(_managedObjectModel);
            
            self.queryPSCURLBlock = nil;
            self.configureEntityBlock = nil;
        }
        SAFE_ARC_SUPER_DEALLOC();
    } while (NO);
}

- (NSString *)urlString {
    NSString *result = nil;
    do {
        @synchronized(self) {
            if (self.queryPSCURLBlock) {
                result = [self.queryPSCURLBlock() absoluteString];
            }
        }
    } while (NO);
    return result;
}

- (int)saveMainManagedObjectContext {
    int result = -1;
    do {
        @synchronized(self) {
            NSError *err = nil;
            NSManagedObjectContext *moc = self.mainManagedObjectContext;
            if (moc != nil) {
                if ([moc hasChanges] && ![moc save:&err]) {
                    NSLog(@"mainManagedObjectContext save error %@, %@", [err localizedDescription], [err userInfo]);
                    abort();
                }
            }
        }
        result = 0;
    } while (NO);
    return result;
}

- (int)syncAction:(DCCDSMOCActionBlock)aMOCActionBlock withConfigureBlock:(DCCDSMOCConfigureBlock)aMOCConfigureBlock {
    int result = -1;
    do {
        NSManagedObjectContext *moc = [self queryManagedObjectContextForCurrentThread];
        if (moc == nil) {
            break;
        }
        __block BOOL stop = NO;
        if (moc != self.mainManagedObjectContext && aMOCConfigureBlock) {
            aMOCConfigureBlock(moc, &stop);
            if (stop) {
                break;
            }
        }
        [moc performBlockAndWait:^{
            @autoreleasepool {
                aMOCActionBlock(self.managedObjectModel, moc, &stop);
            }
        }];
        if (stop) {
            break;
        }
        result = 0;
    } while (NO);
    return result;
}

- (int)asyncAction:(DCCDSMOCActionBlock)aMOCActionBlock withConfigureBlock:(DCCDSMOCConfigureBlock)aMOCConfigureBlock {
    int result = -1;
    do {
        NSManagedObjectContext *moc = [self queryManagedObjectContextForCurrentThread];
        if (moc == nil) {
            break;
        }
        __block BOOL stop = NO;
        if (moc != self.mainManagedObjectContext && aMOCConfigureBlock) {
            aMOCConfigureBlock(moc, &stop);
            if (stop) {
                break;
            }
        }
        [moc performBlock:^{
            @autoreleasepool {
                aMOCActionBlock(self.managedObjectModel, moc, &stop);
            }
        }];
        if (stop) {
            break;
        }
        result = 0;
    } while (NO);
    return result;
}

- (NSManagedObjectContext *)mainManagedObjectContext {
    NSManagedObjectContext *result = nil;
    do {
        @synchronized(self) {
            if (_mainManagedObjectContext != nil) {
                result = _mainManagedObjectContext;
            } else {
                _mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                _mainManagedObjectContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
                result = _mainManagedObjectContext;
            }
        }
    } while (NO);
    return result;
}

- (NSManagedObjectModel *)managedObjectModel {
    NSManagedObjectModel *result = nil;
    do {
        @synchronized(self) {
            if (_managedObjectModel != nil) {
                result = _managedObjectModel;
            } else {
                _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
                SAFE_ARC_RETAIN(_managedObjectModel);
                if (self.configureEntityBlock) {
                    self.configureEntityBlock(_managedObjectModel);
                }
                result = _managedObjectModel;
            }
        }
    } while (NO);
    return result;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    NSPersistentStoreCoordinator *result = nil;
    do {
        @synchronized(self) {
            if (_persistentStoreCoordinator != nil) {
                result = _persistentStoreCoordinator;
            } else {
                NSURL *storeURL = nil;
                if (self.queryPSCURLBlock) {
                    storeURL = self.queryPSCURLBlock();
                }
                if (storeURL == nil) {
                    break;
                }
                NSError *err = nil;
                _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
                if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&err]) {
                    NSLog(@"PSC load error %@, %@", [err localizedDescription], [err userInfo]);
                    abort();
                }
                
                result = _persistentStoreCoordinator;
            }
        }
    } while (NO);
    return result;    
}

#pragma mark - DCCoreDataStore - Private Method
- (void)setupSaveNotification {
    do {
        @synchronized(self) {
            [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:nil queue:nil usingBlock:^(NSNotification* note) {
                NSManagedObjectContext *moc = self.mainManagedObjectContext;
                if (note.object != moc) {
                    [moc performBlock:^(){
                        [moc mergeChangesFromContextDidSaveNotification:note];
                    }];
                }
            }];
        }
    } while (NO);
}

- (NSManagedObjectContext *)queryManagedObjectContextForCurrentThread {
    NSManagedObjectContext *result = nil;
    do {
        @synchronized(self) {
            if ([[NSThread currentThread] isMainThread]) {
                result = self.mainManagedObjectContext;
            } else {
                result = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                result.persistentStoreCoordinator = self.persistentStoreCoordinator;
                SAFE_ARC_AUTORELEASE(result);
            }
        }
    } while (NO);
    return result;
}

@end
