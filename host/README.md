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
# Web（Chrome）— port 要固定,因為 Google 用戶端登記的「已授權 JavaScript 來源」是 http://localhost:5000
flutter run -d chrome --web-port=5000 --dart-define-from-file=dart_defines.json

# iOS 模擬器（Google 登入尚未支援 iOS,見下方）
flutter run -d "iPhone 15"        # 換成 flutter devices 列出的實際名稱/ID

# Android 模擬器 / 實機
flutter run -d emulator-5554 --dart-define-from-file=dart_defines.json   # 換成 flutter devices 列出的實際 ID
```

## Google 登入

登入是**按需觸發**的:進框架不會要求登入,模組用到 Google 時才會呼叫。登入後右上角橫幅會出現帳號頭像(選單有「登出」)。設計見 [`../docs/plugin-contract.md`](../docs/plugin-contract.md) 第 6 點。

- 先 `cp dart_defines.example.json dart_defines.json`,再填入 **「Web 應用程式」型用戶端**的 ID(公開值,識別「這個 app」,不是使用者)。`dart_defines.json` 已被 `.gitignore` 排除,不會進 repo。
- **一定要是「Web 應用程式」型**,不能用「電腦版應用程式(桌面)」型的 ID:桌面型不能登記 JavaScript 來源,Chrome 登入會失敗。用戶端類型建立後無法更改,一個 ID 只對應一個用戶端。email-assist 後端的 `credentials.json` 是桌面型,**不是**這個。
- **用戶端密鑰(client secret)不放這裡、也不進 repo**,只會放在模組後端的環境變數。
- 沒帶 `--dart-define-from-file` 時 Google 登入不可用(其他功能不受影響)。
- 需要在 Google Cloud Console 完成:Web 用戶端(登記 `http://localhost:5000` 為已授權 JavaScript 來源)、Android 用戶端(套件名稱 `com.klyve.audit_amigo` + 該機器的 debug SHA-1)、把要登入的信箱加進 OAuth 同意畫面的測試使用者。
- 目前只支援 **Web 與 Android**。iOS 需要另外設定(Info.plist 的 `GIDClientID` 與 URL scheme),尚未做。
- 測試中狀態的 `gmail.modify` refresh token 約 7 天過期,需要重新授權。

**目前這個 host 只提供登入本身**:email-assist 的 `Shell` 還沒有接收身份的參數,要等它那邊對接後,模組才會實際使用這個登入。

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
