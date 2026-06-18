# Obsidian Punctuation Normalizer

Codex skill for normalizing Chinese/Western punctuation in Obsidian Markdown notes while preserving Markdown and Obsidian syntax.

這是一個 **Codex skill**，用來協助 Codex 批次整理 Obsidian / Markdown 文件中的中文標點、半形/全形符號與局部空格。它不是 Obsidian community plugin，不會安裝到 Obsidian 的 plugins folder，也不會在 Obsidian UI 裡新增指令。

## What it does

- Converts CJK-context punctuation to Traditional Chinese typography, for example comma to ，, period to 。, question mark to ？.
- Converts Chinese-context parentheses and paired straight quotes where appropriate.
- Preserves Markdown and Obsidian structures such as YAML frontmatter, code blocks, inline code, Markdown links, images, wikilinks, embeds, tables, URLs, decimals, percentages, filenames, and English phrases.
- Runs a dry run first so Codex can inspect the planned changes before writing.

## Repository layout

    obsidian-punctuation-normalizer/
    ├── SKILL.md
    ├── agents/
    │   └── openai.yaml
    └── scripts/
        └── normalize_obsidian_punctuation.ps1

`SKILL.md` is the skill entrypoint read by Codex. The PowerShell script in `scripts/` is the deterministic bundled tool used by the skill.

## Installation

Clone this repository into your Codex skills directory:

    git clone https://github.com/meng0224/obsidian-punctuation-normalizer.git "$env:USERPROFILE\.codex\skills\obsidian-punctuation-normalizer"

Or manually copy the whole folder to:

    %USERPROFILE%\.codex\skills\obsidian-punctuation-normalizer

Restart Codex or reload skills if needed.

## Usage

Ask Codex to use the skill on a Markdown file or Obsidian vault folder, for example:

    Use $obsidian-punctuation-normalizer to normalize punctuation in this Obsidian Markdown folder.

The skill is designed to:

1. Inspect the target first.
2. Run a dry run.
3. Review whether the planned changes look safe.
4. Apply the normalization.
5. Verify Markdown / Obsidian syntax-sensitive areas.

## Direct script usage

You can also run the bundled script manually:

    & ".\scripts\normalize_obsidian_punctuation.ps1" -Path "C:\path\to\vault" -DryRun -VerboseReport

Apply changes after reviewing the dry-run output:

    & ".\scripts\normalize_obsidian_punctuation.ps1" -Path "C:\path\to\vault" -VerboseReport

Include subfolders when intended:

    & ".\scripts\normalize_obsidian_punctuation.ps1" -Path "C:\path\to\vault" -Recurse -DryRun -VerboseReport

## Notes

- Folder targets are non-recursive by default.
- Always prefer `-DryRun` before writing to a real vault.
- If the target is not tracked by Git, rollback depends on cloud sync history, file history, or backups.
- This tool normalizes punctuation and local spacing only; it is not intended to rewrite prose.

## License

MIT

