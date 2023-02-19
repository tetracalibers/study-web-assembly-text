(module
  (import "js" "external_call" (func $external_call (result i32)))
  
  (global $i (mut i32) (i32.const 0))
  
  (func $internal_call (result i32)
    ;; $iをインクリメント
    global.get $i
    i32.const 1
    i32.add
    global.set $i
    
    ;; 返り値
    global.get $i
  )
  
  (func (export "wasm_call")
    (loop $again
      call $internal_call
      i32.const 4_000_000
      ;; $iの値が4_000_000以下なら繰り返す
      i32.le_u
      br_if $again
    )
  )
  
  (func (export "js_call")
    (loop $again
      call $external_call
      i32.const 4_000_000
      i32.le_u
      br_if $again
    )
  )
)