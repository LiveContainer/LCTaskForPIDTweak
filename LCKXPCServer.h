//
//  KernelXPCServer.h
//  LCTaskForPIDTweak
//
//  Created by Duy Tran on 19/2/26.
//
@import Foundation;

@protocol LCKXPCServiceProtocol
- (void)proc_pidpath:(pid_t)pid reply:(void (^)(NSString *))reply;
- (void)allRunningProcessesWithReply:(void (^)(NSArray<NSNumber *> *))reply;

- (void)checkinWithInfo:(NSDictionary *)info;
- (void)testShowAlert:(NSString *)msg;
@end

@interface LCKProcessInterface : NSObject<LCKXPCServiceProtocol>
@property(nonatomic) NSXPCConnection *connection;
@property(nonatomic) NSDictionary *info;
- (instancetype)initWithConnection:(NSXPCConnection *)connection;
@end

@interface LCKXPCService : NSObject<NSXPCListenerDelegate>
@property(nonatomic) NSXPCListener *listener;
@property(nonatomic) NSMutableDictionary<NSNumber *, LCKProcessInterface *> *processList;
+ (instancetype)sharedInstanceIfExists;
@end

@interface LCKXPCService(Client)
+ (NSXPCConnection *)sharedClientConnection;
+ (id<LCKXPCServiceProtocol>)sharedClientProxy;
@end
