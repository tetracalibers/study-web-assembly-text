(module 
  (import "env" "print_string" (func $print_string (param i32 i32)))
  (import "env" "buffer" (memory 1))
  
  ;; 16進数文字をすべて含んでいる文字配列$digits
  (data (i32.const 128) "0123456789ABCDEF")
  
  ;; 文字列データを保持するための文字配列$dec_string
  (data (i32.const 256) "               0")
  ;; $dec_stringの長さ
  (global $dec_string_len i32 (i32.const 16))
  
  ;; 整数から10進数文字列を作成する関数
  (func $set_dec_string (param $num i32) (param $string_len i32)
    (local $index i32)
    (local $digit_char i32)
    (local $digit_val i32)
    
    ;; $indexに文字列の長さを格納
    ;; $indexは$dec_stringの最後のバイトを表す
    ;; 最後の文字から、1つずつ最初の文字に向かって移動（デクリメント）させる
    local.get $string_len
    local.set $index
    
    ;; $numは0かどうか
    local.get $num
    i32.eqz
    
    ;; $numが0の場合、スペースは不要
    if
      ;; $index--
      local.get $index
      i32.const 1
      i32.sub
      local.set $index
      
      ;; ASCIIの'0'をメモリ位置 256 + $index に格納
      (i32.store8 offset=256 (local.get $index) (i32.const 48))
    end
    
    ;; ループを使って数値を文字列に変換
    ;; 下から1桁ずつ取り出して、文字列に追加していく繰り返し
    (loop $digit_loop
      (block $break
        ;; $indexが文字列の終わりを指すようにし、0にデクリメント
        local.get $index
        i32.eqz
        br_if $break ;; $index === 0 ならループを抜ける
        
        ;; 最下位の桁の数字を求めて、$digit_valに格納
        local.get $num
        i32.const 10
        i32.rem_u
        local.set $digit_val ;; 10で割った余りを格納
        
        ;; $num === 0 かどうか
        local.get $num
        i32.eqz
        
        if
          ;; $num === 0 なら、左側をスペースでパディング
          i32.const 32 ;; ASCIIのスペース文字
          local.set $digit_char
        else
          ;; i32.load8_uを使って文字を読み込む
          ;; オフセットは$digit_val
          (i32.load8_u offset=128 (local.get $digit_val))
          local.set $digit_char
        end
        
        ;; 次に処理する文字は1つ前なので、$index--
        local.get $index
        i32.const 1
        i32.sub
        local.set $index
        
        ;; 文字をアドレス $dec_string + $index に格納
        (i32.store8 offset=256 (local.get $index) (local.get $digit_char))
        
        ;; 10進数の最後の桁を削除するため、10で割る
        ;; 整数の除算のため、小数点以下が捨てられることを利用している
        local.get $num
        i32.const 10
        i32.div_u
        local.set $num
        
        ;; ループ継続
        br $digit_loop
      )
    )
  )
  
  (func (export "to_string") (param $num i32)
    ;; 文字列に変換したい数値と、左パディングを含む必要な文字列の長さを渡す
    (call $set_dec_string (local.get $num) (global.get $dec_string_len))
    ;; 線形メモリ内で作成した文字列の位置とその文字列の長さを渡す
    (call $print_string (i32.const 256) (global.get $dec_string_len))
  )
)