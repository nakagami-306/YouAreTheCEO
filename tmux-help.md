# YouAreTheCEO tmux キーバインド

## プリフィックスキー
- **Ctrl-b** (tmuxデフォルト)

## 基本操作
- `Ctrl-b` + `?` : キーバインド一覧表示
- `Ctrl-b` + `d` : セッションからデタッチ
- `Ctrl-b` + `[` : コピーモード（スクロール可能）
  - コピーモード中: 矢印キーでスクロール、`q`または`Esc`で終了
- `Ctrl-b` + `]` : ペースト

## ペイン操作
- `Ctrl-b` + `%` : 垂直分割
- `Ctrl-b` + `"` : 水平分割
- `Ctrl-b` + `方向キー` : ペイン間移動
- `Ctrl-b` + `o` : 次のペインへ移動
- `Ctrl-b` + `数字` : 指定番号のペインへ移動
- `Ctrl-b` + `x` : 現在のペインを閉じる
- `Ctrl-b` + `z` : ペインの最大化/元に戻す
- `Ctrl-b` + `q` : ペイン番号表示

## ウィンドウ操作
- `Ctrl-b` + `c` : 新しいWorkerウィンドウ作成
- `Ctrl-b` + `w` : ウィンドウ一覧表示
- `Ctrl-b` + `n` : 次のウィンドウ
- `Ctrl-b` + `p` : 前のウィンドウ
- `Ctrl-b` + `数字` : 指定番号のウィンドウへ
- `Ctrl-b` + `,` : ウィンドウ名変更

## CEO System専用
- `Ctrl-b` + `s` : システムステータス表示
- `Ctrl-b` + `r` : 設定リロード
- `Ctrl-b` + `y` : 全ペイン同期のON/OFF
- `Ctrl-b` + `Space` : レイアウト切り替え

## セッション操作
- `tmux attach -t your-company` : セッションにアタッチ
- `tmux detach` : セッションからデタッチ
- `tmux kill-session -t your-company` : セッション終了

## Tips
- コピーモード中はviキーバインドが使用可能（j/k: 上下、h/l: 左右）
- スクロールしたい場合は`Ctrl-b` + `[`でコピーモードに入る