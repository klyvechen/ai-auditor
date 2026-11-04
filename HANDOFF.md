# Handoff — AuditAmigo AI / email-assist Google 登入整合

寫於 2026-11-04，因使用者機器即將重開機而暫停。

## 現在在哪個分支

- 工作全部在 ai-auditor 的 git worktree 分支 `worktree-host-scaffold`，**已全部 commit 且已 push**（`git status` 乾淨，HEAD 與 `oring/worktree-host-scaffold` 一致，目前是 `312e5df`）。
- **還沒 merge 進 `main`**。`main` 落後這個分支共 **8 個 commit**（從 `eb7ef87` 改套件名稱那次之後都還沒進 main）：
  ```
  312e5df Wire requestGoogleAccess into the registry (all platforms)
  703986d Add iOS support to Google sign-in
  6a65b97 Re-resolve email_assist to pick up the ProviderNotFoundException fix
  dee8244 Add a per-module Google login gate (tap module -> login if needed -> enter)
  eb7ef87 Rename the app identifier to com.klyve.audit_amigo (iOS: com.klyve.auditAmigo)
  d7cc4bc Stop committing a Google client ID; require a Web-type one locally
  172d1ec Add a debug-only Google sign-in check page
  8e52abf Add on-demand Google sign-in to the host (phase 1, host side)
  ```
  merge 指令跟之前每次都一樣，klyve 自己在主目錄（不是 worktree）執行：
  ```bash
  cd /Users/klyve/prj/ai/ai-auditor
  git fetch oring worktree-host-scaffold
  git checkout main
  git merge worktree-host-scaffold
  git push oring main
  ```

## 做到哪裡了(對照上次說的 A / B 兩塊)

**(A) host 端登入閘門 — 已完成。** `host/lib/modules/host_module.dart` 新增 `requiresGoogle` 旗標，email-assist 這筆設成 `true`（見 `registry.dart`）。行為：Google 已設定但沒登入時，點模組會先顯示登入畫面，登入成功才進模組；Google 沒設定時完全不受影響，等同模組獨立跑。

**(B) Gmail 授權併入同一個流程 — host 端已接上,email-assist 兩端也都做了,但完全沒有真實驗證過。**
- host `registry.dart` 已經把 `requestGoogleAccess: google.requestAccess` 傳給 `Shell`（之前只傳 `googleIdToken`）。
- email-assist 的 `Shell` 已經接受 `requestGoogleAccess` 參數（phase 2）：有傳但 Gmail 還沒連結時,會顯示一個全螢幕的「連結 Gmail」提示,呼叫 `connectGmail()`。
- email-assist 後端已經有 `POST /auth/google/connect`（用 `server_auth_code` 換 token）與 `POST /auth/google/disconnect`。
- host 鎖定的 `email_assist` commit 是 `4d298e0`，**這就是 email-assist 遠端 `main` 目前的最新 commit**（我剛查過 `git ls-remote`，兩邊一致，不需要重新 `flutter pub upgrade email_assist`）。

**完全沒做過的事：真實 Google 登入從頭到尾沒有在瀏覽器或手機上跑過一次。** 之前請 klyve 用 🐞 測試頁驗證(`flutter run -d chrome --web-port=5000 --dart-define-from-file=dart_defines.json`，看「aud 等於用戶端 ID」是否為 ✓)，不確定有沒有做、結果如何——這段對話沒看到。**這是恢復工作後第一件要確認的事**，不要假設 A/B 已經真的跑得通。

## 需要 klyve 做、但不確定有沒有做完的事

1. Google Cloud Console：Web 用戶端（`http://localhost:5000`，ID `152093295844-jtlfd3hmp5hlhgbfvkt09feia0h3rcoe...`，已給過）、Android 用戶端（套件名稱改過,要用新的 `com.klyve.audit_amigo` + debug SHA-1）、iOS 用戶端（`dart_defines.example.json` 已經多了 `GOOGLE_IOS_CLIENT_ID` 佔位符,代表某個時間點加了 iOS 支援,但不確定 klyve 有沒有真的去 Console 建這組）。
2. `~/.android/debug.keystore` 當時不存在；上次教的是 `JAVA_HOME` 沒設好（已幫他寫進 `~/.zshrc`，指向 Android Studio 內建 JBR），不確定後來 `./gradlew signingReport` 有沒有成功跑出 SHA-1。
3. email-assist 後端 `.env` 要設 `GOOGLE_WEB_CLIENT_ID`、`ALLOWED_EMAILS=klyvechen@gmail.com`，並重啟（`.env` 只在啟動時讀）。
4. `dart_defines.json`（不是 `.example.json`）要存在且填對值，這個檔案被 `.gitignore` 排除，**重開機/換機器不會保留**，要重新 `cp dart_defines.example.json dart_defines.json` 再填。

## herdr 狀態要注意

`herdr agent list` 現在看到 w3:p1、w3:p3 的 `name` 都是 `None`——原本叫 `uni-login`、`email-assist-ag` 的名字不見了（可能中途被 clear 過）。**恢復後要先重新確認 email-assist 那個 pane 現在叫什麼名字**（`herdr agent list` 核對 `cwd`/`terminal_title` 是不是 email-assist 那份），不要直接對著舊名字 `email-assist-ag` 送 `herdr agent prompt`，目前這個名字可能已經不存在或接到別的 pane。

## 下一步建議順序

1. 確認 herdr 裡哪個 pane 是 email-assist 的（見上）。
2. 確認 `dart_defines.json` 是否存在、內容對不對。
3. 確認 email-assist 後端 `.env` 有沒有設好、有沒有在跑。
4. 跑 host 的 🐞 測試頁，**第一次真的用 Google 帳號登入**，確認 `aud` 相符。
5. 端對端：點「Gmail 整理助手」→ 應該先看到登入閘門 → 登入後進模組 → 如果 Gmail 還沒連結,應該看到「連結 Gmail」的全螢幕提示 → 按下去測 `connectGmail()` 整條路。
6. 都驗證過再請 klyve 合併 8 個 commit 進 `main`。
7. `flutter analyze`/`flutter test` 這次暫停前沒有跑完確認(跑到一半背景化了,output 在 `/private/tmp/claude-502/-Users-klyve-prj-ai-ai-auditor--claude-worktrees-host-scaffold/43b7495d-3f11-4963-b153-decbd65eea59/tasks/b641eij09.output`，那個暫存目錄重開機後可能會消失，不確定)，重開後第一件事最好重跑一次確認沒有破壞。
