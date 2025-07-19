# Claude Scripts Collection

這是一個包含 Claude 相關實用腳本的集合，旨在最大化利用 Claude 訂閱價值。

## 為什麼需要這些腳本？ / Why These Scripts?

Claude 的對話視窗有 5 小時的活動時間限制。當你在睡覺或忙於其他事情時，這些寶貴的時間可能會被浪費。這個腳本集合幫助你：

- 🎯 **最大化訂閱價值** - 在 5 小時視窗即將結束時自動續期
- 😴 **睡眠時間自動化** - 設定在凌晨自動執行，不錯過任何可用時間
- 🔄 **批量操作管理** - 同時管理多個 Claude 會話
- ⏰ **精準時間控制** - 在最佳時機自動續期對話

## auto_continue_terminals.sh

一個自動化腳本，用於向所有開啟的終端機視窗和分頁發送 "continue" 命令。專為優化 Claude 使用時間而設計。

### 功能特點

- 🚀 可以立即執行或定時執行
- 🔄 自動遍歷所有終端機視窗和分頁
- 💤 執行期間防止系統休眠
- 🌍 支援中英文版 macOS
- 🛡️ 完整的錯誤處理和權限檢查

### 典型使用場景 / Typical Use Cases

#### 💤 睡眠時間最佳化 / Sleep Time Optimization
```bash
# 晚上 11:00 開始 Claude 任務
# 在凌晨 3:50 自動續期（5小時視窗前）
./auto_continue_terminals.sh 03:50

# 早上醒來時，Claude 仍在運行，可以繼續工作！
```

#### 🏢 工作時間管理 / Work Time Management
```bash
# 早上 9:00 開始任務
# 下午 1:50 自動續期
./auto_continue_terminals.sh 13:50

# 午餐時不需要擔心會話超時
```

#### 🌙 過夜任務處理 / Overnight Task Processing
```bash
# 設定多個時間點，確保長時間任務不中斷
# 第一次續期：凌晨 2:00
./auto_continue_terminals.sh 02:00
# 第二次續期：早上 7:00（在另一個終端執行）
./auto_continue_terminals.sh 07:00
```

### 為什麼不使用 crontab 或其他排程工具？ / Why Not Use crontab or Other Schedulers?

這個腳本特意設計為**前台執行**而非背景排程，原因如下：

#### 🖥️ **即時視覺反饋 / Real-time Visual Feedback**
- 可以即時看到腳本執行狀態和 Claude 的回應
- 在終端中保持完整的互動記錄
- 發生問題時能立即介入處理

#### 💤 **系統休眠問題 / System Sleep Issues**
- macOS 的 crontab 在系統休眠時**不會執行**
- launchd 雖然支援休眠喚醒，但配置複雜且不可靠
- 本腳本使用 `caffeinate` 主動防止系統休眠

#### 🔍 **透明度與控制 / Transparency and Control**
- 可以隨時按 Ctrl+C 中斷執行
- 清楚看到每個步驟的執行過程
- 保持對 Claude 會話的完整掌控

#### 🎯 **簡單可靠 / Simple and Reliable**
```bash
# crontab 的問題：系統休眠時不執行
# 50 3 * * * /path/to/script.sh  # ❌ 電腦睡眠時會錯過

# 本腳本的解決方案：主動防止休眠
./auto_continue_terminals.sh 03:50  # ✅ 保證執行
```

#### 📚 **技術細節已驗證 / Technical Details Verified**

這些設計決策基於以下已驗證的事實：

1. **crontab 限制**：根據 macOS 官方文檔和社群經驗，cron 作業在系統休眠時確實不會執行
2. **caffeinate 功能**：macOS 內建的 `caffeinate` 命令（位於 `/usr/bin/caffeinate`）可有效防止系統進入休眠狀態
3. **實際效果**：使用 `caffeinate -d -i -s` 可以同時防止顯示器休眠、系統閒置休眠和系統休眠

### 使用方法 / Usage

#### 📝 **準備步驟 / Preparation Steps**

1. **開啟所有需要的終端機視窗 / Open all required Terminal windows**
   ```bash
   # 在每個終端機分頁中啟動 Claude
   claude
   
   # 等待 Claude 進入交互模式
   # 你應該會看到類似 "Claude: How can I help you today?" 的提示
   ```

2. **確保輸入法為英文 / Ensure English Input Method**
   - ⚠️ **重要**：執行腳本前必須將輸入法切換為英文
   - 腳本會發送 "continue" 命令，中文輸入法可能導致輸入錯誤
   - macOS 快捷鍵：`Control + Space` 或 `Command + Space`（依據系統設定）

3. **執行腳本 / Run the Script**
   ```bash
   # 立即執行
   ./auto_continue_terminals.sh
   
   # 定時執行（24小時制）
   ./auto_continue_terminals.sh 14:30  # 下午 2:30 執行
   ./auto_continue_terminals.sh 09:00  # 上午 9:00 執行
   ```

#### 🎯 **最佳實踐 / Best Practices**

- 在睡前設置好所有 Claude 會話
- 確認每個終端都已進入 Claude 交互模式
- 將輸入法切換為英文後再執行腳本
- 可以開啟多個終端視窗，腳本會自動處理所有視窗

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
