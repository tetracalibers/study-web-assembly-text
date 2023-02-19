const fs = require("fs")
const bytes = fs.readFileSync(__dirname + "/loop.wasm")
const n = parseInt(process.argv[2] || "1")

const importObject = {
  env: {
    log: (n, factorial) => console.log(n + "! = " + factorial)
  }
}

;(async () => {
  /** i32がサポートするのはおよそ20億までの数値 */
  if (n > 12) {
    console.log("=== Factorials greater than 12 are too large for a 32-bit integer. ===")
    return
  }
  const wasm = await WebAssembly.instantiate(new Uint8Array(bytes), importObject)
  const { calc_factorial } = wasm.instance.exports
  const factorial = calc_factorial(n)
  console.log("result ", n + "! = " + factorial)
})()
