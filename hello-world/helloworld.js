const fs = require("fs")

const bytes = fs.readFileSync(__dirname + "/helloworld.wasm")

/** 線形メモリ配列での文字列の開始位置 */
const START_STRING_INDEX = 100
/** WebAssemblyインスタンスがアクセスする線形メモリ（バッファ） */
const memory = new WebAssembly.Memory({ initial: 1 }) // 1ページ確保

/**
 * WebAssemblyモジュール内で呼び出す文字列表示関数
 * @param {number} str_len 文字列の長さ
 */
const printStringForWasm = str_len => {
  const bytes = new Uint8Array(memory.buffer, START_STRING_INDEX, str_len)
  const str = new TextDecoder("utf8").decode(bytes)
  console.log(str)
}

/** WebAssemblyモジュールに渡すオブジェクト */
const wasmImportObj = {
  env: {
    buffer: memory,
    start_string: START_STRING_INDEX,
    print_string: printStringForWasm
  }
}

;(async () => {
  const wasm = await WebAssembly.instantiate(new Uint8Array(bytes), wasmImportObj)
  const { helloworld } = wasm.instance.exports
  helloworld()
})()
