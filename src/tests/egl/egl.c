#include <gbm.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <EGL/egl.h>
#include <GLES/gl.h>

static EGLint const attribute_list[] = {
        EGL_RED_SIZE, 1,
        EGL_GREEN_SIZE, 1,
        EGL_BLUE_SIZE, 1,
        EGL_NONE
};

int main()
{
    int fd = open("/dev/dri/card0", O_RDWR | FD_CLOEXEC);
    if (fd < 0) 
    {
        abort();
    }

    struct gbm_device *gbm = gbm_create_device(fd);
    if (!gbm) 
    {
        abort();
    }
    
    EGLDisplay display = eglGetDisplay(gbm);
    EGLConfig config;
    EGLint num_config;
    
    if (display == EGL_NO_DISPLAY) {
        abort();
    }

    EGLint major, minor;
    if (!eglInitialize(display, &major, &minor)) {
        abort();
    }
    
    eglChooseConfig(display, attribute_list, &config, 1, &num_config);
    EGLContext context = eglCreateContext(display, config, EGL_NO_CONTEXT, NULL);
    struct gbm_surface *window = gbm_surface_create(gbm,
                                        256, 256,
                                        GBM_FORMAT_XRGB8888,
                                        GBM_BO_USE_RENDERING);
    if (!window) {
        abort();
    } 
    
    EGLSurface surface = eglCreatePlatformWindowSurfaceEXT(display, config, window, NULL);  
                                            
    eglMakeCurrent(display, surface, surface, context);
    
    glClearColor(1.0, 1.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glFlush();

    eglSwapBuffers(display, surface);

    sleep(10);
    return 0;
}
