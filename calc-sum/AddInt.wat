(module
  (func (export "AddInt")
    (param $value_1 i32) (param $value_2 i32)
    (result i32)
    local.get $value_1 ;; $value_1をスタックにプッシュ
    local.get $value_2 ;; $value_2をスタックにプッシュ
    i32.add ;; 2つの値をポップし、それらの和をスタックにプッシュ
  )
)