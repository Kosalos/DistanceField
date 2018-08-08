# DistanceField
Distance Fields demo for IOS iPad uses Swift and Metal

Utility program for iPad for experiments in raymarching lighting effects.

Learned some ray marching lighting effects by studying shockham's mandelbulb posting: \
https://github.com/shockham/mandelbulb \
This app uses his shader routines, and adds a bunch of widgets so we can alter the parameters in real-time.

Learned Distance Field equations from : http://iquilezles.org/www/articles/distfunctions/distfunctions.htm \
This app animates many spheres using the Distance Field algorithms.

Slide finger on widgets to change respective parameter. \
P1...PB affect fields in the lighting routines,  'Size' is the sphere sine control. \
Press 'AutoChange' to enable automatic param changes.

/////////////////////////////////////
Be sure to try out all the base objects and operators.
Here is a way to see the Subtraction operater in action:

float scene(float3 pos,Control control) {\
    float iDist;\
    float dist = 999.9;\
    float3 p;\
    int skipIndex = 8;\
    int skipIndex2 = 14;\

    for(int i=0;i<NUM_OBJECT;++i) {\
        if(i == skipIndex || i == skipIndex2) continue;\
        
        p = pos - control.obj[i].pos.xyz;  //  <- hardwired to do Sphere distance field
        
        iDist = length(p) - control.pC * control.obj[i].param[0];\
        dist = min(iDist,dist);\
    }

    // now subtract sphere1\
    p = pos - control.obj[skipIndex].pos.xyz;\
    iDist = length(p) - control.pC * control.obj[skipIndex].param[0];\
    dist = max(-iDist,dist);

    // subtract sphere2\
    p = pos - control.obj[skipIndex2].pos.xyz;\
    iDist = length(p) - control.pC * control.obj[skipIndex2].param[0];\
    dist = max(-iDist,dist);

    return dist;
}
/////////////////////////////////////




$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ \
Update: If I comment out all the lighting calls I can get up to 80 spheres, although it gets too slow\
to be fun.  Just curious why this problem crops up. I thought other shadere were much more stressful..
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ \
To everyone reading this, I need your help. \
If I increase the nmber of spheres past 32 (in shader.h), I get the run-time error:  \
"Compute function exceeds available temporary registers". \

I have many things to get past this, but no success. \
Money is no problem. \
Please make the necessary changes to the shader to allow for many more spheres, \
then name your price to teach me what you did.

thanks \
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 

![Screenshot](screenshot.png)

