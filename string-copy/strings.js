const fs = require("fs")
const bytes = fs.readFileSync(__dirname + "/strings.wasm")

const memory = new WebAssembly.Memory({ initial: 1 })
const MAX_STRING_LENGTH = 65535

const importObject = {
  env: {
    buffer: memory,
    null_str: str_pos => {
      const bytes = new Uint8Array(memory.buffer, str_pos, MAX_STRING_LENGTH - str_pos)
      const str_end_null = new TextDecoder("utf8").decode(bytes)
      const str = str_end_null.split("\0")[0]
      console.log(str)
    },
    str_pos_len: (str_pos, str_len) => {
      const bytes = new Uint8Array(memory.buffer, str_pos, str_len)
      const str = new TextDecoder("utf8").decode(bytes)
      console.log(str)
    },
    len_prefix: str_pos => {
      const str_len = new Uint8Array(memory.buffer, str_pos, 1)[0]
      const bytes = new Uint8Array(memory.buffer, str_pos + 1, str_len)
      const str = new TextDecoder("utf8").decode(bytes)
      console.log(str)
    }
  }
}

;(async () => {
  const wasm = await WebAssembly.instantiate(new Uint8Array(bytes), importObject)
  const { main } = wasm.instance.exports
  main()
})()
