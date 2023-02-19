const colors = require("colors")
const fs = require("fs")
const bytes = fs.readFileSync(__dirname + "/store_data.wasm")

// 64KBのメモリブロックを確保
const memory = new WebAssembly.Memory({ initial: 1 })
// メモリバッファの32ビットのデータビュー
// バッファを32ビット符号なし整数の配列として扱う
const mem_i32 = new Uint32Array(memory.buffer)

// データの1バイト目のアドレス
const data_addr = 32
// データの先頭を表す32ビットインデックス
const data_i32_index = data_addr / 4
// 設定する32ビット整数の個数
const data_count = 16

// WASMがJavaScriptからインポートするオブジェクト
const importObject = {
  env: {
    mem: memory,
    data_addr,
    data_count
  }
}

;(async () => {
  // インスタンス化により、初期化関数を実行
  await WebAssembly.instantiate(new Uint8Array(bytes), importObject)

  // 初期化により変化したメモリバッファの内容を表示
  for (let i = 0; i < data_i32_index + data_count + 4; i++) {
    const data = mem_i32[i]
    if (data !== 0) {
      console.log(`data[${i}]=${data}`.red.bold)
    } else {
      console.log(`data[${i}]=${data}`)
    }
  }
})()
