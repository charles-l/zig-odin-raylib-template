#include <emscripten/emscripten.h>
extern void web_init(void);
extern void web_update(void);

int main() {
    web_init();
    emscripten_set_main_loop(web_update, 0, 1);

    return 0;
}
