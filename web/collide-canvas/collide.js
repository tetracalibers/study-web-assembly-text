/** 正方形キャンバスの辺の長さ */
// 512 = 2^9 = 0x200（バイナリロジックによって幅と高さを簡単に操作できる値）
const cnvs_size = 512

/** 非衝突色 #95BDFF */
const no_hit_color = 0xff_ff_bd_95 // A_B_G_R の順
/** 衝突色 #F7C8E0 */
const hit_color = 0xff_e0_c8_f7

/** 各ピクセルのバイト数（R, G, B, A）*/
const pixel_bytes = 4
/** キャンバス内のピクセル数 */
const pixel_count = cnvs_size * cnvs_size

/** @type {HTMLCanvasElement | null} */
const canvas = document.getElementById("cnvs")
/** WASMで生成したビットマップをcanvas要素にレンダリングするための描画コンテキスト */
const ctx = canvas.getContext("2d")
ctx.clearRect(0, 0, cnvs_size, cnvs_size)

/** 各ストライドのバイト数 */
const stride_bytes = 16
/** 32ビットバージョンのストライド */
// i32型の整数はそれぞれ4バイトなので、4で割る
const stride_i32 = stride_bytes / 4

/** ピクセルデータ保持に必要なバイト数 */
const obj_start = pixel_count * pixel_bytes
/** 先頭のオブジェクトに対する32ビットオフセット */
const obj_start_32 = pixel_count
/** 各オブジェクトのピクセル数 */
const obj_size = 4
/** オブジェクトの数 */
const obj_cnt = 3000

/** x属性（バイト 0 ~ 3） */
const x_offset = 0
/** y属性（バイト 4 ~ 7） */
const y_offset = 4
/** xの速度属性（バイト 8 ~ 11） */
const xv_offset = 8
/** yの速度属性（バイト 12 ~ 15） */
const yv_offset = 12

/** 線形メモリ */
const memory = new WebAssembly.Memory({ initial: 80 })
/** 線形メモリの8ビットビュー */
const mem_i8 = new Uint8Array(memory.buffer)
/** 線形メモリの32ビットビュー */
const mem_i32 = new Uint32Array(memory.buffer)

/** WASMに渡すオブジェクト */
const importObject = {
  env: {
    buffer: memory,
    cnvs_size,
    no_hit_color,
    hit_color,
    obj_start,
    obj_cnt,
    obj_size,
    x_offset,
    y_offset,
    xv_offset,
    yv_offset
  }
}

/** キャンバスに転送するImageDataオブジェクト */
const image_data = new ImageData(
  // memory.bufferは線形メモリ内のデータ（キャンバスに表示されるピクセルデータ）を含んでいる型付き配列
  new Uint8ClampedArray(memory.buffer, 0, obj_start),
  // width
  cnvs_size,
  // height
  cnvs_size
)

// ランダムなオブジェクトを生成
for (let i = 0; i < obj_cnt * stride_i32; i += stride_i32) {
  // オブジェクトのx属性の値として、cnvs_sizeより小さい乱数を設定
  // メモリバッファの32ビット整数ビューを使って、線形メモリ内のデータにアクセス
  mem_i32[obj_start_32 + i] = Math.floor(Math.random() * cnvs_size)
  // オブジェクトのy属性の値として、cnvs_sizeより小さい乱数を設定
  mem_i32[obj_start_32 + i + 1] = Math.floor(Math.random() * cnvs_size)
  // オブジェクトのxv属性の値として、-2 ~ 2の乱数を設定
  mem_i32[obj_start_32 + i + 2] = Math.round(Math.random() * 4) - 2
  // オブジェクトのyv属性の値として、-2 ~ 2の乱数を設定
  mem_i32[obj_start_32 + i + 3] = Math.round(Math.random() * 4) - 2
}

/**
 * 画像データを生成するWASM関数
 * @type {() => void}
 */
let animation_wasm

/** 画面を更新するたびに呼び出される関数 */
const animate = () => {
  // 画像データを生成
  animation_wasm()
  // ピクセルデータをレンダリング
  ctx.putImageData(image_data, 0, 0)
  // 次のフレームをレンダリングするときのコールバックを渡す
  requestAnimationFrame(animate)
}

;(async () => {
  const wasm = await WebAssembly.instantiateStreaming(fetch("collide.wasm"), importObject)
  animation_wasm = wasm.instance.exports.main
  requestAnimationFrame(animate)
})()
