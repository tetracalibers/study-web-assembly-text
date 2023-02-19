const fs = require("fs")

const export_bytes = fs.readFileSync(__dirname + "/table_export.wasm")
const test_bytes = fs.readFileSync(__dirname + "/table_test.wasm")

let i = 0

const increment = () => ++i
const decrement = () => --i

const importObject = {
  js: {
    tbl: null,
    increment,
    decrement,
    wasm_increment: null,
    wasm_decrement: null
  }
}

;(async () => {
  const table_exp_wasm = await WebAssembly.instantiate(new Uint8Array(export_bytes), importObject)
  const { tbl, increment, decrement } = table_exp_wasm.instance.exports
  importObject.js = {
    ...importObject.js,
    tbl,
    wasm_increment: increment,
    wasm_decrement: decrement
  }

  const wasm = await WebAssembly.instantiate(new Uint8Array(test_bytes), importObject)
  const { js_table_test, js_import_test, wasm_table_test, wasm_import_test } = wasm.instance.exports

  i = 0
  let start = Date.now()
  js_table_test()
  let time = Date.now() - start
  console.log("js_table_test time =", time)

  i = 0
  start = Date.now()
  js_import_test()
  time = Date.now() - start
  console.log("js_import_test time =", time)

  i = 0
  start = Date.now()
  wasm_table_test()
  time = Date.now() - start
  console.log("wasm_table_test time =", time)

  i = 0
  start = Date.now()
  wasm_import_test()
  time = Date.now() - start
  console.log("wasm_import_test time =", time)
})()
