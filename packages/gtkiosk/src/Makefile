GTKINC=`pkg-config --cflags gtk+-3.0`
GTKLIBS=`pkg-config --libs gtk+-3.0`
WKINC=`pkg-config --cflags webkit2gtk-4.0`
WKLIBS=`pkg-config --libs webkit2gtk-4.0`

all: gtkiosk

gtkiosk: gtkiosk.c
	$(CC) $(CFLAGS) $(LDFLAGS) -Wall $(GTKINC) $(WKINC) -o $@ $^ $(GTKLIBS) $(WKLIBS)

clean:
	rm gtkiosk

.PHONY: all clean
