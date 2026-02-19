#import "LCTaskForPIDTweak.h"

@implementation LCTaskForPIDTweak
+ (NSString *)exceptionPortName {
    NSString *appGroupPrefix = [PrivClass(LCSharedUtils) appGroupID];
    return [appGroupPrefix stringByAppendingFormat:@".lc.host.tfptweak.exc_port"];
}
+ (NSString *)kernelPortName {
    NSString *appGroupPrefix = [PrivClass(LCSharedUtils) appGroupID];
    return [appGroupPrefix stringByAppendingFormat:@".lc.host.tfptweak.kernel_port"];
}
+ (NSString *)taskPortNameForPID:(pid_t)pid {
    NSString *appGroupPrefix = [PrivClass(LCSharedUtils) appGroupID];
    return [appGroupPrefix stringByAppendingFormat:@".lc.guest.tfptweak.tfp_%d", pid];
}
@end

@implementation NSXPCListener(LCTaskForPIDTweak)
- (mach_port_t)machPort {
    return xpc_endpoint_copy_listener_port_4sim(self.endpoint._endpoint);
}
@end
@implementation NSXPCListenerEndpoint(LCTaskForPIDTweak)
- (instancetype)initWithBootstrapName:(NSString *)name {
    mach_port_t port;
    kern_return_t kr = bootstrap_look_up(bootstrap_port, name.UTF8String, &port);
    if(kr != KERN_SUCCESS) {
        NSLog(@"[LCTaskForPIDTweak] Failed to look up bootstrap port for %@: %s", name, mach_error_string(kr));
        return nil;
    }
    self = [self init];
    self._endpoint = xpc_endpoint_create_mach_port_4sim(port);
    return self;
}
@end

__attribute__((constructor))
static void init(void) {
    if(PrivClass(LCUtils)) {
        init_livecontainer();
    } else {
        init_guest_apps();
    }
}

void LCShowAlert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        void (*func)(NSString* message) = dlsym(RTLD_DEFAULT, "LCShowAlert");
        assert(func);
        func(msg);
    });
}
