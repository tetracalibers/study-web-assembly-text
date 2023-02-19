(module
  ;; 開始位置と長さが必要
  (import "env" "str_pos_len" (func $str_pos_len (param i32 i32)))
  ;; null終端文字を使えば、開始位置だけで済む
  (import "env" "null_str" (func $null_str (param i32)))
  ;; 長さを表すプレフィックスを持つ文字列
  (import "env" "len_prefix" (func $len_prefix (param i32)))
  (import "env" "buffer" (memory 1))
  
  (data (i32.const 0) "null-terminating string\00")
  (data (i32.const 128) "another null-terminating string\00")
  (data (i32.const 256) "Know the length of this string")
  (data (i32.const 384) "Also know the length of this string")
  ;; 長さは10進数で22 = 16進数で16
  (data (i32.const 512) "\16length-prefixed string")
  ;; 長さは10進数で30 = 16進数で1e
  (data (i32.const 640) "\1eanthor length-prefixed string")
  
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
  
  (func (export "main")
    ;; コピー前
    (call $str_pos_len (i32.const 256) (i32.const 30))
    (call $str_pos_len (i32.const 384) (i32.const 35))
    
    ;; 1つ目の文字列から30バイトを2つ目の文字列にコピー
    (call $string_copy (i32.const 256) (i32.const 384) (i32.const 30))
    
    ;; 長さは元の2つ目の文字列のまま
    ;; 1つ目の文字列 + 2つ目の文字列の最後の5文字 が表示される
    (call $str_pos_len (i32.const 384) (i32.const 35))
    ;; 長さを1つ目の文字列の長さと等しく設定すると、正しく表示される
    (call $str_pos_len (i32.const 384) (i32.const 30))
  )
)