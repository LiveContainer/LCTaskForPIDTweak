//
//  LiveContainer.h
//  LCTaskForPIDTweak
//
//  Created by Duy Tran on 18/2/26.
//

@import Darwin;
#define PrivClass(NAME) NSClassFromString(@#NAME)

// LiveContainer functions

@interface LCSharedUtils
+ (NSString *)appGroupID;
+ (NSURL*)containerLockPath;
@end

@interface NSUserDefaults(LiveContainer)
+ (instancetype)lcUserDefaults;
+ (instancetype)lcSharedDefaults;
+ (NSString *)lcAppGroupPath;
+ (NSString *)lcAppUrlScheme;
+ (NSBundle *)lcMainBundle;
+ (NSDictionary *)guestAppInfo;
+ (NSDictionary *)guestContainerInfo;
+ (bool)isLiveProcess;
+ (bool)isSharedApp;
+ (NSString*)lcGuestAppId;
+ (bool)isSideStore;
+ (bool)sideStoreExist;
@end
