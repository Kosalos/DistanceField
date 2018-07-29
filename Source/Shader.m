#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "Shader.h"

Control *cPtr = NULL;

void setControlPointer(Control *ptr) { cPtr = ptr; }

static float movement = 0.0;
static float movement2 = 0.0;
static float QQQ = 0.07;

void initializeObjs(void) {
    if(cPtr == NULL) { printf("Must call setControlPointer() first\n"); exit(0); }
    
    for(int i=0;i<NUM_OBJECT;++i) {
        cPtr->obj[i].kind = 1;
        cPtr->obj[i].param[0] = 0.1 + (float)i * 0.04;
    }
}

void updateObjs() {
    movement += 0.01f * QQQ;
    movement2 += 0.02f * QQQ;
    
    for(int i=0;i<NUM_OBJECT;++i) {
        cPtr->obj[i].pos.x = cosf(movement *  (float)(i+1  )) * 1.9/16 * (float)(i+1)/4;
     // cPtr->obj[i].pos.y = sinf(movement *  (float)(i+1.2)) * 2.1/16 * (float)(i+1)/4;
        cPtr->obj[i].pos.z = cosf(movement2 * (float)(i+1.5)) * 2.4/16 * (float)(i+1)/5;
    }
}
