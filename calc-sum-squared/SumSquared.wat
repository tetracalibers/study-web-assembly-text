(module
  (func (export "SumSquared")
    (param $value_1 i32) (param $value_2 i32)
    (result i32)
    
    ;; 加算結果を格納するローカル変数を用意
    (local $sum i32)
    ;; たし算してポップ
    (i32.add (local.get $value_1) (local.get $value_2))
    ;; 取り出した値を格納
    local.set $sum
    
    ;; かけ算してポップ
    (i32.mul (local.get $sum) (local.get $sum))
  )
)