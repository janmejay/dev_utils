#include <assert.h>
#include <stdbool.h>
#include <unistd.h>

#include <X11/extensions/Xfixes.h>

int main(int argc, char** argv) {
    Display *display = XOpenDisplay(NULL);
    assert(display != NULL);
    XFixesHideCursor(display, DefaultRootWindow(display));
    XFlush(display);
    while (true) {
        sleep(100000);
    }
    return 0;
}
