(module
  (import "env" "log" (func $log (param i32 i32)))
  
  (func $calc_factorial (export "calc_factorial") (param $n i32) (result i32)
    (local $i i32)
    (local $factorial i32)
    
    (local.set $factorial (i32.const 1))
    
    (loop $continue
      (block $break
        ;; $i++
        (local.set $i
          (i32.add (local.get $i) (i32.const 1))
        )
        ;; $factorial = $i * $factorial
        (local.set $factorial
          (i32.mul (local.get $i) (local.get $factorial))
        )
        ;; 表示
        (call $log (local.get $i) (local.get $factorial))
        ;; $i === $n の場合はループを抜ける
        (br_if $break
          (i32.eq (local.get $i) (local.get $n))
        )
        ;; ループの先頭に戻る
        br $continue
      )
    )
    
    ;; $factorialを呼び出し元のJavaScriptに渡す
    local.get $factorial
  )
)