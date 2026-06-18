---
name: obsidian-punctuation-normalizer
description: Normalize Chinese/Western punctuation in Obsidian or Markdown files. Use when asked to 整理 Obsidian/Markdown 文件標點, 中西標點正規化, 中文標點, 全形/半形標點, 標點潤稿, 批次整理資料夾文件, or to fix punctuation across Traditional Chinese Markdown notes while preserving Markdown and Obsidian syntax.
---

# Obsidian Punctuation Normalizer

Use this skill to normalize punctuation in Traditional Chinese Obsidian/Markdown notes without rewriting prose.

## Default Behavior

- Normalize only punctuation and local spacing/quote marks. Do not change wording, terminology, section order, or content.
- Prefer Chinese typography in Chinese prose:
  - `,` -> `，`
  - `.` -> `。`
  - `?` -> `？`
  - `!` -> `！`
  - `;` -> `；`
  - `:` -> `：`
  - Chinese-context `( ... )` -> `（ ... ）`
  - paired straight quotes around Chinese text -> `「...」`
- Keep Western punctuation where it is structural or technical:
  - YAML frontmatter keys, Markdown syntax, Markdown tables, URLs.
  - fenced code blocks and inline code.
  - Obsidian wikilinks and embeds such as `[[Note]]` and `![[image.png|300]]`.
  - Markdown links and image links.
  - English names/phrases, grade codes, decimals, percentages, numeric ranges, and filenames such as `.png`.
- Keep Chinese term + English gloss style as fullwidth parentheses: `總會長（Guild Grandmaster）`.

## Workflow

1. Resolve the target path from the user request. If no path is supplied, use the current workspace folder.
2. Inspect before mutating:
   - Count target `.md` files.
   - Check whether the target is inside a git repo.
   - If not in git, mention that rollback depends on cloud sync/history or manual backups.
3. Run a dry run first:

```powershell
& "$env:USERPROFILE\.codex\skills\obsidian-punctuation-normalizer\scripts\normalize_obsidian_punctuation.ps1" -Path "<target>" -DryRun -VerboseReport
```

4. If the dry-run report is reasonable, run the actual normalization:

```powershell
& "$env:USERPROFILE\.codex\skills\obsidian-punctuation-normalizer\scripts\normalize_obsidian_punctuation.ps1" -Path "<target>" -VerboseReport
```

5. Verify after writing:
   - Search for remaining CJK-adjacent halfwidth punctuation.
   - Search for YAML keys accidentally using `：`.
   - Spot-check at least one regular prose note, one large note, one table-heavy note, one note with code blocks or diagrams, one note with Obsidian embeds, and `Index.md` if present.

## Script Notes

- The bundled script accepts:
  - `-Path <folder-or-file>`: target Markdown file or folder.
  - `-Recurse`: include subfolders when the target is a folder.
  - `-DryRun`: report changes without writing.
  - `-VerboseReport`: print file-level change information and validation hints.
- Folder targets are non-recursive by default. Use `-Recurse` only when the user clearly wants nested folders.
- If a dry run reports suspicious changes in frontmatter, links, embeds, or tables, inspect samples before writing.
