#include <stdlib.h> 
#include <string.h>

// Custom typedefs ------------------------------------------------------

typedef float Vec2[2]; 
typedef float Vec3[3]; 
typedef float Vec4[4]; 

struct M4 {
    float m[4][4];
};

// Parameters ------------------------------------------------------------

// struct M4 model_matrix = {{
//         {1, 0, 0, 0},
//         {0, 1, 0, 0},
//         {0, 0, 1, 0},
//         {0, 0, 0, 1},
//     }};
// struct M4 proj_matrix = {{
//         {1, 0, 0, 0},
//         {0, 1, 0, 0},
//         {0, 0, 1, 0},
//         {0, 0, 0, 1},
//     }};

struct M4 model_matrix = {{
        {1,         0,          0,          0           },
        {0,         1,          0,          0           },
        {0,         0,          1,          -3.0        },  
        {0,         0,          0,          1           },
    }};

struct M4 proj_matrix = {{
        {1.810660,  0,          0,          0           },
        {0,         2.414214,   0,          0           },
        {0,         0,          -1.020202,  -0.202020   },
        {0,         0,          -1.000000,  0           },
    }};

int SCREEN_WIDTH = 640;
int SCREEN_HEIGHT = 480;

// Commands --------------------------------------------------------------

#define GPU_PIPE_CMD_MIN            0xFFFFFF00
#define GPU_PIPE_CMD_POLY_VERTEX    0xFFFFFF00
#define GPU_PIPE_CMD_FRAME_END      0xFFFFFF01
#define GPU_PIPE_CMD_FRAGMENT       0xFFFFFF02

// TGL functions ---------------------------------------------------------

void gl_M4_MulV4(Vec4 a, struct M4* b, Vec4 c) 
{
    Vec4 tmp;
    tmp[0] = b->m[0][0] * c[0] + b->m[0][1] * c[1] + b->m[0][2] * c[2] + b->m[0][3] * c[3];
    tmp[1] = b->m[1][0] * c[0] + b->m[1][1] * c[1] + b->m[1][2] * c[2] + b->m[1][3] * c[3];
    tmp[2] = b->m[2][0] * c[0] + b->m[2][1] * c[1] + b->m[2][2] * c[2] + b->m[2][3] * c[3];
    tmp[3] = b->m[3][0] * c[0] + b->m[3][1] * c[1] + b->m[3][2] * c[2] + b->m[3][3] * c[3];
    memcpy(a, tmp, 4*sizeof(float));
}

// Kind of viewport transformation ----------------------------------------

void ViewportTransform(Vec4 s, float *d, int size_x, int size_y)
{
    d[0] = (1 + s[0])/2. * (size_x-1);
    d[1] = (1 + s[1])/2. * (size_y-1);
    d[2] = (1 + s[2])/2.;
    d[3] = s[3];    // we will need w clip coord during rasterization for perspective correct vertex attribute (color) calculations
}

// Vertex to display coords ------------------------------------------------

void process_vertex(float *vert_in, float *vert_out)
{
    Vec4 vert_vec4 = {vert_in[0], vert_in[1], vert_in[2], 1};
    // multiply on model matrix
    gl_M4_MulV4(vert_vec4, &model_matrix, vert_vec4);
    // multiply on projection matrix
    gl_M4_MulV4(vert_vec4, &proj_matrix, vert_vec4);
    
    // ###TODO: clipping should be done here
    
    // normalize coordinates (produce NDC)
    vert_vec4[0] = vert_vec4[0]/vert_vec4[3];
    vert_vec4[1] = vert_vec4[1]/vert_vec4[3];
    vert_vec4[2] = vert_vec4[2]/vert_vec4[3];

    ViewportTransform(vert_vec4, vert_out, SCREEN_WIDTH, SCREEN_HEIGHT);
}