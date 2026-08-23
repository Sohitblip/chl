#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <mach/mach.h>
#include "Offsets.hpp"

// Kernel Level Memory Access Reader
template <typename T>
T SafeRead(uintptr_t address) {
    T buffer;
    vm_size_t size = sizeof(T);
    vm_size_t bytesRead = 0;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)address, size, (vm_address_t)&buffer, &bytesRead);
    if (kr != KERN_SUCCESS) return T(); 
    return buffer;
}

// Kernel Level Safe Structural State Writer
void SafeWriteByte(uintptr_t address, uint8_t value) {
    vm_size_t size = sizeof(uint8_t);
    vm_write(mach_task_self(), (vm_address_t)address, (vm_address_t)&value, size);
}

// Background core tracking engine loop
void ProcessEnemyVisibility() {
    uintptr_t UWorld = SafeRead<uintptr_t>(OFFSET_UWORLD);
    if (!UWorld || UWorld < 0x100000000) return;

    uintptr_t ActorArray = SafeRead<uintptr_t>(UWorld + OFFSET_ACTOR_ARRAY);
    if (!ActorArray || ActorArray < 0x100000000) return;

    int ActorCount = SafeRead<int>(UWorld + OFFSET_ACTOR_ARRAY + 0x8);
    if (ActorCount <= 0 || ActorCount > 300) return;

    for (int i = 0; i < ActorCount; i++) {
        uintptr_t CurrentActor = SafeRead<uintptr_t>(ActorArray + (i * 0x8));
        if (!CurrentActor || CurrentActor < 0x100000000) continue;

        // Extracting Skeletal Mesh Component from Unreal Actor memory structure
        // Standard structural engine offset for Mesh tracking is usually 0x280 - 0x310 depending on version
        uintptr_t MeshComponent = SafeRead<uintptr_t>(CurrentActor + 0x280); 
        if (!MeshComponent || MeshComponent < 0x100000000) continue;

        // Custom Engine Flag adjustment to force character skeletal tracking outline visibility 
        // 0x6E4/0x5B0 holds the bOwnerNoSee / bOnlyOwnerSee rendering parameters flags inside Unreal Engine
        // Forcing bits explicitly changes rendering states instantly without rendering canvases
        uintptr_t RenderFlagAddress = MeshComponent + 0x5B0; 
        
        // Changing state to make them bypass standard depth map obstructions
        SafeWriteByte(RenderFlagAddress, 1);
    }
}

@interface ChamsCoreHandler : NSObject
+ (void)initializeLoop;
@end

@implementation ChamsCoreHandler
+ (void)initializeLoop {
    // 15 seconds safe loading buffer for memory region definitions mapping
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Background operational cycle ticking at steady execution sequences
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onTick) userInfo:nil repeats:YES];
    });
}

+ (void)onTick {
    @autoreleasepool {
        ProcessEnemyVisibility();
    }
}
@end

__attribute__((constructor)) static void run_native_chams_engine() {
    [ChamsCoreHandler initializeLoop];
}
