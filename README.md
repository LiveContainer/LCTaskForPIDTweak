# LCTaskForPIDTweak

A LiveContainer systemwide tweak allowing multitask apps to access task port and process info of each other.
Allows CocoaTop and VansonMod(?) to work jailed inside LiveContainer environment.

## Installation
- Put this tweak to the global Tweaks folder, and tap the signature button.
- Go to LiveContainer Settings > tap version number 5 times > enable "Load Tweaks to LiveContainer Itself"
- Restart LiveContainer

## Known issues
- No entitlement simulation for now, so an app can get task port of any other running apps

## Technical details
### Hooked methods
- `sysctl({CTL_KERN, KERN_PROC, KERN_PROC_ALL})`
- `proc_pidpath`
- `task_for_pid`
