#include <stdio.h>
#include <stdlib.h>
#include <GLES/gl.h>

#ifdef USE_SDL
#include <SDL2/SDL.h>
//#include <SDL2/SDL_opengl.h>
SDL_Window* sdl_window;
#endif

/* screen width, height, and bit depth */
//#define SCREEN_WIDTH  640
//#define SCREEN_HEIGHT 480
#define SCREEN_WIDTH  512
#define SCREEN_HEIGHT 512
#define SCREEN_BPP     32

#include "model.h"

/* general OpenGL initialization function */
int initGLES()
{
    /* Enable smooth shading */
    //glShadeModel( GL_SMOOTH );

    /* Set the background black */
    //glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );

    /* Depth buffer setup */
    //glClearDepth( 1.0f );

    /* Enables culling */
    //glEnable(GL_CULL_FACE);
    //glCullFace(GL_FRONT);
    
    /* Enables Depth Testing */
    //glEnable( GL_DEPTH_TEST );

    /* The Type Of Depth Test To Do */
    //glDepthFunc( GL_LEQUAL );

    /* Really Nice Perspective Calculations */
    //glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);

    return 0;
}

/* Here goes our drawing code */
int drawGLScene( GLvoid )
{
    /* Clear The Screen And The Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    //glColor4f(0.0, 0.0, 1.0, 0);  /* blue */
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    

    glDrawArrays(GL_TRIANGLES, 0, 36);

    #ifdef USE_SDL
    /* Draw it to the screen */
    SDL_GL_SwapWindow(sdl_window);
    SDL_Delay(20);
    #endif

    return 0;
}

#ifdef USE_SDL
int InitSDL()
{
    /* initialize SDL */
    if (SDL_Init(SDL_INIT_VIDEO) < 0 )
    {
        fprintf(stderr, "Video initialization failed: %s\n", SDL_GetError());
        exit(1);
    }

    /* create SDL window */
    sdl_window = SDL_CreateWindow("OpenGL ES 1.1 test", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_OPENGL);

    /* Verify there is a window */
    if(!sdl_window)
    {
        fprintf(stderr, "Window could not be created! SDL_Error: %s\n", SDL_GetError());
        exit(1);
    }
    
     // Create new OpenGL context & renderer
    SDL_GLContext ogl_ctx = SDL_GL_CreateContext(sdl_window);
    SDL_GL_SetSwapInterval(0);
    SDL_GL_MakeCurrent(sdl_window, ogl_ctx);
    
    return 0;
}
#endif

void gl_print_matrix(const GLfloat* m) {
	GLint i;

	for (i = 0; i < 4; i++) {
		printf("%f %f %f %f\n", m[i], m[4 + i], m[8 + i], m[12 + i]);
	}
}

int main( int argc, char **argv )
{
    /* main loop variable */
    int done = 0;
    /* used to collect events */

    #ifdef USE_SDL
    /* Init SDL */
    InitSDL();
    #endif

    /* initialize OpenGL */
    initGLES();
    glRotatef(45.f, 1.0f, 1.0f, 1.0f);
    GLfloat matrix[16]; 
    glGetFloatv (GL_MODELVIEW_MATRIX, matrix); 
    //glGetFloatv (GL_PROJECTION_MATRIX, matrix); 
    gl_print_matrix(matrix);

    /* wait for events */ 
    while (!done)
    {
        #ifdef USE_SDL
        /* handle the events in the queue */
        SDL_Event event;
        while (SDL_PollEvent(&event))
        {
            switch( event.type )
            {
                case SDL_QUIT:
                    /* handle quit requests */
                    done = 1;
                    break;
                default:
                    break;
            }
        }
        #endif

        /* draw the scene */
        drawGLScene( );
    }

    #ifdef USE_SDL
    /* clean ourselves up and exit */
    SDL_Quit();
    #endif

    /* Should never get here */
    return 0;
}
