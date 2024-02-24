# zig-odin-raylib-template

A zig-build-powered template for building games with odin and raylib that compiles to a native exe or an emscripten app.

To build for desktop (tested on Linux/Windows):

    $ git submodule init --update  # only needs to be done on initial clone
    $ zig build
    $ zig build -Dtarget=x86_64-windows  # cross-compile to windows

To build for web:

    $ zig build -Dtarget=wasm32-wasi --sysroot ~/src/emsdk/upstream/emscripten/
    $ python -m http.server

Then navigate to `http://localhost:8000/game.html` in a web browser.

## dependencies/versions

Requires `python3` for helper script that downloads and unpacks odin.

TODO: download emcc so it doens't have to be externally managed.

```
$ zig version
0.11.0
```
