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


// GL typedefs
typedef float GLfloat;


// Declarations
void gl_M4_MulV4(Vec4 a, M4* b, Vec4 c) ;
void gl_M4_MulLeft(M4* c, M4* b);
void glRotate(float angle, float x, float y, float z);


