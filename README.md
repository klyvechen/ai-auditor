# AI-Auditor

一個「模組管理框架」:本身不做任何具體業務邏輯,只負責把多個獨立的功能模組(plugin)組織在同一個殼裡。第一個模組是 [email-assist](../email-assist)(Gmail 整理助手)。

## 要解決什麼問題

klyve 手上會有不只一個「AI 幫忙審核/處理某件事」的小工具,每個工具都值得獨立開發、獨立測試、獨立部署(自己的 repo、自己的後端、自己的金鑰)。但使用起來應該像同一個 App:一個地方登入、一個地方切換「現在要看哪個模組」。AI-Auditor 就是那個共同的殼。

## 設計原則

1. **框架不懂模組的業務邏輯**,只認得「這是一個模組,它有一個可以嵌入的 UI」。
2. **加模組不用改框架核心**——理想上只需要在模組清單裡登記一筆。
3. **每個模組自己管金鑰**,框架不要求、也不儲存模組的後端金鑰(Gmail token、AI API key 等)。
4. **跨模組的事框架管,模組內部的事模組自己管**:跨模組導覽、手機版整體外殼 → 框架負責;模組自己的頁面切換、版面自適應 → 模組自己負責。

細節約定見 [`docs/plugin-contract.md`](docs/plugin-contract.md)。

## 目前掛載的模組

| 模組 | 說明 | Repo |
|---|---|---|
| email-assist | Gmail 整理助手:AI 判斷多餘信件,審核後移到垃圾桶或退訂 | [`~/prj/ai/email-assist`](../email-assist) |

掛載清單目前用 [`modules.json`](modules.json) 手動登記,見該檔案說明與尚未決定的問題。

## 技術棧

框架本體用 **Flutter**——跟 email-assist 前端同技術棧,才能把模組的 `Shell` widget 當套件直接 import 嵌進內容區,不用另外設計跨進程/webview 的嵌入機制。之後其他模組如果也想用「同進程 widget 嵌入」這條路,建議也用 Flutter 做前端;如果模組想用別的技術棧,則只能走獨立視窗或 webview 嵌入(見 plugin-contract 的「嵌入方式」一節)。

## 專案結構

```
ai-auditor/
├── README.md               本檔案
├── docs/
│   └── plugin-contract.md  模組怎麼被掛進框架(介面約定)
├── modules.json             目前掛載哪些模組、去哪裡找
└── host/                    框架本體(Flutter);尚未建立專案
```

## 現況

初始文檔階段,`host/` 底下的 Flutter 專案還沒建立。下一步：

1. `cd host && flutter create --platforms=macos,android --org com.klyve --project-name ai_auditor .`
2. 在 `host/pubspec.yaml` 加 email-assist 的 path dependency(`../../email-assist/app`),把它的 `Shell` 當套件 import。
3. 做左側模組選單 + 內容區(先只有 email-assist 一個項目也要留可擴充的架構)。
4. 設計手機版整體殼(見 plugin-contract 的開放問題)。

## 尚未決定的問題

見 [`docs/plugin-contract.md`](docs/plugin-contract.md#尚未決定的問題)。
