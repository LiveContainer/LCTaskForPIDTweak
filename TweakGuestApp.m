#import "LCKXPCServer.h"
#import "LCTaskForPIDTweak.h"

static NSString *containerLockPath;
static int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) = sysctl;

static int hook_sysctl_CTL_KERN_PROC_ALL(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    // TODO: implement via LCKXPCServer
    struct kinfo_proc *procs = (struct kinfo_proc *)oldp;
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:containerLockPath];
    if(!info) return 0;
    size_t count = 0;
    for(NSDictionary *appUsageInfo in info.allValues) {
        if(![appUsageInfo isKindOfClass:NSDictionary.class]) continue;
        uint64_t val57 = [appUsageInfo[@"auditToken57"] longLongValue];
        audit_token_t token;
        token.val[5] = val57 >> 32;
        token.val[7] = val57 & 0xffffffff;
        csops_audittoken(token.val[5], 0, NULL, 0, &token);
        if(errno == ESRCH) continue;
        if(oldp) {
            procs[count].kp_eproc.e_ucred.cr_uid = 501; // uid=501
            procs[count].kp_eproc.e_pcred.p_rgid = 501; // gid=501
            procs[count].kp_eproc.e_ppid = 1; // ppid=1
            procs[count].kp_proc.p_pid = token.val[5];
            snprintf(procs[count].kp_proc.p_comm, sizeof(procs[count].kp_proc.p_comm), "LiveProcess");
        }
        count++;
    }
    if(oldlenp) *oldlenp = count * sizeof(struct kinfo_proc);
    return 0;
}
int hook_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if(namelen>=3 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_ALL) {
        return hook_sysctl_CTL_KERN_PROC_ALL(name, namelen, oldp, oldlenp, newp, newlen);
    }
    return orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
}
kern_return_t hook_task_for_pid(mach_port_name_t target_tport, int pid, mach_port_name_t *t) {
    return bootstrap_look_up(bootstrap_port, [LCTaskForPIDTweak taskPortNameForPID:pid].UTF8String, t);
}
int hook_proc_pidpath(int pid, char *buffer, uint32_t buffersize) {
    if(buffersize < 1 || !buffer) return 0;
    [LCKXPCService.sharedClientProxy proc_pidpath:pid reply:^(NSString *path) {
        if(path) {
            bzero(buffer, buffersize);
            strncpy(buffer, path.UTF8String, MIN(path.length, buffersize));
        }
    }];
    return (int)strlen((char *)buffer);
}

void guest_check_in(void) {
    // save old thread states
    exception_mask_t masks[32];
    mach_msg_type_number_t masksCnt;
    exception_handler_t handlers[32];
    exception_behavior_t behaviors[32];
    thread_state_flavor_t flavors[32];
    mach_port_t thread = mach_thread_self();
    thread_get_exception_ports(thread, EXC_MASK_BAD_INSTRUCTION, masks, &masksCnt, handlers, behaviors, flavors);
    thread_set_exception_ports(thread, EXC_MASK_BAD_INSTRUCTION, exc_port, EXCEPTION_STATE_IDENTITY | MACH_EXCEPTION_CODES, ARM_THREAD_STATE64);
    
    // crash here, borrow genter. this will send my task port to LC
    __asm__(".long 0x00201420");
    
    // restore old thread states
    for (int i = 0; i < masksCnt; i++){
        thread_set_exception_ports(mach_thread_self(), EXC_MASK_BAD_INSTRUCTION, handlers[i], behaviors[i], flavors[i]);
        mach_port_deallocate(mach_task_self(), handlers[i]);
    }
    
    // destroy leftover port
    mach_port_deallocate(mach_task_self(), exc_port);
    exc_port = 0;
    
    // check in with the kernel server
    NSDictionary *info = @{
        @"ProgramArguments": NSProcessInfo.processInfo.arguments
    };
    [LCKXPCService.sharedClientProxy pid:getpid() checkinWithInfo:info];
}

void init_guest_apps(void) {
    litehook_rebind_symbol = dlsym(RTLD_DEFAULT, "litehook_rebind_symbol");
    assert(litehook_rebind_symbol);
    
    containerLockPath = [PrivClass(LCSharedUtils) containerLockPath].path;
    kern_return_t kr = bootstrap_look_up(bootstrap_port, LCTaskForPIDTweak.exceptionPortName.UTF8String, &exc_port);
    if(kr != KERN_SUCCESS) {
        LCShowAlert([NSString stringWithFormat:@"LCTaskForPIDTweak: bootstrap_look_up failed: %d", kr]);
        return;
    }
    
    guest_check_in();
    
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, sysctl, hook_sysctl, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, proc_pidpath, hook_proc_pidpath, nil);
    litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, task_for_pid, hook_task_for_pid, nil);
}
