# Obsidian Punctuation Normalizer

用於整理 Obsidian / Markdown 文件標點的 Codex skill。它會在保留 Markdown 與 Obsidian 語法的前提下，正規化中文與西文標點。

這是一個 **Codex skill**，用來協助 Codex 批次整理 Obsidian / Markdown 文件中的中文標點、半形/全形符號與局部空格。它不是 Obsidian community plugin，不會安裝到 Obsidian 的 plugins folder，也不會在 Obsidian UI 裡新增指令。

## 功能

- 將中文語境中的標點轉成台灣繁中常用排版，例如半形逗號轉成 `，`、半形句號轉成 `。`、半形問號轉成 `？`。
- 依中文語境轉換括號與成對引號。
- 保留 Markdown 與 Obsidian 結構，例如 YAML frontmatter、code blocks、inline code、Markdown links、images、wikilinks、embeds、tables、URLs、小數、百分比、檔名與英文片語。
- 先執行 dry run，讓 Codex 在真正寫入前檢查預計變更。

## 專案結構

    obsidian-punctuation-normalizer/
    ├── SKILL.md
    ├── agents/
    │   └── openai.yaml
    └── scripts/
        └── normalize_obsidian_punctuation.ps1

`SKILL.md` 是 Codex 讀取的 skill 入口。`scripts/` 裡的 PowerShell 腳本是這個 skill 會呼叫的 deterministic bundled tool。

## 安裝方式

將這個 repository clone 到你的 Codex skills 目錄：

    git clone https://github.com/meng0224/obsidian-punctuation-normalizer.git "$env:USERPROFILE\.codex\skills\obsidian-punctuation-normalizer"

也可以手動把整個資料夾複製到：

    %USERPROFILE%\.codex\skills\obsidian-punctuation-normalizer

必要時重新啟動 Codex，或重新載入 skills。

## 使用方式

請 Codex 對某個 Markdown 檔案或 Obsidian vault 資料夾使用這個 skill，例如：

    Use $obsidian-punctuation-normalizer to normalize punctuation in this Obsidian Markdown folder.

這個 skill 的預期流程是：

1. 先檢查目標路徑。
2. 先跑 dry run。
3. 檢查預計變更是否安全。
4. 套用標點正規化。
5. 驗證 Markdown / Obsidian 語法敏感區域沒有被破壞。

## 直接執行腳本

你也可以手動執行 bundled script：

    & ".\scripts\normalize_obsidian_punctuation.ps1" -Path "C:\path\to\vault" -DryRun -VerboseReport

確認 dry-run 輸出合理後，再套用變更：

    & ".\scripts\normalize_obsidian_punctuation.ps1" -Path "C:\path\to\vault" -VerboseReport

如果確定要包含子資料夾，加入 `-Recurse`：

    & ".\scripts\normalize_obsidian_punctuation.ps1" -Path "C:\path\to\vault" -Recurse -DryRun -VerboseReport

## 注意事項

- 資料夾目標預設不會遞迴處理子資料夾。
- 對真實 vault 寫入前，建議一律先使用 `-DryRun`。
- 如果目標沒有 Git 版本控管，回復變更會依賴雲端同步歷史、檔案歷程或備份。
- 這個工具只正規化標點與局部空格，不會改寫文章內容。

## 授權

MIT

