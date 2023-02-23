(module
  (import "env" "buffer" (memory 1))
  
  ;; 16進数の数字
  (global $digit_ptr i32 (i32.const 128))
  (data (i32.const 128) "0123456789ABCDEF")
  
  ;; 10進数文字列のポインタ、長さ、データセクション
  (global $dec_string_ptr i32 (i32.const 256))
  (global $dec_string_len i32 (i32.const 16))
  (data (i32.const 256) "               0")
  
  ;; 16進数文字列のポインタ、長さ、データセクション
  (global $hex_string_ptr i32 (i32.const 384))
  (global $hex_string_len i32 (i32.const 16))
  (data (i32.const 384) "             0x0")
  
  ;; 2進数文字列データのポインタ、長さ、データセクション
  (global $bin_string_ptr i32 (i32.const 512))
  (global $bin_string_len i32 (i32.const 40))
  (data (i32.const 512) " 0000 0000 0000 0000 0000 0000 0000 0000")
  
  ;; h1開始タグの文字列ポインタ、長さ、データセクション
  (global $h1_open_ptr i32 (i32.const 640))
  (global $h1_open_len i32 (i32.const 4))
  (data (i32.const 640) "<H1>")
  
  ;; h1終了タグの文字列ポインタ、長さ、データセクション
  (global $h1_close_ptr i32 (i32.const 656))
  (global $h1_close_len i32 (i32.const 5))
  (data (i32.const 672) "</H1>")
  
  ;; h4開始タグの文字列ポインタ、長さ、データセクション
  (global $h4_open_ptr i32 (i32.const 672))
  (global $h4_open_len i32 (i32.const 4))
  (data (i32.const 672) "<H4>")
  
  ;; h4終了タグの文字列ポインタ、長さ、データセクション
  (global $h4_close_ptr i32 (i32.const 688))
  (global $h4_close_len i32 (i32.const 5))
  (data (i32.const 688) "</H4>")
  
  ;; 出力文字列のポインタとデータセクション
  (global $out_str_ptr i32 (i32.const 1024))
  (global $out_str_len (mut i32) (i32.const 0))
  
  ;; 整数から2進数文字列を作成する関数
  (func $set_bin_string (param $num i32) (param $string_len i32)
    (local $index i32)
    (local $loops_remaining i32)
    (local $nibble_bits i32)
    
    local.get $string_len
    local.set $index
    
    ;; 32ビット整数を扱う上で、外側のループで処理しなければならないニブルの数を求める
    i32.const 8 ;; 32ビットのニブルは8つ（32 / 4 = 8）
    local.set $loops_remaining ;; 外側のループでニブルを区切る
    
    ;; スペースを追加するための外側のループ
    (loop $bin_loop
      (block $outer_break
        ;; $index === 0 ならループから抜ける
        local.get $index
        i32.eqz
        br_if $outer_break
        
        ;; 内側のループで処理しなければならないビットの数を求める
        i32.const 4 ;; 各ニブルの4ビット
        local.set $nibble_bits
      
        ;; 各行を処理するための内側のループ
        (loop $nibble_loop
          (block $nibble_break
            ;; $index--
            local.get $index
            i32.const 1
            i32.sub
            local.set $index
            
            ;; 最後のビットを調べる
            local.get $num
            i32.const 1
            i32.and ;; 最後のビットが1の場合は1、それ以外は0
            
            if
              ;; 1の場合は、'1'を文字列に追加する
              local.get $index
              i32.const 49 ;; ASCIIの'1'
              i32.store8 offset=512 ;; 位置 512 + $index に'1'を格納
            else
              ;; 0の場合は、'0'を文字列に追加する
              local.get $index
              i32.const 48 ;; ASCIIの'0'
              i32.store8 offset=512 ;; 位置 512 + $index に'0'を格納
            end
            
            ;; 最後の1ビットをシフトオフ（取り除く）
            local.get $num
            i32.const 1
            i32.shr_u
            local.set $num
            
            ;; $nibble_bits--
            local.get $nibble_bits
            i32.const 1
            i32.sub
            local.tee $nibble_bits
            
            ;; $nibbles_bits === 0 なら内側のループを抜ける
            i32.eqz
            br_if $nibble_break
            
            ;; 内側のループ続行
            br $nibble_loop
          )
        )
        
        ;; スペース挿入位置を得るため、$index--
        local.get $index
        i32.const 1
        i32.sub
        local.tee $index
        
        ;; 行間のスペースを追加
        i32.const 32 ;; ASCIIのスペース文字
        i32.store8 offset=512 ;; 位置 512 + $index に格納
        
        ;; 外側のループ続行
        br $bin_loop
      )
    )
  )
  
  ;; 整数から16進数文字列を作成する関数
  (func $set_hex_string (param $num i32) (param $string_len i32)
    (local $index i32)
    (local $digit_char i32)
    (local $digit_val i32)
    (local $x_pos i32)
    
    ;; $indexに文字列の長さを格納
    ;; $indexは$dec_stringの最後のバイトを表す
    ;; 最後の文字から、1つずつ最初の文字に向かって移動（デクリメント）させる
    local.get $string_len
    local.set $index
    
    ;; ループを使って数値を文字列に変換
    ;; 下から1桁ずつ取り出して、文字列に追加していく繰り返し
    (loop $digit_loop
      (block $break
        ;; $indexが文字列の終わりを指すようにする
        ;; $index === 0 ならループを抜ける
        local.get $index
        i32.eqz
        br_if $break
        
        ;; 最下位の桁の数字を求めて、$digit_valに格納
        ;; 16進数の1つの桁は、1ニブル（4ビット）のデータに相当
        local.get $num
        i32.const 0xf ;; 16進数の0F, 2進数の0000_1111
        i32.and
        local.set $digit_val ;; 一番下のニブル（下位4桁）を格納
        
        ;; 現在の$num（残りの桁）がすべて0かどうか
        local.get $num
        i32.eqz
        
        if
          ;; $x_pos === 0
          local.get $x_pos
          i32.eqz
          if
            ;; $num === 0 かつ $x_pos === 0 なら
            ;; $x_posにプレフィックス0xを配置する位置を設定
            local.get $index
            local.set $x_pos
          else
            ;; $num === 0 かつ $x_pos !== 0 なら
            ;; 左側をスペースでパディング
            i32.const 32 ;; 32はASCIIのスペース文字
            local.set $digit_char
          end
        else
          ;; 位置 128 + $digit_val から文字を読み込む
          (i32.load8_u offset=128 (local.get $digit_val))
          local.set $digit_char
        end
        
        ;; 次に処理する文字は1つ前なので、$index--
        local.get $index
        i32.const 1
        i32.sub
        local.tee $index
        
        local.get $digit_char
        ;; $digit_charの値を位置 384 + $index に格納
        i32.store8 offset=384
        
        ;; 最後の桁を削除するため、1桁（4ビット）シフト
        local.get $num
        i32.const 4
        i32.shr_u
        local.set $num
        
        ;; ループ継続
        br $digit_loop
      )
    )
    
    ;; 最後の数値文字を入れた場所より1つ左にxを置くため、$x_pos - 1
    local.get $x_pos
    i32.const 1
    i32.sub
    
    ;; xを文字列の先頭に格納
    i32.const 120 ;; ASCIIのx
    i32.store8 offset=384
    
    ;; 最後の数値文字を入れた場所より2つ左に0を置くため、$x_pos - 2
    local.get $x_pos
    i32.const 2
    i32.sub
    
    ;; 0を文字列の先頭に格納
    i32.const 48 ;; ASCIIの0
    i32.store8 offset=384
  )
  
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
        ;; $indexが文字列の終わりを指すようにする
        ;; $index === 0 ならループを抜ける
        local.get $index
        i32.eqz
        br_if $break
        
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
  
  ;; $source ~ $source + $len のメモリブロックを
  ;; $dest ~ $dest + $len のメモリブロックに1バイト（8ビット）ずつコピー
  (func $byte_copy (param $source i32) (param $dest i32) (param $len i32)
    (local $last_source_byte i32)
    
    local.get $source
    local.get $len
    i32.add
    
    local.set $last_source_byte
    
    (loop $copy_loop
      (block $break
        local.get $dest
        ;; $sourceから1バイトを読み取る
        (i32.load8_u (local.get $source))
        ;; $destに1バイトを格納
        i32.store8
        
        ;; $dest++
        local.get $dest
        i32.const 1
        i32.add
        local.set $dest
        
        ;; $source++
        local.get $source
        i32.const 1
        i32.add
        local.tee $source
        
        ;; 終端に達したら抜ける
        local.get $last_source_byte
        i32.eq
        br_if $break
        
        ;; そうでなければ続ける
        br $copy_loop
      )
    )
  )
  
  ;; 8バイト（64ビット）ずつコピー
  (func $byte_copy_i64 (param $source i32) (param $dest i32) (param $len i32)
    (local $last_source_byte i32)
    
    local.get $source
    local.get $len
    i32.add
    
    local.set $last_source_byte
    
    (loop $copy_loop
      (block $break
        (i64.store (local.get $dest) (i64.load (local.get $source)))
        
        ;; $dest = $dest + 8
        local.get $dest
        i32.const 8
        i32.add
        local.set $dest
        
        ;; $source = $source + 8
        local.get $source
        i32.const 8
        i32.add
        local.tee $source
        
        local.get $last_source_byte
        i32.ge_u
        br_if $break
        
        br $copy_loop
      )
    )
  )
  
  ;; 8バイトのコピー関数と1バイトのコピー関数を組み合わせた高速コピー関数
  (func $string_copy (param $source i32) (param $dest i32) (param $len i32)
    (local $start_source_byte i32)
    (local $start_dest_byte i32)
    ;; 1バイトコピーでコピーしなければならないバイト数
    (local $singles i32)
    ;; 8バイトコピーでコピーできるバイト数
    (local $len_less_singles i32)
    
    ;; 8バイトコピーでコピーできるバイト数の初期値 を 文字列全体の長さ[byte] に設定
    local.get $len
    local.set $len_less_singles
    
    ;; $singles = $lenの最後の3ビットをマスクしたもの
    local.get $len
    i32.const 7 ;; 2進数の0111
    i32.and ;; 0111は最後の3ビット以外は0なので、AND演算で0になる
    local.tee $singles ;; 1とのAND演算でそのまま残った最後の3ビットをセット
    
    ;; $singlesが0でなければ、1バイトコピーが必要なので実行
    if
      ;; 8バイトコピーでコピーできるバイト数を更新
      local.get $len ;; 文字列全体のバイト数
      local.get $singles ;; 1バイトずつコピーするしかないバイト数
      i32.sub
      local.tee $len_less_singles ;; $len - $singles
      
      ;; $start_source_byteが1バイトずつコピーしなければならないデータの先頭を指すようにする
      ;; 1バイトずつコピーが必要なデータは、8バイトコピーできるデータの後にあるので、
      ;; $len_less_singles（8バイトコピー可能）分読み飛ばす
      local.get $source
      i32.add
      local.set $start_source_byte ;; $source + $len_less_singles
      
      ;; $start_dest_byteが1バイトずつコピーするデータのコピー先先頭を指すようにする
      local.get $len_less_singles
      local.get $dest
      i32.add
      local.set $start_dest_byte ;; $dest + $len_less_singles
      
      ;; 1バイトずつコピーを実行
      (call $byte_copy
        (local.get $start_source_byte)
        (local.get $start_dest_byte)
        (local.get $singles)
      )
    end
    
    ;; 8バイトコピーする長さを求める
    ;; $lenの最後の3ビットは0にすることで、1バイトコピーした部分は消す
    local.get $len
    i32.const 0xff_ff_ff_f8 ;; 2進数では11111111_11111111_11111111_11111000
    i32.and
    local.set $len
    
    ;; 8バイトコピーを実行
    (call $byte_copy_i64 (local.get $source) (local.get $dest) (local.get $len))
  )
  
  ;; 与えられた文字列を出力文字列の最後に追加
  (func $append_out (param $source i32) (param $len i32)
    ;; 与えられた文字列$sourceをコピーして、出力文字列の最後に追加
    (call $string_copy
      (local.get $source)
      (i32.add
        (global.get $out_str_ptr)
        (global.get $out_str_len)
      )
      (local.get $len)
    )
    
    ;; 出力文字列の長さを更新
    ;; $out_str_len + $len
    global.get $out_str_len
    local.get $len
    i32.add
    global.set $out_str_len
  )
  
  ;; 要素#outputに設定する文字列を作成
  (func (export "setOutput") (param $num i32) (result i32)
    ;; $numの値から10進数文字列を作成
    (call $set_dec_string (local.get $num) (global.get $dec_string_len))
    ;; $numの値から16進数文字列を作成
    (call $set_hex_string (local.get $num) (global.get $hex_string_len))
    ;; $numの値から2進数文字列を作成
    (call $set_bin_string (local.get $num) (global.get $bin_string_len))
    
    ;; 出力文字列をリセットし、現在メモリ内にある文字列が上書きされるようにする
    i32.const 0
    global.set $out_str_len
    
    ;; <h1>${decimal_string}</h1>を出力文字列の最後に追加
    (call $append_out (global.get $h1_open_ptr) (global.get $h1_open_len))
    (call $append_out (global.get $dec_string_ptr) (global.get $dec_string_len))
    (call $append_out (global.get $h1_close_ptr) (global.get $h1_close_len))
    
    ;; <h4>${hexadecimal_string}</h4>を出力文字列の最後に追加
    (call $append_out (global.get $h4_open_ptr) (global.get $h4_open_len))
    (call $append_out (global.get $hex_string_ptr) (global.get $hex_string_len))
    (call $append_out (global.get $h4_close_ptr) (global.get $h4_close_len))
    
    ;; <h4>${binary_string}</h4>を出力文字列の最後に追加
    (call $append_out (global.get $h4_open_ptr) (global.get $h4_open_len))
    (call $append_out (global.get $bin_string_ptr) (global.get $bin_string_len))
    (call $append_out (global.get $h4_close_ptr) (global.get $h4_close_len))
    
    ;; 出力文字列の長さを返す
    global.get $out_str_len
  )
)