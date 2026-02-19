//
//  LCKXPCServer.m
//  LCTaskForPIDTweak
//
//  Created by Duy Tran on 19/2/26.
//
#import "LCKXPCServer.h"
#import "LCTaskForPIDTweak.h"

@implementation LCKXPCService
- (instancetype)init {
    self = [super init];
    self.listener = [NSXPCListener anonymousListener];
    self.listener.delegate = self;
    [self.listener resume];
    
    self.processList = [NSMutableDictionary dictionary];
    return self;
}

// Protocol
- (void)proc_pidpath:(pid_t)pid reply:(void (^)(NSString *))reply {
    reply(self.processList[@(pid)][@"ProgramArguments"][0]);
}

- (void)pid:(pid_t)pid checkinWithInfo:(NSDictionary *)info {
    // only allow writing to uninitialized entry
    if(self.processList[@(pid)] != NSNull.null) {
        //LCShowAlert([NSString stringWithFormat:@"LCKXPCService Violation: guest tried to overwrite exitsing process info"]);
        return;
    }
    
    self.processList[@(pid)] = info;
}
- (void)testShowAlert:(NSString *)message {
    LCShowAlert([NSString stringWithFormat:@"LCTaskForPIDTweak: %@", message]);
}

// NSXPCListenerDelegate
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    // set process entry to uninitialized
    self.processList[@(newConnection.processIdentifier)] = NSNull.null;
    
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LCKXPCServiceProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    return YES;
}
@end

