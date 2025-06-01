# Pomodoro 專注計時器

一款專為幫助使用者提高專注力與工作效率所設計的番茄鐘應用程式。此應用程式基於番茄工作法（Pomodoro Technique）原理，協助使用者在工作和休息之間取得平衡。

## 功能特色

- **番茄鐘計時器**：設定專注時間區間和休息時間
- **使用者帳戶管理**：支援電子郵件和 Google 帳號登入
- **個人資料頁面**：查看使用者基本資訊和學習統計數據
- **專注統計追蹤**：
  - 總專注時間記錄
  - 連續學習天數
  - 每週學習時間統計
  - 完成的番茄鐘數量

## 技術堆疊

- **前端框架**：Flutter 
- **程式語言**：Dart
- **後端服務**：Firebase
  - Authentication（使用者認證）
  - Cloud Firestore（資料庫）
  - Firebase Storage（存儲）
- **其他套件**：
  - image_picker：處理圖片選擇
  - palette_generator：顏色擷取
  - intl：國際化支援
  - flutter_html：HTML 內容渲染

## 安裝指南

### 必要條件

- Flutter SDK (^3.7.2)
- Dart SDK
- 註冊的 Firebase 專案
- Android Studio / VS Code

### 安裝步驟

1. 複製此專案到本地
   ```bash
   git clone https://github.com/1028ouo/pomodoro.git
   cd pomodoro
   ```

2. 安裝依賴套件
   ```bash
   flutter pub get
   ```

3. 配置 Firebase
   - 在 Firebase 控制台建立新專案
   - 依照 Firebase Flutter 整合指南新增 Android/iOS 應用程式
   - 下載並放置 `google-services.json`（Android）或 `GoogleService-Info.plist`（iOS）檔案

4. 配置 Spoonacalur API
   - 到官網註冊獲取 API Key
   - 建立自己的 .env 檔
   - 正確引用至您的專案裡

5. 執行專案
   ```bash
   flutter run
   ```

## 專案結構

```
lib/
├── main.dart                 # 應用程式入口
├── pages/                    # 頁面
│   ├── home_page.dart        # 首頁
│   ├── login_page.dart       # 登入頁面
│   ├── timer_page.dart       # 個人資料頁面
│   └── ...
├── services/                 # 服務層（Firebase等）
└── models/                   # 資料模型
```

## 使用說明

1. **登入/註冊**：首次使用時需要建立帳號或使用 Google 帳號登入
2. **設定番茄鐘**：設定專注時間長度（預設25分鐘）
3. **開始專注**：啟動計時器，專心完成任務
4. **查看統計**：在個人資料頁面查看累積的專注時間和其他統計資料
