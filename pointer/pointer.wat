(module
  (memory 1)
  (global $pointer i32 (i32.const 128))
  
  (func $init
    ;; $pointerの位置に99を格納
    (i32.store (global.get $pointer) (i32.const 99))
  )
  
  (func (export "get_ptr") (result i32)
    ;; $pointerの位置にある値を返す
    (i32.load (global.get $pointer))
  )
  
  ;; $initを初期化関数として呼び出す
  ;; モジュールがインスタンス化される時に自動的に実行される
  (start $init)
)