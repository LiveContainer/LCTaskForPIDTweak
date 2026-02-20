//
//  LCKXPCServer.m
//  LCTaskForPIDTweak
//
//  Created by Duy Tran on 19/2/26.
//
#import "LCKXPCServer.h"
#import "LCTaskForPIDTweak.h"

@implementation LCKProcessInterface
- (instancetype)initWithConnection:(NSXPCConnection *)connection {
    self = [super init];
    self.connection = connection;
    return self;
}
- (void)checkinWithInfo:(NSDictionary *)info {
    if(!self.info) self.info = info;
}
- (void)testShowAlert:(NSString *)message {
    LCShowAlert([NSString stringWithFormat:@"LCTaskForPIDTweak: %@", message]);
}
- (void)allRunningProcessesWithReply:(void (^)(NSArray<NSNumber *> *))reply {
    reply(LCKXPCService.sharedInstanceIfExists.processList.allKeys);
}

- (void)proc_pidpath:(pid_t)pid reply:(void (^)(NSString *))reply {
    reply(LCKXPCService.sharedInstanceIfExists.processList[@(pid)].info[@"ProgramArguments"][0]);
}
@end

@implementation LCKXPCService
static LCKXPCService *sharedInstance;
+ (instancetype)sharedInstanceIfExists {
    return sharedInstance;
}

- (instancetype)init {
    self = sharedInstance = [super init];
    self.listener = [NSXPCListener anonymousListener];
    self.listener.delegate = self;
    [self.listener resume];
    
    self.processList = [NSMutableDictionary dictionary];
    return self;
}

// NSXPCListenerDelegate
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    LCKProcessInterface *obj = [[LCKProcessInterface alloc] initWithConnection:newConnection];
    self.processList[@(newConnection.processIdentifier)] = obj;
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LCKXPCServiceProtocol)];
    newConnection.exportedObject = obj;
    [newConnection resume];
    return YES;
}
@end

