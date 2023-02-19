const fs = require('fs')

const bytes = fs.readFileSync(__dirname + '/AddInt.wasm')

/** コマンドラインから取り出した引数。足し算に使う */
const value_1 = parseInt(process.argv[2])
/** コマンドラインから取り出した引数。足し算に使う */
const value_2 = parseInt(process.argv[3])

;(async () => {
  /** WebAssemblyモジュールのインスタンス */
  const wasm = await WebAssembly.instantiate(new Uint8Array(bytes))
  /** @type {number} 足し算の実行結果 */
  const add_value = wasm.instance.exports.AddInt(value_1, value_2)
  /** 表示 */
  console.log(value_1 + ' + ' + value_2 + ' = ' + add_value)
})()
