# WASM/WASI example

This example is adapted from
[WASI Hello World, Wasm By Example](https://wasmbyexample.dev/examples/wasi-hello-world/wasi-hello-world.rust.en-us.html).

## Build

```
# Setup rustup folowing https://rustup.rs/
$ rustup target add wasm32-wasip1
$ cargo build --target wasm32-wasip1 --release
```

## Run

With `wasmtime`:

```
$ mkdir helloworld
$ wasmtime run --dir=$PWD::/ target/wasm32-wasip1/release/wasi_hello_world.wasm
```

## References

[Redesign Wasmtime's CLI flags](https://github.com/bytecodealliance/wasmtime/issues/6741).

## License

The code in this folder is based on work that is copyright Aaron Turner and
licensed under a
[Creative Commons Attribution 4.0 License](https://creativecommons.org/licenses/by/4.0/).

See original code at <https://github.com/torch2424/wasm-by-example>.
