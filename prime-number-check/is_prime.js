const fs = require("fs")
const bytes = fs.readFileSync(__dirname + "/is_prime.wasm")

const value = process.argv[2]

;(async () => {
  const wasm = await WebAssembly.instantiate(new Uint8Array(bytes))
  const { is_prime } = wasm.instance.exports
  if (!!is_prime(value)) {
    console.log(value, "is prime!")
  } else {
    console.log(value, "is not prime")
  }
})()
