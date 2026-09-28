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

# iOS 模擬器
flutter run -d "iPhone 15" --dart-define-from-file=dart_defines.json   # 換成 flutter devices 列出的實際名稱/ID

# Android 模擬器 / 實機
flutter run -d emulator-5554 --dart-define-from-file=dart_defines.json   # 換成 flutter devices 列出的實際 ID
```

## Google 登入

登入是**按需觸發**的:進框架不會要求登入,模組用到 Google 時才會呼叫。登入後右上角橫幅會出現帳號頭像(選單有「登出」)。設計見 [`../docs/plugin-contract.md`](../docs/plugin-contract.md) 第 6 點。

- 先 `cp dart_defines.example.json dart_defines.json`,再填入用戶端 ID。`dart_defines.json` 已被 `.gitignore` 排除,不會進 repo。
- **用戶端密鑰(client secret)不放這裡、也不進 repo**,只會放在模組後端的環境變數。
- 沒帶 `--dart-define-from-file` 時 Google 登入不可用(其他功能不受影響)。iOS 則是 `GOOGLE_WEB_CLIENT_ID`、`GOOGLE_IOS_CLIENT_ID` 兩個都要有才會啟用,少一個就視同「iOS 上未設定」(其他平台不受影響)。
- 三個平台各自要在 Google Cloud Console 建對應的用戶端,**同一個 project 底下建三個**,用戶端類型建立後無法更改:
  - **Web 應用程式**:填 `GOOGLE_WEB_CLIENT_ID`。已授權的 JavaScript 來源要登記 `http://localhost:5000`。這組 ID 同時也是 Android 的 `serverClientId`、iOS 的 `serverClientId`(換 refresh token 用),所以三個平台共用同一個 Web 用戶端。
  - **Android**:套件名稱 `com.klyve.audit_amigo` + 該機器的 debug SHA-1(`./gradlew signingReport`,見上面「事前準備」)。**這組 ID 不用填進任何檔案**——Android 靠套件名稱+簽章比對,不靠程式碼裡的 ID。
  - **iOS**:Bundle ID `com.klyve.auditAmigo`(注意跟 Android 的底線寫法不同,iOS bundle ID 不能有底線)。填 `GOOGLE_IOS_CLIENT_ID`。**另外還要改 `ios/Runner/Info.plist` 的 `CFBundleURLTypes`**——把 `REPLACE_WITH_REVERSED_IOS_CLIENT_ID` 換成你拿到的 iOS 用戶端 ID 反過來寫的格式:例如 ID 是 `123-abc.apps.googleusercontent.com`,反過來就是 `com.googleusercontent.apps.123-abc`。這個 URL scheme 是 Google 登入在 iOS 上接收回呼用的,**就算用程式碼傳 client ID,這一步仍然必要**,不是可以跳過的選項。這串不是密鑰,可以進 repo。
  - email-assist 後端的 `credentials.json` 是**桌面型**,跟上面三組都**不是同一種**,不要拿來用。
  - 三個用戶端都要把要登入的信箱加進 OAuth 同意畫面的測試使用者。
- 測試中狀態的 `gmail.modify` refresh token 約 7 天過期,需要重新授權。
- **iOS 額外的 App Store 規則**:Apple 的審核規則對「有 Google 登入」的 App 有額外要求([Login Services](https://developer.apple.com/app-store/review/guidelines/#login-services))——通常需要同時提供一種不依賴第三方帳號的登入方式(例如 Sign in with Apple)。這是**上架前**才需要處理的事,開發/測試階段不受影響,先記錄在這裡。

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

**Android**:release 版只放行 `127.0.0.1`/`10.0.2.2`/`localhost` 三個位址的明文 HTTP
（`android/app/src/main/res/xml/network_security_config.xml`）,但 **debug 版（`flutter run` 預設）另外套用
`android/app/src/debug/res/xml/network_security_config.xml`,放行任何位址**,所以連區網 IP（實機測試）
不用改設定檔就能用。

**iOS**:`ios/Runner/Info.plist` 的 `NSAppTransportSecurity` 目前也只放行 `127.0.0.1`/`localhost`,**沒有 debug
版才放寬這種機制**——如果要用 iOS 實機連區網 IP 的後端,要手動把該 IP 加進 `NSExceptionDomains`,目前還沒有像
Android 那樣自動處理,是已知的落差。

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
