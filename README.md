# zig-odin-raylib-template

A zig-build-powered template for building games with odin and raylib that compiles to a native exe or an emscripten app.

To build for desktop (tested on Linux/Windows):

    $ zig build
    $ zig build -Dtarget=x86_64-windows  # cross-compile to windows

To build for web:

    $ zig build -Dtarget=wasm32-wasi --sysroot ~/src/emsdk/upstream/emscripten/
    $ python -m http.server

Then navigate to `http://localhost:8000/game.html` in a web browser.

## versions

TODO: download correct version of odin and emcc so it doens't have to be
externally managed.

```
$ zig version
0.11.0-dev.3363+9461ed503
$ odin version
odin version dev-2023-06-nightly:788f3c22
```
