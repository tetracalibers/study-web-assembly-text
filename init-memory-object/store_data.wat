(module
  ;; 線形メモリをJavaScriptからimport
  (import "env" "mem" (memory 1))
  ;; JavaScriptから読み込むデータのアドレスをimport
  (global $data_addr (import "env" "data_addr") i32)
  ;; 初期化時に格納するデータの個数をimport
  (global $data_count (import "env" "data_count") i32)
  
  (func $store_data (param $index i32) (param $value i32)
    (i32.store
      ;; i32型は4バイト確保しておく必要がある
      ;; $data_addr に $index * 4（i32 = 4バイト）を足す
      (i32.add
        (global.get $data_addr)
        (i32.mul (i32.const 4) (local.get $index))
      )
      ;; 格納する値
      (local.get $value)
    )
  )
  
  (func $init
    (local $index i32)
    
    ;; データを初期化
    (loop $data_loop
      local.get $index
      
      local.get $index
      i32.const 5
      i32.mul
      
      ;; $indexはループの完了した回数を表す
      ;; 今回のダミーデータは、値を5ずつカウントアップして表示する
      ;; $store_data($index)($index * 5)
      call $store_data
      
      ;; $index++
      local.get $index
      i32.const 1
      i32.add
      local.tee $index
      
      global.get $data_count
      i32.lt_u
      br_if $data_loop
    )
    
    ;; 配列内の最初のデータを1に設定する
    ;; 最初のデータを1に設定することで、設定されたデータがどこから始まるのかわかるようにする
    (call $store_data (i32.const 0) (i32.const 1))
  )
  
  (start $init)
)