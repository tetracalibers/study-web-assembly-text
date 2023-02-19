const fs = require("fs")

const bytes = fs.readFileSync(__dirname + "/globals.wasm")

const importObject = {
  js: {
    log_i32: value => console.log("i32 ", value),
    log_i64: value => console.log("i64 ", value),
    log_f32: value => console.log("f32 ", value),
    log_f64: value => console.log("f64 ", value)
  },
  env: {
    import_i32: 5_000_000_000,
    import_i64: BigInt(5_000_000_000),
    import_f32: 123.0123456789,
    import_f64: 123.0123456789
  }
}

;(async () => {
  const wasm = await WebAssembly.instantiate(new Uint8Array(bytes), importObject)
  const { globaltest } = wasm.instance.exports
  globaltest()
})()
