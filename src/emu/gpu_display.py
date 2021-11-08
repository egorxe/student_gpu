import sdl2
import sdl2.ext
import ctypes
import numpy

COEF = 1

class GpuDisplay():
    
    def __init__(self, size_x, size_y):
        self.size_x = size_x 
        self.size_y = size_y 
        
        # init framebuffer
        self.framebuffer = numpy.zeros((size_x, size_y), dtype='uint32')
        
        # init SDL
        sdl2.ext.init()
        self.window = sdl2.ext.Window("GPU emulator", size=(self.size_x * COEF, self.size_y * COEF))
        self.window.show()
        self.surface = self.window.get_surface()
        
    def PutPixel(self, pixel):
        # put pixel to buffer (reverse Y axis from OpenGL style to SDL style)
        # OpenGL puts coord origin to lower left corner but SDL to upper left
        self.framebuffer[pixel[0]][self.size_y-1-pixel[1]] = pixel[2]
        # self.framebuffer[pixel[0]][pixel[1]] = pixel[2]
    
    def ClearScreen(self):
        sdl2.ext.fill(self.surface, sdl2.ext.Color(0, 0, 0), (0, 0, self.size_x * COEF, self.size_y * COEF))  
        pass
    
    def DrawFramebuffer(self):
        # copy framebuffer to screen
        pixels = sdl2.ext.pixels2d(self.surface)
        numpy.copyto(pixels, self.framebuffer) 
        
        # clear framebuffer
        self.framebuffer.fill(0)
        
    def Tick(self):
        finish = False
        event = sdl2.events.SDL_Event()
        ret = 1
        while (ret == 1):
            ret = sdl2.events.SDL_PollEvent(ctypes.byref(event), 1)
            if event.type == sdl2.events.SDL_QUIT:
                finish = True
        self.window.refresh()
        return finish
        
