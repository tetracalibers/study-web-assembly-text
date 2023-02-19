const fs = require("fs")
const bytes = fs.readFileSync(__dirname + "/number_string.wasm")
const value = parseInt(process.argv[2])
const memory = new WebAssembly.Memory({ initial: 1 })

;(async () => {
  const wasm = await WebAssembly.instantiate(new Uint8Array(bytes), {
    env: {
      buffer: memory,
      print_string: (str_pos, str_len) => {
        const bytes = new Uint8Array(memory.buffer, str_pos, str_len)
        const str = new TextDecoder("utf8").decode(bytes)
        console.log(`>${str}!`)
      }
    }
  })
  wasm.instance.exports.to_string(value)
})()
