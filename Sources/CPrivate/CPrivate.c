#include "CPrivate.h"
#include <dlfcn.h>

_Static_assert(sizeof(MTTouch) == 96, "MTTouch layout mismatch");

typedef CFMutableArrayRef (*MTDeviceCreateListFn)(void);
typedef void (*MTRegisterContactFrameCallbackFn)(MTDeviceRef, MTContactCallback);
typedef void (*MTDeviceStartFn)(MTDeviceRef, int);

static CFMutableArrayRef gDevices;

static void *openFramework(const char *path) {
    return dlopen(path, RTLD_NOW);
}

int TPMultitouchStart(MTContactCallback callback) {
    void *handle = openFramework("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport");
    if (!handle) return -1;

    MTDeviceCreateListFn createList = (MTDeviceCreateListFn)dlsym(handle, "MTDeviceCreateList");
    MTRegisterContactFrameCallbackFn registerCallback = (MTRegisterContactFrameCallbackFn)dlsym(handle, "MTRegisterContactFrameCallback");
    MTDeviceStartFn start = (MTDeviceStartFn)dlsym(handle, "MTDeviceStart");
    if (!createList || !registerCallback || !start) return -2;

    gDevices = createList(); // kept alive for the app's lifetime
    if (!gDevices) return -3;

    CFIndex count = CFArrayGetCount(gDevices);
    for (CFIndex i = 0; i < count; i++) {
        MTDeviceRef device = (MTDeviceRef)CFArrayGetValueAtIndex(gDevices, i);
        registerCallback(device, callback);
        start(device, 0);
    }
    return (int)count;
}

