const memory = new WebAssembly.Memory({ initial: 1 })

/**
 * 出力先HTML要素
 *
 * @type {HTMLElement}
 */
let output = null

/**
 * WASMからエクスポートした関数。
 * HTML文字列を生成し、線形メモリに格納し、その長さを返す
 *
 * @param {number} _num 変換する数
 * @return {number} HTML文字列の長さ
 */
let setOutput = _num => {
  // WASMモジュールがインスタンス化される前に
  // この関数を実行すると、このメッセージが表示される
  console.log("function not available")
  return 0
}

/**
 * HTML文字列を取り出して表示する関数
 *
 * @param {number} num
 */
const setNumbers = num => {
  // ページが完全に読み込まれていない場合は制御を戻す
  if (output === null) return

  /** HTML文字列の長さ */
  const len = setOutput(num)

  /** メモリバッファから取り出したHTML文字列 */
  const bytes = new Uint8Array(memory.buffer, 1024, len)

  output.innerHTML = new TextDecoder("utf8").decode(bytes)
}

/** 読み込み完了時に実行される関数 */
const onPageLoad = () => {
  output = document.getElementById("output")
}

/** ボタンクリック時に実行される関数 */
const onClickSetNumbersButton = () => {
  const num = document.getElementById("val").value
  setNumbers(num)
}

/** WASMモジュールに渡すデータ */
const importObject = {
  env: {
    buffer: memory
  }
}

;(async () => {
  const wasm = await WebAssembly.instantiateStreaming(fetch("hex_and_binary.wasm"), importObject)
  setOutput = wasm.instance.exports.setOutput

  const btn = document.getElementById("set_numbers_button")
  btn.style.display = "block"
})()
