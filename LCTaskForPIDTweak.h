@import Darwin;
@import Foundation;
#import <mach/mach.h>
#import "bootstrap.h"
#import "litehook.h"
#import "mach_excServer.h"
#import "LiveContainer.h"

mach_port_t exc_port, kern_port;
kern_return_t hook_task_for_pid(mach_port_name_t target_tport, int pid, mach_port_name_t *t);
void init_livecontainer(void);
void init_guest_apps(void);
void LCShowAlert(NSString *msg);

@interface LCTaskForPIDTweak : NSObject
+ (NSString *)exceptionPortName;
+ (NSString *)kernelPortName;
+ (NSString *)taskPortNameForPID:(pid_t)pid;
@end

// categories
@interface NSXPCListener(LCTaskForPIDTweak)
- (mach_port_t)machPort;
@end
@interface NSXPCListenerEndpoint(LCTaskForPIDTweak)
- (instancetype)initWithBootstrapName:(NSString *)name;
@end

// private C APIs
int csops_audittoken(pid_t pid, unsigned int ops, void * useraddr, size_t usersize, audit_token_t * token);
int proc_pidpath(int pid, void *buffer, uint32_t buffersize);
mach_port_t xpc_endpoint_copy_listener_port_4sim(xpc_object_t endpoint);
xpc_endpoint_t xpc_endpoint_create_mach_port_4sim(mach_port_t port);

// private ObjC APIs
@interface NSXPCConnection(private)
- (void)activate;
@end

@interface NSXPCListener(private)
- (id)initWithServiceName:(NSString *)name;
@end

@interface NSXPCListenerEndpoint(private)
@property(nonatomic, setter=_setEndpoint:) xpc_object_t _endpoint;
@end
