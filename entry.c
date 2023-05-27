#include <emscripten/emscripten.h>
extern void init(void);
extern void update(void);

int main() {
    init();
    emscripten_set_main_loop(update, 0, 1);

    return 0;
}
