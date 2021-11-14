#ifndef _GPU_PIPELINE_HH
#define _GPU_PIPELINE_HH

// custom typedefs
typedef float Vec2[2]; 
typedef float Vec3[3]; 
typedef float Vec4[4]; 
typedef unsigned char Rgb[3]; 

struct M4 {
    float m[4][4];
};

typedef struct {
    float v[4];
} V4;

#define PIPELINE_MAX_Z      (1<<16)

#include <iofifo.hh> 
#include <pipeline_cmd.h> 

#endif
