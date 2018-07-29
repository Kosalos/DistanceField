/*
 Distance field functions from :  http://www.iquilezles.org/www/index.htm
 RayMarching Lighting effects from : https://github.com/shockham/mandelbulb
*/


#include <metal_stdlib>
#import "Shader.h"

using namespace metal;

#define vec2 float2
#define vec3 float3

constant float MIN_DIST = 0.0;
constant float MAX_DIST = 100.0;
constant float EPSILON = 0.0001;
constant float N_EPSILON = 0.001;

float3 toRectangular(float3 sph) {
    return float3(
                  sph.x * sin(sph.z) * cos(sph.y),
                  sph.x * sin(sph.z) * sin(sph.y),
                  sph.x * cos(sph.z));
}

float3 toSpherical(float3 rec) {
    return float3(length(rec),
                  atan2(rec.y,rec.x),
                  atan2(sqrt(rec.x*rec.x+rec.y*rec.y), rec.z));
}

float sdSphere(vec3 p, float s )
{
    return length(p)-s;
}

//float sdCone( float3 p, float2 c )
//{
//    float2 cn = normalize(c);
//
//    float q = length(p.xy);
//    return dot(cn,float2(q,p.z));
//}
//
//float sdTorus(float3 p, float2 t)
//{
//    float2 q = float2(length(p.xz) - t.x, p.y);
//    return length(q) - t.y;
//}
//
//float sdHexPrism( vec3 p, vec2 h )
//{
//    vec3 q = abs(p);
//    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
//}
//
//float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
//{
//    vec3 pa = p - a, ba = b - a;
//    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
//    return length( pa - ba*h ) - r;
//}
//
//float sdCappedCylinder( vec3 p, vec2 h )
//{
//    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
//    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
//}
//
//float sdCappedCone(vec3 p, vec3 c )
//{
//    vec2 q = vec2( length(p.xz), p.y );
//    vec2 v = vec2( c.z*c.y/c.x, -c.z );
//    vec2 w = v - q;
//    vec2 vv = vec2( dot(v,v), v.x*v.x );
//    vec2 qv = vec2( dot(v,w), v.x*w.x );
//    vec2 d = max(qv,0.0)*qv/vv;
//    return sqrt( dot(w,w) - max(d.x,d.y) ) * sign(max(q.y*v.x-q.x*v.y,w.y));
//}
//
//float sdEllipsoid(vec3 p,vec3 r )
//{
//    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
//}
//
//
//float length3Pow(float3 v, float p) {
//    return pow( (pow(v.x,p) + pow(v.y,p) + pow(v.z,p)), (1.0 / p));
//}
//
//float sdTorus82( vec3 p, vec2 t )
//{
//    vec2 q = vec2(length2Pow(p.xz,2)-t.x,p.y);
//    return length2Pow(q,8)-t.y;
//}
//
//float sdTorus88( vec3 p, vec2 t )
//{
//    vec2 q = vec2(length2Pow(p.xz,8)-t.x,p.y);
//    return length2Pow(q,8)-t.y;
//}
//
//float opU( float d1, float d2 )
//{
//    return min(d1,d2);
//}
//
//float opS( float d1, float d2 )
//{
//    return max(-d1,d2);
//}
//
//float opI( float d1, float d2 )
//{
//    return max(d1,d2);
//}

////The mod function returns x minus the product of y and floor(x/y)
//
//float mod1(float x, float y) {
//    if(y == 0) return 0;
//    float div = x/y;
//    return x - y * float(floor(div));
//}
//
//float3 mod3(float3 x, float3 y) {
//    float3 ans;
//    ans.x = mod1(x.x,y.x);
//    ans.y = mod1(x.y,y.y);
//    ans.z = mod1(x.z,y.z);
//    return ans;
//}

//float opRep( vec3 p, vec3 c )
//{
//    vec3 q = mod3(p,c)-0.5*c;
//    return primitve( q );
//}

//vec3 opTx( vec3 p, mat4 m )
//{
//    vec3 q = invert(m)*p;
//    return primitive(q);
//}

float length2Pow(float2 v, float p) {
    return pow( (pow(v.x,p) + pow(v.y,p)), (1.0 / p));
}

// ===================================================================

float scene(float3 pos,Control control) {
    float iDist;
    float dist = 999.9;
    float3 p;
    
    for(int i=0;i<NUM_OBJECT;++i) {
        
        p = pos - control.obj[i].pos.xyz;  //  <- hardwired to do Sphere dostance field
        
        iDist = length(p) - control.pC * control.obj[i].param[0];
        dist = min(iDist,dist);
    }

    return dist;
}

float shortest_dist(float3 eye, float3 marchingDirection, Control control) {
    float start = MIN_DIST;
    float end = 30;
    float depth = start;
    float dist;

    for(;;) {
        dist = scene(eye,control);
        if(dist < control.minimumStepDistance) return depth;
        
        eye += dist * marchingDirection;
        depth += dist;
        if (depth >= end) return end;
    }
}

float3 estimate_normal(float3 p, Control control) {
    float3 ans;
    ans.x = scene(float3(p.x + N_EPSILON, p.y, p.z),control) - scene(float3(p.x - N_EPSILON, p.y, p.z),control);
    ans.y = scene(float3(p.x, p.y + N_EPSILON, p.z),control) - scene(float3(p.x, p.y - N_EPSILON, p.z),control);
    ans.z = scene(float3(p.x, p.y, p.z + N_EPSILON),control) - scene(float3(p.x, p.y, p.z - N_EPSILON),control);
    
    return normalize(ans);
}

float3 phong_contrib
(
 float3 k_d,
 float3 k_s,
 float  alpha,
 float3 p,
 float3 eye,
 float3 lightPos,
 float3 lightIntensity,
 Control control
 ) {
    float3 N = estimate_normal(p,control);
    float3 L = normalize(lightPos - p);
    float dotLN = dot(L, N);
    if (dotLN < 0.0) return float3();
    
    float3 V = normalize(eye - p);
    float3 R = normalize(reflect(-L, N));
    float dotRV = dot(R, V);
    if (dotRV < 0.0) return lightIntensity * (k_d * dotLN);
    
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}

float soft_shadow(float3 ro, float3 rd, float mint, float maxt, float k, Control control) {
    float res = 1.0;
    for(float t=mint; t < maxt;) {
        float h = scene(ro + rd*t,control);
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}

float calc_AO(float3 pos, float3 nor, Control control) {
    float occ = 0.0;
    float sca = 1.0;
    for(int i=0; i<5; i++) {
        float hr = 0.01 + 0.12*float(i)/4.0;
        float3 aopos =  nor * hr + pos;
        float dd = scene(aopos,control);
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}

float3 lighting(float3 k_a, float3 k_d, float3 k_s, float alpha, float3 p, float3 eye, Control control) {
    float3 color = k_a / 2;
    float3 normal = estimate_normal(p,control);
    
    color = mix(color, normal, control.p5);
    color = mix(color, float3(1.0 - smoothstep(0.0, 0.6, distance(float2(0.0), p.xy))), control.p6);
    color = color * float3(1.0, 0.5, control.p7);
    
     float occ = calc_AO(p, normal,control);
    
    float3 light1Pos = float3(4.0 * sin(control.time),
                              5.0,
                              4.0 * cos(control.time));
    float3 light1Intensity = float3(0.4);

    color += phong_contrib(k_d, k_s, alpha, p, eye, light1Pos, light1Intensity, control);
    
    color = mix(color, color * occ * soft_shadow(p, normalize(light1Pos), control.p8, control.p9 * 10, control.pA * 30,control), control.pB);

    return color;
}

kernel void rayMarchShader
(
 texture2d<float, access::write> outTexture [[texture(0)]],
 constant Control &control [[buffer(0)]],
 uint2 p [[thread_position_in_grid]])
{
    float2 uv = float2(float(p.x) / float(control.size), float(p.y) / float(control.size));     // map pixel to 0..1
    float3 viewVector = control.focus - control.camera;
    float3 topVector = toSpherical(viewVector);
    topVector.z += 1.5708;
    topVector = toRectangular(topVector);
    float3 sideVector = cross(viewVector,topVector);
    sideVector = normalize(sideVector) * length(topVector);
    
    float3 color = float3(0,0,0);
    
    float dx = control.zoom * (uv.x - 0.5);
    float dy = (-1.0) * control.zoom * (uv.y - 0.5);
    float3 direction = normalize((sideVector * dx) + (topVector * dy) + viewVector);
    
    float dist = shortest_dist(control.camera,direction,control);
    
    if (dist <= MAX_DIST - EPSILON) {
        float3 pc = control.camera + dist * direction;
        color = lighting(control.p1,control.p2,control.p3,control.p4 * 50, pc, control.camera,control);
    }
    
    outTexture.write(float4(color,1),p);
}

