const fs = require("fs")
const bytes = fs.readFileSync(__dirname + "/pointer.wasm")
const memory = new WebAssembly.Memory({ initial: 1, maximum: 4 })

const importObject = {
  env: {
    mem: memory
  }
}

;(async () => {
  const wasm = await WebAssembly.instantiate(new Uint8Array(bytes), importObject)
  const pointer_value = wasm.instance.exports.get_ptr()
  console.log("pointer_value=" + pointer_value)
})()
