#pragma once
#include <simd/simd.h>

#define NUM_OBJECT 32

typedef struct {
    vector_float3 pos;
    int kind;
    float param[2];
} Object;

typedef struct {
    vector_float3 camera;
    vector_float3 focus;

    Object obj[NUM_OBJECT];
    
    int size;
    int formula;
    float power;
    float minimumStepDistance;
    float zoom;
    float time;
    
    float p1;
    float p2;
    float p3;
    float p4;
    float p5;
    float p6;
    float p7;
    float p8;
    float p9;
    float pA;
    float pB;
    float pC;
} Control;

#ifndef __METAL_VERSION__

void setControlPointer(Control *ptr);
void initializeObjs(void);
void updateObjs(void);

#endif

