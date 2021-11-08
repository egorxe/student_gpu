MESA_DIR := /home/egor/proj/TinyGL/mesa-mesa-18.3.3
TEST_NAME:= kubus

.PHONY: test_mesa

test_mesa:
	cc kubus.c -DUSE_SDL=1 -I/usr/local/include -L/usr/local/lib -lGLESv1_CM -lGLU -lSDL2 -o $(TEST_NAME)
