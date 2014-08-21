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
@property (nonatomic, strong) NSManagedObjectContext *mainManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) DCDictionaryCache *managedObjectContextCahce;

- (void)setupSaveNotification;
- (NSManagedObjectContext *)getManagedObjectContextForCurrentThread;
- (NSManagedObjectContext *)queryManagedObjectContextForCurrentThread;
- (void)cacheManagedObjectContext:(NSManagedObjectContext *)context forThread:(NSString *)threadID;

@end

@implementation DCCoreDataStore
#pragma mark - DCCoreDataStore - Public Method
@synthesize queryPSCURLBlock = _queryPSCURLBlock;
@synthesize configureEntityBlock = _configureEntityBlock;
@synthesize mainManagedObjectContext = _mainManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectContextCahce = _managedObjectContextCahce;

- (id)initWithQueryPSCURLBlock:(DCCDSQueryPSCURLBlock)aQueryPSCURLBlock configureEntityBlock:(DCCDSConfigureEntityBlock)aConfigureEntityBlock andContextCacheLimit:(NSUInteger)contextCacheLimit {
    if (aQueryPSCURLBlock == nil || aConfigureEntityBlock == nil) {
        return nil;
    }
    
    if (![NSThread isMainThread]) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.queryPSCURLBlock = aQueryPSCURLBlock;
        self.configureEntityBlock = aConfigureEntityBlock;
        
        self.managedObjectContextCahce = [[DCDictionaryCache alloc] initWithCountLimit:contextCacheLimit];
        
        self.managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
        if (_configureEntityBlock) {
            _configureEntityBlock(_managedObjectModel);
        }
        
        NSURL *storeURL = nil;
        if (_queryPSCURLBlock) {
            storeURL = _queryPSCURLBlock();
        }
        if (storeURL) {
            NSError *err = nil;
            self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
            if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&err]) {
                NSLog(@"PSC load error %@, %@", [err localizedDescription], [err userInfo]);
            }
        }
        
        _mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainManagedObjectContext.persistentStoreCoordinator = _persistentStoreCoordinator;
        
        NSString *threadID = [NSObject createMemoryID:[NSThread currentThread]];
        [self cacheManagedObjectContext:_mainManagedObjectContext forThread:threadID];

        [self setupSaveNotification];
    }
    return self;
}

- (void)dealloc {
    do {
        @synchronized(self) {
            [self resign];
            
            [self.managedObjectContextCahce removeAllObjects];
            self.managedObjectContextCahce = nil;
            
            self.mainManagedObjectContext = nil;
            self.persistentStoreCoordinator = nil;
            self.managedObjectModel = nil;
            
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
            if (_queryPSCURLBlock) {
                result = [_queryPSCURLBlock() absoluteString];
            }
        }
    } while (NO);
    return result;
}

- (int)saveManagedObjectContext {
    int result = -1;
    do {
        @synchronized(self) {
            NSError *err = nil;
            NSManagedObjectContext *moc = [self getManagedObjectContextForCurrentThread];
            if (moc != nil) {
                if ([moc hasChanges] && ![moc save:&err]) {
                    NSLog(@"mainManagedObjectContext save error %@, %@", [err localizedDescription], [err userInfo]);
                }
            }
        }
        result = 0;
    } while (NO);
    return result;
}

- (void)resign {
    do {
        @synchronized(self) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
        }
    } while (NO);
}

- (int)syncAction:(DCCDSMOCActionBlock)aMOCActionBlock withConfigureBlock:(DCCDSMOCConfigureBlock)aMOCConfigureBlock {
    int result = -1;
    do {
        NSManagedObjectContext *moc = [self queryManagedObjectContextForCurrentThread];
        if (moc == nil) {
            break;
        }
        __block NSError *err = nil;
        __block BOOL shouldCacheContext = NO;
        NSString *threadID = [NSObject createMemoryID:[NSThread currentThread]];
        if (moc != self.mainManagedObjectContext && aMOCConfigureBlock) {
            aMOCConfigureBlock(moc, &err);
            if (err) {
                NSLog(@"%@", [err localizedDescription]);
                break;
            }
        }
        [moc performBlockAndWait:^{
            @autoreleasepool {
                aMOCActionBlock(self.managedObjectModel, moc, &shouldCacheContext, &err);
                if (shouldCacheContext) {
                    [self cacheManagedObjectContext:moc forThread:threadID];
                }
            }
        }];
        if (err) {
            NSLog(@"%@", [err localizedDescription]);
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
        __block NSError *err = nil;
        __block BOOL shouldCacheContext = NO;
        NSString *threadID = [NSObject createMemoryID:[NSThread currentThread]];
        if (moc != self.mainManagedObjectContext && aMOCConfigureBlock) {
            aMOCConfigureBlock(moc, &err);
            if (err) {
                NSLog(@"%@", [err localizedDescription]);
                break;
            }
        }
        [moc performBlock:^{
            @autoreleasepool {
                aMOCActionBlock(self.managedObjectModel, moc, &shouldCacheContext, &err);
                if (shouldCacheContext) {
                    [self cacheManagedObjectContext:moc forThread:threadID];
                }
                if (err) {
                    NSLog(@"%@", [err localizedDescription]);
                }
            }
        }];
        result = 0;
    } while (NO);
    return result;
}

#pragma mark - DCCoreDataStore - Private Method
- (void)setupSaveNotification {
    do {
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:nil queue:nil usingBlock:^(NSNotification* note) {
            @synchronized(self) {
                NSArray *allContexts = [_managedObjectContextCahce allValues];
                for (NSManagedObjectContext *moc in allContexts) {
                    if (![note.object isEqual:moc]) {
                        [moc performBlock:^(){
                            [moc mergeChangesFromContextDidSaveNotification:note];
                        }];
                    }
                }
            }
        }];
    } while (NO);
}

- (NSManagedObjectContext *)getManagedObjectContextForCurrentThread {
    NSManagedObjectContext *result = nil;
    do {
        @synchronized(self) {
            if ([[NSThread currentThread] isMainThread]) {
                result = self.mainManagedObjectContext;
            } else {
                if (_managedObjectContextCahce) {
                    NSString *threadID = [NSObject createMemoryID:[NSThread currentThread]];
                    result = [_managedObjectContextCahce objectForKey:threadID];
                }
            }
        }
    } while (NO);
    return result;
}

- (NSManagedObjectContext *)queryManagedObjectContextForCurrentThread {
    NSManagedObjectContext *result = nil;
    do {
        result = [self getManagedObjectContextForCurrentThread];
        if (!result) {
            @synchronized(self) {
                result = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                result.persistentStoreCoordinator = self.persistentStoreCoordinator;
            }
        }
    } while (NO);
    return result;
}

- (void)cacheManagedObjectContext:(NSManagedObjectContext *)context forThread:(NSString *)threadID {
    do {
        if (!context || !threadID) {
            break;
        }
        @synchronized(self) {
            if (!_managedObjectContextCahce) {
                break;
            }
            id obj = [_managedObjectContextCahce objectForKey:threadID];
            if (obj) {
                break;
            }
            [_managedObjectContextCahce setObject:context forKey:threadID];
        }
    } while (NO);
}

@end
