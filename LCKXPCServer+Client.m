//
//  LCKXPCServer.m
//  LCTaskForPIDTweak
//
//  Created by Duy Tran on 19/2/26.
//
#import "LCKXPCServer.h"
#import "LCTaskForPIDTweak.h"

@implementation LCKXPCService(Client)
#pragma mark - Client
+ (NSXPCConnection *)sharedClientConnection {
    static NSXPCConnection *connection;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSXPCListenerEndpoint *endpoint = [[NSXPCListenerEndpoint alloc] initWithBootstrapName:LCTaskForPIDTweak.kernelPortName];
        connection = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];
        
        //(id)[(BypassUnavailable *)[NSXPCConnection alloc] initWithMachServiceName:LCTaskForPIDTweak.kernelPortName];
        connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LCKXPCServiceProtocol)];
        connection.interruptionHandler = ^{
            connection = nil;
            onceToken = 0;
            NSLog(@"LCKXPCService: connection interrupted");
        };
        connection.invalidationHandler = ^{
            connection = nil;
            onceToken = 0;
            NSLog(@"LCKXPCService: connection invalidated");
        };
        [connection activate];
    });
    return connection;
}
+ (id<LCKXPCServiceProtocol>)sharedClientProxy {
    return [self.sharedClientConnection synchronousRemoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        LCShowAlert([NSString stringWithFormat:@"synchronousRemoteObjectProxyWithErrorHandler encountered an error: %@", error.localizedDescription]);
    }];
}
@end
