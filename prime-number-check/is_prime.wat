(module
  ;; 偶数判定関数
  (func $even_check (param $n i32) (result i32)
    local.get $n
    i32.const 2
    i32.rem_u   ;; 2で割った余り
    i32.const 0 ;; 偶数の余りは0
    i32.eq      ;; $n % 2 === 0
  )
  
  ;; 2かどうかを調べる関数
  (func $eq_2 (param $n i32) (result i32)
    local.get $n
    i32.const 2
    i32.eq
  )
  
  ;; $nが$mの倍数かどうかを調べる関数
  (func $multiple_check (param $n i32) (param $m i32) (result i32)
    local.get $n
    local.get $m
    i32.rem_u    ;; $n % $m
    i32.const 0
    i32.eq
  )
  
  ;; 素数判定関数
  (func $is_prime (export "is_prime") (param $n i32) (result i32)
    (local $i i32)
    
    ;; 1は素数ではない
    (if (i32.eq (local.get $n) (i32.const 1))
      (then
        i32.const 0
        return
      )
    )
    
    ;; 2は素数
    (if (call $eq_2 (local.get $n))
      (then
        i32.const 1
        return
      )
    )
    
    (block $not_prime
      ;; 2以外の偶数は素数ではない
      ;; $even_check関数が1を返す場合は、素数ではないとして抜ける
      (call $even_check (local.get $n))
      br_if $not_prime
      
      ;; $i += 2が常に奇数になるようにする
      (local.set $i (i32.const 1))
      
      ;; $iが$nより大きくなるか、$nを割り切れる$iが見つかるまで、素数の評価を繰り返す
      (loop $prime_check_loop
        ;; setは値をポップするが、teeはスタックに残す
        ;; $iの新しい値を$nと比較するため、スタックに残しておく
        (local.tee $i
          ;; 奇数だけを調べるため、$i += 2
          (i32.add (local.get $i) (i32.const 2))
        )
        
        ;; スタックにプッシュ
        local.get $n
        
        ;; スタックは [$i, $n] みたいな状態
        
        ;; ge_uはスタックに最後に追加された2つの値をポップし、大小を調べる
        ;; $i >= $n の場合、$nは素数
        i32.ge_u
        if
          i32.const 1
          return
        end
        
        ;; $nが$iの倍数の場合は素数ではない
        (call $multiple_check (local.get $n) (local.get $i))
        br_if $not_prime
        
        ;; ループの先頭に戻る
        br $prime_check_loop
      )
    )
    
    ;; $not_primeブロックを抜けてここに到達した場合、falseを返す
    i32.const 0
  )
)