#pragma once
#include <CoreFoundation/CoreFoundation.h>

// MultitouchSupport.framework (private) — layout must stay 96 bytes.
typedef struct { float x; float y; } MTPoint;
typedef struct { MTPoint position; MTPoint velocity; } MTVector;

typedef struct {
    int32_t frame;
    double timestamp;
    int32_t identifier;
    int32_t state;      // 4 = make touch, 5 = touching
    int32_t fingerID;
    int32_t handID;
    MTVector normalized; // 0...1, origin bottom-left
    float size;
    int32_t zero1;
    float angle;
    float majorAxis;
    float minorAxis;
    MTVector absolute;
    int32_t zero2[2];
    float zDensity;
} MTTouch;

typedef void *MTDeviceRef;
typedef int (*MTContactCallback)(MTDeviceRef device, const MTTouch *touches, int32_t count, double timestamp, int32_t frame);

/// Registers the callback on every multitouch device. Returns the device count, or < 0 on failure.
int TPMultitouchStart(MTContactCallback callback);

