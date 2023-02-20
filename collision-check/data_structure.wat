(module
  (import "env" "mem" (memory 1))

  (global $obj_base_addr (import "env" "obj_base_addr") i32)
  (global $obj_count (import "env" "obj_count") i32)
  (global $obj_stride (import "env" "obj_stride") i32)
  
  (global $x_offset (import "env" "x_offset") i32)
  (global $y_offset (import "env" "y_offset") i32)
  (global $radius_offset (import "env" "radius_offset") i32)
  (global $collision_offset (import "env" "collision_offset") i32)
  
  ;; 衝突検出関数
  (func $collision_check
    (param $x1 i32) (param $y1 i32) (param $r1 i32)
    (param $x2 i32) (param $y2 i32) (param $r2 i32)
    (result i32)
    
    (local $x_diff_sq i32)
    (local $y_diff_sq i32)
    (local $r_sum_sq i32)
    
    ;; $x1 - $x2
    local.get $x1
    local.get $x2
    i32.sub
    ;; ($x1 - $x2) * ($x1 - $x2)
    local.tee $x_diff_sq
    local.get $x_diff_sq
    i32.mul
    local.set $x_diff_sq
    
    ;; $y1 - $y2
    local.get $y1
    local.get $y2
    i32.sub
    ;; ($y1 - $y2) * ($y1 - $y2)
    local.tee $y_diff_sq
    local.get $y_diff_sq
    i32.mul
    local.set $y_diff_sq
    
    ;; $r1 + $r2
    local.get $r1
    local.get $r2
    i32.add
    ;; ($r1 + $r2) * ($r1 + $r2)
    local.tee $r_sum_sq
    local.get $r_sum_sq
    i32.mul
    local.tee $r_sum_sq
    
    ;; X^2 + Y^2
    local.get $x_diff_sq
    local.get $y_diff_sq
    i32.add
    ;; X^2 + Y^2 < D
    i32.gt_u
  )
  
  ;; 線形メモリからオブジェクトの属性を取り出す関数
  (func $get_attr 
    (param $obj_base i32) (param $attr_offset i32)
    (result i32)
    
    ;; ベースアドレスに属性オフセットを足す
    local.get $obj_base
    local.get $attr_offset
    i32.add
    ;; その位置にある値を読み取って返す
    i32.load
  )
  
  ;; 与えられたオブジェクトの衝突フラグを設定する関数
  ;; 2つのオブジェクトのベースアドレスを受け取り、それらのオブジェクトの衝突フラグを設定
  (func $set_collision (param $obj_base_1 i32) (param $obj_base_2 i32)
    ;; アドレス = $obj_base_1 + $collision_offset に 1(true) を格納
    local.get $obj_base_1
    global.get $collision_offset
    i32.add
    i32.const 1
    i32.store
    
    ;; アドレス = $obj_base_2 + $collision_offset に 1(true) を格納
    local.get $obj_base_2
    global.get $collision_offset
    i32.add
    i32.const 1
    i32.store
  )
  
  ;; 衝突チェック実行
  ;; 線形メモリ内のそれぞれの円を他のすべての円と比較する
  (func $init
    ;; 外側のループカウンタ
    (local $i i32)
    ;; i番目のオブジェクトのアドレス
    (local $i_obj i32)
    ;; オブジェクトiのx, y, r
    (local $xi i32)
    (local $yi i32)
    (local $ri i32)
    
    ;; 内側のループカウンタ
    (local $j i32)
    ;; j番目のオブジェクトのアドレス
    (local $j_obj i32)
    ;; オブジェクトjのx, y, r
    (local $xj i32)
    (local $yj i32)
    (local $rj i32)
    
    ;; 外側のループ
    (loop $outer_loop
      ;; $j = 0
      (local.set $j (i32.const 0))
      
      ;; 内側のループ
      (loop $inner_loop
        (block $inner_continue
          ;; $i === $j の場合は同じ円の比較なので、処理をスキップ
          (br_if $inner_continue
            (i32.eq (local.get $i) (local.get $j))
          )
          
          ;; $i_obj = $obj_base_addr + $i * $obj_stride
          ;; 次の$get_attr引数の (local.tee $i_obj) で値を格納している
          (i32.add
            (global.get $obj_base_addr)
            (i32.mul (local.get $i) (global.get $obj_stride))
          )

          ;; $i_obj + $x_offset を読み取って$xiに格納
          (call $get_attr (local.tee $i_obj) (global.get $x_offset))
          local.set $xi

          ;; $i_obj + $y_offset を読み取って$yiに格納
          (call $get_attr (local.get $i_obj) (global.get $y_offset))
          local.set $yi

          ;; $i_obj + $radius_offset を読み取って$riに格納
          (call $get_attr (local.get $i_obj) (global.get $radius_offset))
          local.set $ri
          
          ;; $j_obj = $obj_base_addr + $j * $obj_stride
          ;; 次の$get_attr引数の (local.tee $j_obj) で値を格納している
          (i32.add 
            (global.get $obj_base_addr)
            (i32.mul (local.get $j) (global.get $obj_stride))
          )
          
          ;; $j_obj + $x_offset を読み取って$xjに格納
          (call $get_attr (local.tee $j_obj) (global.get $x_offset))
          local.set $xj
          
          ;; $j_obj + $y_offset を読み取って$yiに格納
          (call $get_attr (local.get $j_obj) (global.get $y_offset))
          local.set $yj

          ;; $j_obj + $radius_offset を読み取って$riに格納
          (call $get_attr (local.get $j_obj) (global.get $radius_offset))
          local.set $rj
          
          ;; i番目とj番目のオブジェクトの衝突をチェック
          (call $collision_check
            (local.get $xi) (local.get $yi) (local.get $ri)
            (local.get $xj) (local.get $yj) (local.get $rj)
          )
          
          ;; 衝突する場合は、衝突フラグをtrueに変更
          if
            (call $set_collision (local.get $i_obj) (local.get $j_obj))
          end
        )
        
        ;; j++
        ;; 次に出現する (local.tee $j) で値を格納
        (i32.add (local.get $j) (i32.const 1))
        
        ;; $j < $obj_count の場合は内側のループを繰り返す
        ;; 今の円を、他の円と比較する
        (br_if $inner_loop
          (i32.lt_u (local.tee $j) (global.get $obj_count))
        )
      )
      ;; $i++
      ;; 次に出現する (local.tee $i) で値を格納
      (i32.add (local.get $i) (i32.const 1))
      
      ;; $i < $obj_count の場合は外側のループを繰り返す
      ;; 今の円の比較が終わったので、他の円を調査対象とする
      (br_if $outer_loop
        (i32.lt_u (local.tee $i) (global.get $obj_count))
      )
    )
  )
  
  (start $init)
)