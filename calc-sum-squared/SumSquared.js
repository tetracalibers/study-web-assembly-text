const fs = require("fs")

const bytes = fs.readFileSync(__dirname + "/SumSquared.wasm")

const val1 = parseInt(process.argv[2])
const val2 = parseInt(process.argv[3])

;(async () => {
  const wasm = await WebAssembly.instantiate(new Uint8Array(bytes))
  const sum_sq = wasm.instance.exports.SumSquared(val1, val2)
  console.log(`(${val1} + ${val2}) * (${val1} + ${val2}) = ${sum_sq}`)
})()
