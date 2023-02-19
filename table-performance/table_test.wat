(module
  (import "js" "tbl" (table $tbl 4 anyfunc))
  (import "js" "increment" (func $increment (result i32)))
  (import "js" "decrement" (func $decrement (result i32)))
  (import "js" "wasm_increment" (func $wasm_increment (result i32)))
  (import "js" "wasm_decrement" (func $wasm_decrement (result i32)))
  
  ;; テーブル関数の型は全てi32であり、引数はない
  (type $returns_i32 (func (result i32)))
  
  ;; 関数テーブルをインデックス参照するためのグローバル変数
  (global $inc_ptr i32 (i32.const 0))
  (global $dec_ptr i32 (i32.const 1))
  (global $wasm_inc_ptr i32 (i32.const 2))
  (global $wasm_dec_ptr i32 (i32.const 3))
  
  ;; JavaScript関数の間接的な呼び出しのパフォーマンスをテスト
  (func (export "js_table_test")
    (loop $inc_cycle
      (call_indirect (type $returns_i32) (global.get $inc_ptr))
      i32.const 4_000_000
      i32.le_u
      br_if $inc_cycle
    )
    (loop $dec_cycle
      (call_indirect (type $returns_i32) (global.get $dec_ptr))
      i32.const 4_000_000
      i32.le_u
      br_if $dec_cycle
    )
  )
  
  ;; JavaScript関数の直接の呼び出しのパフォーマンスをテスト
  (func (export "js_import_test")
    (loop $inc_cycle
      call $increment
      i32.const 4_000_000
      i32.le_u
      br_if $inc_cycle
    )
    (loop $dec_cycle
      call $decrement
      i32.const 4_000_000
      i32.le_u
      br_if $dec_cycle
    )
  )
  
  ;; WASM関数の間接的な呼び出しのパフォーマンスをテスト
  (func (export "wasm_table_test")
    (loop $inc_cycle
      (call_indirect (type $returns_i32) (global.get $wasm_inc_ptr))
      i32.const 4_000_000
      i32.le_u
      br_if $inc_cycle
    )
    (loop $dec_cycle
      (call_indirect (type $returns_i32) (global.get $wasm_dec_ptr))
      i32.const 4_000_000
      i32.le_u
      br_if $dec_cycle
    )
  )
  
  ;; WASM関数の直接の呼び出しのパフォーマンスをテスト
  (func (export "wasm_import_test")
    (loop $inc_cycle
      call $wasm_increment
      i32.const 4_000_000
      i32.le_u
      br_if $inc_cycle
    )
    (loop $dec_cycle
      call $wasm_decrement
      i32.const 4_000_000
      i32.le_u
      br_if $dec_cycle
    )
  )
)