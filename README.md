# Claude Scripts Collection

這是一個包含 Claude 相關實用腳本的集合。

## auto_continue_terminals.sh

一個自動化腳本，用於向所有開啟的終端機視窗和分頁發送 "continue" 命令。特別適用於同時運行多個 Claude CLI 會話時的批量操作。

### 功能特點

- 🚀 可以立即執行或定時執行
- 🔄 自動遍歷所有終端機視窗和分頁
- 💤 執行期間防止系統休眠
- 🌍 支援中英文版 macOS
- 🛡️ 完整的錯誤處理和權限檢查

### 使用方法

```bash
# 立即執行
./auto_continue_terminals.sh

# 定時執行（24小時制）
./auto_continue_terminals.sh 14:30  # 下午 2:30 執行
./auto_continue_terminals.sh 09:00  # 上午 9:00 執行
```

### 系統需求

- macOS 系統
- 終端機需要輔助使用權限（系統偏好設定 > 安全性與隱私 > 隱私權 > 輔助使用）

### 注意事項

- 執行過程中可隨時按 Ctrl+C 取消
- 腳本會自動防止系統休眠
- 每個分頁都會收到 "continue" + Enter 鍵

## 貢獻

歡迎提交 Issue 或 Pull Request！

## 授權

MIT License
