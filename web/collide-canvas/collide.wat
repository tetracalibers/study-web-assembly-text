(module
  (global $cnvs_size (import "env" "cnvs_size") i32)
  (global $no_hit_color (import "env" "no_hit_color") i32)
  (global $hit_color (import "env" "hit_color") i32)
  (global $obj_start (import "env" "obj_start") i32)
  (global $obj_size (import "env" "obj_size") i32)
  (global $obj_cnt (import "env" "obj_cnt") i32)
  (global $x_offset (import "env" "x_offset") i32)
  (global $y_offset (import "env" "y_offset") i32)
  (global $xv_offset (import "env" "xv_offset") i32)
  (global $yv_offset (import "env" "yv_offset") i32)
  
  (import "env" "buffer" (memory 80))
  
  ;; キャンバス全体をクリアする関数
  ;; 画面がオブジェクトだらけにならないように、フレームをレンダリングするたびに呼び出す
  (func $clear_canvas
    (local $i i32)
    (local $pixel_bytes i32)
    
    ;; width * height でピクセル数を求める
    global.get $cnvs_size
    global.get $cnvs_size
    i32.mul
    
    ;; キャンバス全体のピクセルに必要なバイト数を求める
    i32.const 4 ;; ピクセルごとに4バイト必要
    i32.mul
    local.set $pixel_bytes
    
    (loop $pixel_loop
      ;; ピクセル（色情報）に不透明な黒を設定
      (i32.store (local.get $i) (i32.const 0xff_00_00_00))
      
      ;; $i += 4
      (i32.add (local.get $i) (i32.const 4))
      local.set $i
      
      ;; $i < $pixel_bytes の場合、
      ;; まだ全ピクセルの設定が終了していないので、繰り返し
      (i32.lt_u (local.get $i) (local.get $pixel_bytes))
      br_if $pixel_loop
    )
  )
  
  ;; 渡された整数の絶対値を返す関数
  (func $abs (param $value i32) (result i32)
    ;; $valueが負なら、0から引くことで正の数に変換した値を返す
    (i32.lt_s (local.get $value) (i32.const 0))
    if
      i32.const 0
      local.get $value
      i32.sub
      return
    end
    
    ;; $valueが正なら、そのまま返す
    local.get $value
  )
  
  ;; 座標($x, $y)にあるピクセルの色を$colorに設定
  (func $set_pixel (param $x i32) (param $y i32) (param $color i32)
    ;; $xがキャンバスの範囲外の場合、再設定しない
    (i32.ge_u (local.get $x) (global.get $cnvs_size))
    if
      return
    end
    
    ;; $yがキャンバスの範囲外の場合、再設定しない
    (i32.ge_u (local.get $y) (global.get $cnvs_size))
    if
      return
    end
    
    ;; そのピクセルの手前にある各行のピクセルの数
    ;; $y * $cnvs_size
    local.get $y
    global.get $cnvs_size
    i32.mul
    
    ;; ($y * $cnvs_size) + $x
    local.get $x
    i32.add
    
    ;; 線形メモリ内のピクセルのバイト位置
    ;; (($y * $cnvs_size) + $x) * 4
    i32.const 4 ;; 各ピクセルは4バイト
    i32.mul
    
    ;; 色をメモリ位置(($y * $cnvs_size) + $x) * 4に格納
    local.get $color
    i32.store
  )
  
  ;; $obj_size * $obj_sizeピクセルのオブジェクトを矩形として描画する関数
  (func $draw_obj (param $x i32) (param $y i32) (param $color i32)
    (local $max_x i32)
    (local $max_y i32)
    
    
    (local $xi i32)
    (local $yi i32)
    
    ;; $max_x = $x + $obj_size
    local.get $x
    local.tee $xi
    global.get $obj_size
    i32.add
    local.set $max_x
    
    ;; $max_y = $y + $obj_size
    local.get $y
    local.tee $yi
    global.get $obj_size
    i32.add
    local.set $max_y
    
    (block $break
      (loop $draw_loop
        ;; ピクセルの色を設定
        local.get $xi
        local.get $yi
        local.get $color
        call $set_pixel
        
        ;; $xi++
        local.get $xi
        i32.const 1
        i32.add
        local.tee $xi
        
        ;; 今の行を描画し終えた（$xi >= $max_x）なら
        local.get $max_x
        i32.ge_u
        if
          ;; $xiを$xにリセット
          local.get $x
          local.set $xi
          
          ;; ピクセルの次の行の描画に移るため、$yi++
          local.get $yi
          i32.const 1
          i32.add
          local.tee $yi
          
          ;; $yi >= $max_y なら、全行描き終わったのでループ終了
          local.get $max_y
          i32.ge_u
          br_if $break
        end
        
        ;; 継続
        br $draw_loop
      )
    )
  )
  
  ;; オブジェクト番号、属性オフセット、属性の値に基づいて
  ;; 線形メモリ内のオブジェクトの属性を設定する関数
  (func $set_obj_attr
    (param $obj_number i32)
    (param $attr_offset i32)
    (param $value i32)
    
    ;; $obj_number * 16バイトのストライド
    local.get $obj_number
    i32.const 16
    i32.mul
    
    ;; オブジェクトのベースアドレスを足す
    global.get $obj_start
    i32.add
    
    ;; 属性のオフセットを足す
    local.get $attr_offset
    i32.add
    
    ;; ここまでで求めた位置に$valueを格納
    local.get $value
    i32.store
  )
  
  ;; オブジェクト番号、属性オフセットに基づいて、
  ;; 線形メモリ内のオブジェクトの属性を取得する関数
  (func $get_obj_attr
    (param $obj_number i32) (param $attr_offset i32)
    (result i32)
    
    ;; $obj_number * 16バイトのストライド
    local.get $obj_number
    i32.const 16
    i32.mul
    
    ;; オブジェクトのベースアドレスを足す
    global.get $obj_start
    i32.add
    
    ;; 属性のオフセットを足す
    local.get $attr_offset
    i32.add
    
    ;; ここまでで求めた位置の値を読み込んで、返す
    i32.load
  )
  
  ;; フレームをレンダリングするたびにJavaScriptから呼び出される関数
  ;; 1. 全てのオブジェクトのその速度に基づいて移動させる
  ;; 2. 別のオブジェクトと衝突しているオブジェクトと、衝突していないオブジェクトを塗り分ける
  (func $main (export "main")
    ;; 外側、内側のループのカウンタ
    (local $i i32)
    (local $j i32)
    
    ;; 外側、内側のループのオブジェクトへのポインタ
    (local $outer_ptr i32)
    (local $inner_ptr i32)
    
    ;; 外側、内側のループのオブジェクトのx座標
    (local $x1 i32)
    (local $x2 i32)
    ;; 外側、内側のループのオブジェクトのy座標
    (local $y1 i32)
    (local $y2 i32)
    
    ;; オブジェクト間のx軸、y軸の距離
    (local $xdist i32)
    (local $ydist i32)
    
    ;; $iオブジェクトの衝突フラグ
    (local $i_hit i32)
    
    ;; 速度
    (local $xv i32)
    (local $yv i32)
    
    ;; キャンバスを黒で塗りつぶす
    (call $clear_canvas)
    
    (loop $move_loop
      ;; x属性を取得
      (call $get_obj_attr (local.get $i) (global.get $x_offset))
      local.set $x1
      
      ;; y属性を取得
      (call $get_obj_attr (local.get $i) (global.get $y_offset))
      local.set $y1
      
      ;; xの速度属性を取得
      (call $get_obj_attr (local.get $i) (global.get $xv_offset))
      local.set $xv
      
      ;; yの速度属性を取得
      (call $get_obj_attr (local.get $i) (global.get $yv_offset))
      local.set $yv
      
      ;; xに速度を足し、キャンバスの境界内にとどまらせる
      (i32.add (local.get $xv) (local.get $x1))
      ;; 511 は 00000000_00000000_00000001_11111111
      ;; x位置の最後の9ビット以外をマスクすることで、値を0 ~ 511に保つ
      i32.const 0x1ff ;; 10進数の511
      i32.and ;; 上位23ビットを0にする
      local.set $x1
      
      ;; yに速度を足し、キャンバスの境界内にとどまらせる
      (i32.add (local.get $yv) (local.get $y1))
      i32.const 0x1ff ;; 10進数の511
      i32.and ;; 上位23ビットを0にする
      local.set $y1
      
      ;; 線形メモリ内のx属性を設定
      (call $set_obj_attr (local.get $i) (global.get $x_offset) (local.get $x1))
      
      ;; 線形メモリ内のy属性を設定
      (call $set_obj_attr (local.get $i) (global.get $y_offset) (local.get $y1))
      
      ;; $i++
      local.get $i
      i32.const 1
      i32.add
      local.tee $i
      
      ;; $i < $obj_count の場合はループ続行
      global.get $obj_cnt
      i32.lt_u
      if
        br $move_loop
      end
      
      ;; $iをリセットし、ループ終了
      i32.const 0
      local.set $i
    )
    
    ;; 衝突検出の外側のループ
    (loop $outer_loop
      (block $outer_break
        ;; $j = 0
        i32.const 0
        local.tee $j
        
        ;; $i_hit = 0
        local.set $i_hit
        
        ;; オブジェクト$iのx属性を取得
        (call $get_obj_attr (local.get $i) (global.get $x_offset))
        local.set $x1
        
        ;; オブジェクト$iのy属性を取得
        (call $get_obj_attr (local.get $i) (global.get $y_offset))
        local.set $y1
        
        (loop $inner_loop
          (block $inner_break
            ;; $i === $j の場合は$jをインクリメント
            ;; 自身と衝突するのは自明なので、オブジェクト$jを無視する
            local.get $i
            local.get $j
            i32.eq
            if
              local.get $j
              i32.const 1
              i32.add
              local.set $j
            end
            
            ;; $j >= $obj_cnt の場合は全てのオブジェクトの衝突判定が終了しているので、
            ;; 内側のループを抜ける
            local.get $j
            global.get $obj_cnt
            i32.ge_u
            if
              br $inner_break
            end
            
            ;; オブジェクト$jのx属性を取得
            (call $get_obj_attr (local.get $j) (global.get $x_offset))
            local.set $x2
            
            ;; $x1と$x2の距離（正の値）
            (i32.sub (local.get $x1) (local.get $x2))
            call $abs
            local.tee $xdist
            
            ;; $xdist >= $obj_size の場合、オブジェクトは衝突していない
            global.get $obj_size
            i32.ge_u
            if
              ;; $j++
              local.get $j
              i32.const 1
              i32.add
              local.set $j
              ;; 他のオブジェクトと衝突しているか調べるため、内側のループの先頭に移動
              br $inner_loop
            end
            
            ;; オブジェクト$jのy属性を取得
            (call $get_obj_attr (local.get $j) (global.get $y_offset))
            local.set $y2
            
            ;; $y1と$y2の距離（正の値）
            (i32.sub (local.get $y1) (local.get $y2))
            call $abs
            local.tee $ydist
            
            ;; $ydist >= $obj_size の場合、オブジェクトは衝突していない
            global.get $obj_size
            i32.ge_u
            if
              ;; $j++
              local.get $j
              i32.const 1
              i32.add
              local.set $j
              ;; 他のオブジェクトと衝突しているか調べるため、内側のループの先頭に移動
              br $inner_loop
            end
            
            ;; ここに辿り着くということは、衝突している
            i32.const 1
            local.set $i_hit
            
            ;; 衝突している場合は、内側のループを終了
          )
        )
        
        ;; 衝突状況に応じて色を塗り分け
        local.get $i_hit
        i32.const 0
        i32.eq
        if
          (call $draw_obj (local.get $x1) (local.get $y1) (global.get $no_hit_color))
        else
          (call $draw_obj (local.get $x1) (local.get $y1) (global.get $hit_color))
        end
        
        ;; $i++
        local.get $i
        i32.const 1
        i32.add
        local.tee $i
        
        ;; $i < $obj_cnt の場合、オブジェクトの描画はまだ完了していない
        ;; ので、外側のループの先頭に移動
        global.get $obj_cnt
        i32.lt_u
        if
          br $outer_loop
        end
      )
    )
  )
)