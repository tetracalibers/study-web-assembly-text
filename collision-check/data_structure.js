const colors = require("colors")
const fs = require("fs")
const bytes = fs.readFileSync(__dirname + "/data_structure.wasm")

const memory = new WebAssembly.Memory({ initial: 1 })
const mem_i32 = new Uint32Array(memory.buffer)

// データの1バイト目のアドレス
const obj_base_addr = 0
// 構造体の個数
const obj_count = 32
// 構造体全体のバイト数（4バイト * 属性数4）
const obj_stride = 16

// 構造体の属性のオフセット
const x_offset = 0
const y_offset = 4 // 5バイト目から始まる
const radius_offset = 8
const collision_offset = 12

const obj_i32_base_index = obj_base_addr / 4
const obj_i32_stride = obj_stride / 4

const x_offset_i32 = x_offset / 4
const y_offset_i32 = y_offset / 4
const radius_offset_i32 = radius_offset / 4
const collision_offset_i32 = collision_offset / 4

const importObject = {
  env: {
    mem: memory,
    obj_base_addr,
    obj_count,
    obj_stride,
    x_offset,
    y_offset,
    radius_offset,
    collision_offset
  }
}

// ランダムな大きさの円を作成
for (let i = 0; i < obj_count; i++) {
  const index = obj_i32_stride * i + obj_i32_base_index
  const x = Math.floor(Math.random() * 100)
  const y = Math.floor(Math.random() * 100)
  const r = Math.ceil(Math.random() * 10)

  mem_i32[index + x_offset_i32] = x
  mem_i32[index + y_offset_i32] = y
  mem_i32[index + radius_offset_i32] = r
}

;(async () => {
  await WebAssembly.instantiate(new Uint8Array(bytes), importObject)

  for (let i = 0; i < obj_count; i++) {
    const index = obj_i32_stride * i + obj_i32_base_index

    const x = mem_i32[index + x_offset_i32].toString().padStart(2, " ")
    const y = mem_i32[index + y_offset_i32].toString().padStart(2, " ")
    const r = mem_i32[index + radius_offset_i32].toString().padStart(2, " ")
    const i_str = i.toString().padStart(2, "0")
    const c = !!mem_i32[index + collision_offset_i32]

    if (c) {
      console.log(`obj[${i_str}] x=${x} y=${y} r=${r} collision=${c}`.red.bold)
    } else {
      console.log(`obj[${i_str}] x=${x} y=${y} r=${r} collision=${c}`.green)
    }
  }
})()
