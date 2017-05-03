TARGET = libvdpau_sunxi.so.1
SRC = device.c presentation_queue.c surface_output.c surface_video.c \
	surface_bitmap.c video_mixer.c decoder.c handles.c \
	h264.c mpeg12.c mpeg4.c mp4_vld.c mp4_tables.c mp4_block.c msmpeg4.c h265.c
CEDARV_TARGET = libcedar_access.so
CEDARV_SRC = ve.c veisp.c

DISPLAY_TARGET = libcedarDisplay.so.1
DISPLAY_SRC = cedar_display.c

NV_TARGET = libvdpau_nv_sunxi.so.1
NV_SRC = opengl_nv.c

CFLAGS ?= -Wall -O0 -g 
LDFLAGS ?=
LIBS = -lrt -lm -lpthread
LIBS_EGL = -lEGL
LIBS_GLES2 = -lGLESv2
LIBS_VDPAU_SUNXI = -L /usr/lib/vdpau
LIBS_CEDARV = -L $(PWD) -lcedar_access
LIBS_DISPLAY = -L $(PWD) -lcedar_access
CC = gcc


USE_UMP = 1

ifeq ($(USE_UMP),1)
LIBS  += -lUMP
CFLAGS += -DUSE_UMP=1
endif

MAKEFLAGS += -rR --no-print-directory

DEP_CFLAGS = -MD -MP -MQ $@
LIB_CFLAGS = -fpic
LIB_LDFLAGS = -shared -Wl,-soname,$(TARGET)
LIB_LDFLAGS_NV = -shared -Wl,-soname,$(NV_TARGET)
LIB_LDFLAGS_CEDARV = -shared -Wl,-soname,$(CEDARV_TARGET)
LIB_LDFLAGS_DISPLAY = -shared -Wl,-soname,$(DISPLAY_TARGET)

OBJ = $(addsuffix .o,$(basename $(SRC)))
DEP = $(addsuffix .d,$(basename $(SRC)))

CEDARV_OBJ = $(addsuffix .o,$(basename $(CEDARV_SRC)))
CEDARV_DEP = $(addsuffix .d,$(basename $(CEDARV_SRC)))

NV_OBJ = $(addsuffix .o,$(basename $(NV_SRC)))
NV_DEP = $(addsuffix .d,$(basename $(NV_SRC)))

DISPLAY_OBJ = $(addsuffix .o,$(basename $(DISPLAY_SRC)))
DISPLAY_DEP = $(addsuffix .d,$(basename $(DISPLAY_SRC)))

MODULEDIR = $(shell pkg-config --variable=moduledir vdpau)

ifeq ($(MODULEDIR),)
MODULEDIR=/usr/lib/vdpau
endif
USRLIB = /usr/lib

.PHONY: clean all install

all: $(CEDARV_TARGET) $(TARGET) $(NV_TARGET) $(DISPLAY_TARGET)

$(TARGET): $(OBJ) $(CEDARV_TARGET)
	$(CC) $(LIB_LDFLAGS) $(LDFLAGS) $(OBJ) $(LIBS) $(LIBS_CEDARV) -o $@

$(NV_TARGET): $(NV_OBJ) $(CEDARV_TARGET)
	$(CC) $(LIB_LDFLAGS_NV) $(LDFLAGS) $(NV_OBJ) $(LIBS) $(LIBS_EGL) $(LIBS_GLES2) $(LIBS_VDPAU_SUNXI) $(LIBS_CEDARV) -o $@

$(CEDARV_TARGET): $(CEDARV_OBJ)
	$(CC) $(LIB_LDFLAGS_CEDARV) $(LDFLAGS) $(CEDARV_OBJ) $(LIBS) -o $@

$(DISPLAY_TARGET): $(DISPLAY_OBJ)
	$(CC) $(LIB_LDFLAGS_DISPLAY) $(LDFLAGS) $(DISPLAY_OBJ) $(LIBS) $(LIBS_CEDARV) $(LIBS_VDPAU_SUNXI) -lvdpau_sunxi -o $@

clean:
	rm -f $(OBJ)
	rm -f $(DEP)
	rm -f $(TARGET)
	rm -f $(NV_OBJ)
	rm -f $(NV_DEP)
	rm -f $(NV_TARGET)
	rm -f $(CEDARV_OBJ)
	rm -f $(CEDARV_DEP)
	rm -f $(CEDARV_TARGET)
	rm -f $(DISPLAY_OBJ)
	rm -f $(DISPLAY_DEP)
	rm -f $(DISPLAY_TARGET)

install: $(TARGET) $(TARGET_NV)
	install -D $(TARGET) $(DESTDIR)$(MODULEDIR)/$(TARGET)
	install -D $(NV_TARGET) $(DESTDIR)$(MODULEDIR)/$(NV_TARGET)
	install -D $(CEDARV_TARGET) $(DESTDIR)$(USRLIB)/$(CEDARV_TARGET)
	ln -sf $(DESTDIR)$(USRLIB)/$(CEDARV_TARGET) $(DESTDIR)$(USRLIB)/$(CEDARV_TARGET).1
	install -D $(DISPLAY_TARGET) $(DESTDIR)$(USRLIB)/$(DISPLAY_TARGET)
	ln -sf $(DESTDIR)$(USRLIB)/$(DISPLAY_TARGET) $(DESTDIR)$(USRLIB)/$(DISPLAY_TARGET).1

uninstall:
	rm -f $(DESTDIR)$(MODULEDIR)/$(TARGET)
	rm -f $(DESTDIR)$(MODULEDIR)/$(NV_TARGET)
	rm -f $(DESTDIR)$(USRLIB)/$(CEDARV_TARGET)
	rm -f $(DESTDIR)$(USRLIB)/$(DISPLAY_TARGET)

%.o: %.c
	$(CC) $(DEP_CFLAGS) $(LIB_CFLAGS) $(CFLAGS) -c $< -o $@

include $(wildcard $(DEP))
