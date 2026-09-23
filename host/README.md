# ai_auditor (host)

AI-Auditor 框架本體。負責跨模組導覽（左側選單 / 手機殼），把每個模組的 `Shell` widget 嵌進內容區。
細節約定見 [`../docs/plugin-contract.md`](../docs/plugin-contract.md)。目前掛載的模組見
[`../modules.json`](../modules.json)。

## 事前準備

1. **Flutter SDK**（已驗證於 3.47.x）。
2. 平台工具鏈，只需要裝你打算跑的那個：
   - **Web**：不需要額外安裝，Chrome 就能跑。
   - **iOS**：完整安裝的 Xcode + CocoaPods。
   - **Android**：Android Studio / Android SDK（`flutter config --android-sdk` 若非預設路徑）。

   用 `flutter doctor` 確認缺什麼。

3. **先啟動 email-assist 的後端**（host 本身不管模組的後端）：
   ```bash
   cd ../../email-assist
   uv run email-assist serve   # 預設 http://127.0.0.1:8000
   ```
   細節見 [`email-assist/README.md`](../../email-assist/README.md)。

## 安裝依賴

```bash
cd host
flutter pub get
```

## 啟動（開發模式）

先看有哪些可用裝置：
```bash
flutter devices
```

再照平台啟動：

```bash
# Web（Chrome）
flutter run -d chrome

# iOS 模擬器
flutter run -d "iPhone 15"        # 換成 flutter devices 列出的實際名稱/ID

# Android 模擬器 / 實機
flutter run -d emulator-5554      # 換成 flutter devices 列出的實際 ID
```

## 連線到本機後端時的位址對照

email-assist 的 Shell 需要你在它的「設定」頁填入後端網址，不同執行環境看到的
`127.0.0.1` 意義不同：

| 執行環境 | 後端網址要填 |
|---|---|
| Web (Chrome) | `http://127.0.0.1:8000` |
| iOS 模擬器 | `http://127.0.0.1:8000`（模擬器共用 Mac 的 localhost） |
| Android 模擬器 | `http://10.0.2.2:8000`（Android 模擬器的 `10.0.2.2` 才是指向 host 機器） |
| iOS/Android 實機 | 用 Mac 的區網 IP，例如 `http://192.168.x.x:8000`，且手機要跟 Mac 在同一個網路 |

`127.0.0.1` / `10.0.2.2` / `localhost` 這三個位址的明文 HTTP 流量已經在
`android/app/src/main/res/xml/network_security_config.xml`（Android）與
`ios/Runner/Info.plist`（iOS）開放,其他網域預設仍會被 ATS / Android 9+ 擋掉。
如果之後要連實機的區網 IP 或正式後端網域,要記得把該網域也加進這兩個檔案的放行清單。

## 打包（release build）

```bash
flutter build web           # 輸出在 build/web/
flutter build apk           # 或 flutter build appbundle,輸出在 build/app/outputs/
flutter build ios           # 需要在有 Xcode 的機器上執行,再用 Xcode 走 archive/上架流程
```

依 [`../docs/plugin-contract.md`](../docs/plugin-contract.md) 的「打包限制」:三個平台是各自獨立的
build 指令,任何模組程式碼變動都要三個平台各自重新 build、重新部署。

## 測試

```bash
flutter analyze
flutter test
```
