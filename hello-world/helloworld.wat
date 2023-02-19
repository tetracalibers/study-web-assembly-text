(module
  ;; 組み込み環境（Node.js）からenvオブジェクトを受け取り、
  ;; その中からprint_stringをインポートし、$print_stringとして使う
  (import "env" "print_string" (func $print_string(param i32)))
  ;; envオブジェクトの中からbufferをインポートし、1ページ(64KB)の線形メモリに割り当てる
  (import "env" "buffer" (memory 1))
  
  ;; 線形メモリでの文字列の開始位置を表すグローバル変数
  (global $start_string (import "env" "start_string") i32)
  ;; 文字列の長さを表す定数
  (global $string_len i32 (i32.const 12))
  
  ;; 線形メモリ内の文字列を定義
  ;; (data データを書き込むメモリ位置 データ)
  (data (global.get $start_string) "hello world!")
  
  ;; helloworld関数を定義し、JSで使えるように公開
  (func (export "helloworld")
    ;; $print_string関数を呼び出す
    (call $print_string (global.get $string_len))
  )
)