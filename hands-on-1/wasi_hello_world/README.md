# WASM/WASI example

Inspired by [WASI Hello World, Wasm By Example](https://wasmbyexample.dev/examples/wasi-hello-world/wasi-hello-world.rust.en-us.html).

Build:

```
# Setup rustup folowing https://rustup.rs/
$ rustup target add wasm32-wasip1
$ cargo build --target wasm32-wasip1 --release
```

Run with `wasmtime`:

```
$ mkdir helloworld
$ wasmtime run --dir=$PWD::/ target/wasm32-wasip1/release/wasi_hello_world.wasm
```

See [Redesign Wasmtime's CLI flags](https://github.com/bytecodealliance/wasmtime/issues/6741).
