//
//  KernelXPCServer.h
//  LCTaskForPIDTweak
//
//  Created by Duy Tran on 19/2/26.
//
@import Foundation;

@protocol LCKXPCServiceProtocol
- (void)proc_pidpath:(pid_t)pid reply:(void (^)(NSString *))reply;

- (void)pid:(pid_t)pid checkinWithInfo:(NSDictionary *)info;
- (void)testShowAlert:(NSString *)msg;
@end

@interface LCKXPCService : NSObject<NSXPCListenerDelegate, LCKXPCServiceProtocol>
@property(nonatomic) NSXPCListener *listener;
@property(nonatomic) NSMutableDictionary *processList;
@end

@interface LCKXPCService(Client)
+ (NSXPCConnection *)sharedClientConnection;
+ (id<LCKXPCServiceProtocol>)sharedClientProxy;
@end
