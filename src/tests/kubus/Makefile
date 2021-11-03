MESA_DIR := /home/egor/proj/TinyGL/mesa-mesa-18.3.3
TEST_NAME:= kubus

.PHONY: test_mesa

test_mesa:
	cc kubus.c -DUSE_SDL=1 -I$(MESA_DIR)/include $(MESA_DIR)/builddir/install/lib/x86_64-linux-gnu/libGLESv1_CM.so -lSDL2 -o $(TEST_NAME)
