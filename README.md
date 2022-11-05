# zig-raylib-template

A zig template for building games with raylib that compiles to a native exe or an emscripten app.

To build for desktop:

    $ zig build

To build for web:

    $ zig build -Dtarget=wasm32-wasi --sysroot ~/src/emsdk/upstream/emscripten/
    $ python -m http.server

Then navigate to `http://localhost:8000/game.html` in a web browser.
