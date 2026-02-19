#import "LCKXPCServer.h"
#import "LCTaskForPIDTweak.h"

kern_return_t catch_mach_exception_raise_state_identity(mach_port_t exception_port, mach_port_t thread, mach_port_t task, exception_type_t exception, mach_exception_data_t code, mach_msg_type_number_t codeCnt, int *flavor, thread_state_t old_state, mach_msg_type_number_t old_stateCnt, thread_state_t new_state, mach_msg_type_number_t *new_stateCnt) {
    //NSLog(@"DBG: catch_mach_exception_raise_state_identity");
    arm_thread_state64_t *old = (arm_thread_state64_t *)old_state;
    arm_thread_state64_t *new = (arm_thread_state64_t *)new_state;
    uint64_t pc = arm_thread_state64_get_pc(*old);
    //if(*(uint32_t *)pc == 0x00201420) {
    *new = *old;
    *new_stateCnt = old_stateCnt;
    arm_thread_state64_set_pc_fptr(*new, (void *)(pc+4));
    int pid;
    pid_for_task(task, &pid);
    return bootstrap_register(bootstrap_port, (char *)[LCTaskForPIDTweak taskPortNameForPID:pid].UTF8String, task);
}
static void *exception_server(void *unused) {
    mach_msg_server(mach_exc_server, sizeof(union __RequestUnion__catch_mach_exc_subsystem), exc_port, MACH_MSG_OPTION_NONE);
    return NULL;
}
static void *kernel_server(void *unused) {
    static LCKXPCService *service;
    assert(!service);
    service = [LCKXPCService new];
    kern_port = service.listener.machPort;
    
    // Expose the XPC service to the public
    kern_return_t kr = bootstrap_register(bootstrap_port, (char*)LCTaskForPIDTweak.kernelPortName.UTF8String, kern_port);
    if(kr != KERN_SUCCESS) {
        LCShowAlert([NSString stringWithFormat:@"LCTaskForPIDTweak: bootstrap_register(kern_port) failed: %d", kr]);
        return NULL;
    }
   
    return NULL;
}
void init_livecontainer(void) {
    // in LiveContainer we make a global exception port
    kern_return_t kr;
    kr = bootstrap_check_in(bootstrap_port, LCTaskForPIDTweak.exceptionPortName.UTF8String, &exc_port);
    if(kr != KERN_SUCCESS) {
        LCShowAlert([NSString stringWithFormat:@"LCTaskForPIDTweak: bootstrap_check_in(exc_port) failed: %d", kr]);
        return;
    }
    
    mach_port_insert_right(mach_task_self(), exc_port, exc_port, MACH_MSG_TYPE_MAKE_SEND);
    pthread_t tExc;
    pthread_create(&tExc, NULL, exception_server, NULL);
    //pthread_create(&tKern, NULL, kernel_server, NULL);
    kernel_server(NULL);
}
