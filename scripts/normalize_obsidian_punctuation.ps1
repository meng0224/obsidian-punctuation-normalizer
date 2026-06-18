param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [switch]$Recurse,
    [switch]$DryRun,
    [switch]$VerboseReport
)

$ErrorActionPreference = 'Stop'

function Test-CjkChar([char]$Char) {
    $code = [int][char]$Char
    return (($code -ge 0x3400 -and $code -le 0x4DBF) -or
            ($code -ge 0x4E00 -and $code -le 0x9FFF) -or
            ($code -ge 0xF900 -and $code -le 0xFAFF))
}

function Test-CjkInString([string]$Text) {
    foreach ($char in $Text.ToCharArray()) {
        if (Test-CjkChar $char) { return $true }
    }
    return $false
}

function Get-PrevMeaningful([string]$Text, [int]$Index) {
    for ($i = $Index - 1; $i -ge 0; $i--) {
        $char = $Text[$i]
        if ([char]::IsWhiteSpace($char) -or '*_'.IndexOf($char) -ge 0) { continue }
        return $char
    }
    return [char]0
}

function Get-NextMeaningful([string]$Text, [int]$Index) {
    for ($i = $Index + 1; $i -lt $Text.Length; $i++) {
        $char = $Text[$i]
        if ([char]::IsWhiteSpace($char) -or '*_'.IndexOf($char) -ge 0) { continue }
        return $char
    }
    return [char]0
}

function Test-CjkContext([string]$Text, [int]$Index) {
    $prev = Get-PrevMeaningful $Text $Index
    $next = Get-NextMeaningful $Text $Index
    return (([int]$prev -ne 0 -and (Test-CjkChar $prev)) -or
            ([int]$next -ne 0 -and (Test-CjkChar $next)))
}

function Add-ProtectedSpan([System.Collections.Generic.List[string]]$Spans, [string]$Value) {
    $index = $Spans.Count
    $Spans.Add($Value) | Out-Null
    return ([string][char]0xE000) + $index.ToString() + ([string][char]0xE001)
}

function Protect-Spans([string]$Line, [ref]$Spans) {
    $result = $Line

    $result = [regex]::Replace($result, '^(\s*(?:>\s*)*)\d{1,9}[\.)](?=\s|$)', {
        param($match)
        return Add-ProtectedSpan $Spans.Value $match.Value
    })

    $patterns = [System.Collections.Generic.List[string]]::new()
    if ($result.IndexOf('`') -ge 0) {
        $patterns.Add('`[^`]*`') | Out-Null
    }
    if ($result.IndexOf('[[') -ge 0) {
        $patterns.Add('!\[\[[^\r\n\]]+\]\]') | Out-Null
        $patterns.Add('\[\[[^\r\n\]]+\]\]') | Out-Null
    }
    if ($result.IndexOf('](') -ge 0) {
        $patterns.Add('!\[[^\r\n\]]*\]\([^\r\n\)]*\)') | Out-Null
        $patterns.Add('\[[^\r\n\]]*\]\([^\r\n\)]*\)') | Out-Null
    }
    if ($result.IndexOf('http://') -ge 0 -or $result.IndexOf('https://') -ge 0) {
        $patterns.Add('https?://\S+') | Out-Null
    }

    foreach ($pattern in $patterns) {
        $result = [regex]::Replace($result, $pattern, {
            param($match)
            return Add-ProtectedSpan $Spans.Value $match.Value
        })
    }
    return $result
}

function Restore-Spans([string]$Line, [System.Collections.Generic.List[string]]$Spans) {
    return [regex]::Replace($Line, ([string][char]0xE000) + '(\d+)' + ([string][char]0xE001), {
        param($match)
        return $Spans[[int]$match.Groups[1].Value]
    })
}

function Normalize-Line([string]$Line) {
    if ($Line -notmatch '[,\.\?!;:\(\)"]') {
        return $Line
    }

    if ($Line -match '^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$') {
        return $Line
    }

    $spans = [System.Collections.Generic.List[string]]::new()
    $work = Protect-Spans $Line ([ref]$spans)
    $chars = $work.ToCharArray()

    for ($i = 0; $i -lt $chars.Length; $i++) {
        if ($chars[$i] -eq [char]0xE000) {
            while ($i -lt $chars.Length -and $chars[$i] -ne [char]0xE001) { $i++ }
            continue
        }

        if (Test-CjkContext $work $i) {
            switch ($chars[$i]) {
                ',' { $chars[$i] = '，'; continue }
                '.' { $chars[$i] = '。'; continue }
                '?' { $chars[$i] = '？'; continue }
                '!' { $chars[$i] = '！'; continue }
                ';' { $chars[$i] = '；'; continue }
                ':' { $chars[$i] = '：'; continue }
            }
        }
    }

    $work = -join $chars
    $work = [regex]::Replace($work, '([，。！？；：])\s+(?=[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF])', '$1')

    $work = [regex]::Replace($work, '\(([^\(\)\r\n]{1,120})\)', {
        param($match)
        $before = if ($match.Index -gt 0) { Get-PrevMeaningful $work $match.Index } else { [char]0 }
        $afterIndex = $match.Index + $match.Length - 1
        $after = if ($afterIndex + 1 -lt $work.Length) { Get-NextMeaningful $work $afterIndex } else { [char]0 }
        $inner = $match.Groups[1].Value
        $hasCjk = Test-CjkInString $inner
        $cjkContext = (([int]$before -ne 0 -and (Test-CjkChar $before)) -or
                       ([int]$after -ne 0 -and (Test-CjkChar $after)))

        if ($hasCjk -or $cjkContext) { return '（' + $inner + '）' }
        return $match.Value
    })

    $work = [regex]::Replace($work, '([\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF）])\:\*\*', '$1：**')
    $work = [regex]::Replace($work, '(^\s*>\s*)\((?=.*[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF])', '$1（')
    $work = [regex]::Replace($work, '(^\s*)\((?=.*[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF])', '$1（')
    $work = [regex]::Replace($work, '([\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF。！？；，、」』])\)(\s*)$', '$1）$2')
    $work = [regex]::Replace($work, '"([^"\r\n]*[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF][^"\r\n]*)"', '「$1」')

    return Restore-Spans $work $spans
}

function Get-MarkdownFiles([string]$TargetPath, [bool]$Recursive) {
    $resolved = Resolve-Path -LiteralPath $TargetPath
    $item = Get-Item -LiteralPath $resolved

    if ($item.PSIsContainer) {
        $params = @{
            LiteralPath = $item.FullName
            Filter = '*.md'
            File = $true
        }
        if ($Recursive) { $params.Recurse = $true }
        return @(Get-ChildItem @params)
    }

    if ($item.Extension -ne '.md') {
        throw "Target file is not a Markdown file: $($item.FullName)"
    }
    return @($item)
}

function Normalize-File([System.IO.FileInfo]$File, [bool]$WriteChanges) {
    $utf8Strict = [System.Text.UTF8Encoding]::new($false, $true)
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $text = [System.IO.File]::ReadAllText($File.FullName, $utf8Strict)
    $parts = [regex]::Split($text, '(?<=\r\n|\n)')
    $out = [System.Collections.Generic.List[string]]::new()

    $inFence = $false
    $inFrontmatter = $false
    $lineNo = 0

    foreach ($part in $parts) {
        if ($part.Length -eq 0) { continue }
        $lineNo++
        $line = $part
        $eol = ''

        if ($line.EndsWith("`r`n")) {
            $eol = "`r`n"
            $line = $line.Substring(0, $line.Length - 2)
        } elseif ($line.EndsWith("`n")) {
            $eol = "`n"
            $line = $line.Substring(0, $line.Length - 1)
        }

        if ($lineNo -eq 1 -and $line -eq '---') {
            $inFrontmatter = $true
            $out.Add($line + $eol) | Out-Null
            continue
        } elseif ($inFrontmatter -and $line -eq '---') {
            $inFrontmatter = $false
            $out.Add($line + $eol) | Out-Null
            continue
        }

        if ($inFrontmatter) {
            $line = [regex]::Replace($line, '^(\s*[A-Za-z_][A-Za-z0-9_-]*)：(\s*)', '$1:$2')
            $out.Add($line + $eol) | Out-Null
            continue
        }

        if ($line -match '^\s*(```|~~~)') {
            $out.Add($line + $eol) | Out-Null
            $inFence = -not $inFence
            continue
        }

        if ($inFence) {
            $out.Add($line + $eol) | Out-Null
        } else {
            $out.Add((Normalize-Line $line) + $eol) | Out-Null
        }
    }

    $newText = -join $out
    $changed = $newText -ne $text
    if ($changed -and $WriteChanges) {
        [System.IO.File]::WriteAllText($File.FullName, $newText, $utf8NoBom)
    }

    return [pscustomobject]@{
        Path = $File.FullName
        Changed = $changed
    }
}

function Get-SuspiciousMatches([System.IO.FileInfo[]]$Files, [int]$Limit = 20) {
    $found = [System.Collections.Generic.List[object]]::new()

    foreach ($file in $Files) {
        $lines = [System.IO.File]::ReadAllLines($file.FullName, [System.Text.UTF8Encoding]::new($false, $true))
        $inFence = $false
        $inFrontmatter = $false

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lineNo = $i + 1
            $line = $lines[$i]

            if ($lineNo -eq 1 -and $line -eq '---') {
                $inFrontmatter = $true
                continue
            } elseif ($inFrontmatter -and $line -eq '---') {
                $inFrontmatter = $false
                continue
            }

            if ($inFrontmatter) {
                if ($line -match '^\s*[A-Za-z_][A-Za-z0-9_-]*：') {
                    $found.Add([pscustomobject]@{ Path = $file.FullName; LineNumber = $lineNo; Line = $line }) | Out-Null
                }
                continue
            }

            if ($line -match '^\s*(```|~~~)') {
                $inFence = -not $inFence
                continue
            }
            if ($inFence) { continue }

            $spans = [System.Collections.Generic.List[string]]::new()
            $scanLine = Protect-Spans $line ([ref]$spans)
            if ($scanLine -match '[\u4e00-\u9fff][,\.\?!;:\(\)]|[,\.\?!;:\(\)][\u4e00-\u9fff]|\*\*[^\r\n]*:\*\*|:\*\*') {
                $found.Add([pscustomobject]@{ Path = $file.FullName; LineNumber = $lineNo; Line = $line }) | Out-Null
            }

            if ($found.Count -ge $Limit) { return $found.ToArray() }
        }
    }

    return $found.ToArray()
}

$files = Get-MarkdownFiles $Path $Recurse.IsPresent
$writeChanges = -not $DryRun.IsPresent
$results = foreach ($file in $files) {
    Normalize-File $file $writeChanges
}

$changedFiles = @($results | Where-Object { $_.Changed })

if ($VerboseReport) {
    Write-Output "Mode=$(@('Write','DryRun')[$DryRun.IsPresent])"
    Write-Output "Files=$($files.Count)"
    Write-Output "Changed=$($changedFiles.Count)"
    foreach ($result in $changedFiles) {
        Write-Output "CHANGED $($result.Path)"
    }

    $scanTargets = if ($DryRun) { $files } else { $changedFiles | ForEach-Object { Get-Item -LiteralPath $_.Path } }
    if (-not $DryRun -and $scanTargets.Count -gt 0) {
        $remaining = Get-SuspiciousMatches @($scanTargets) 20
        if ($remaining) {
            Write-Output 'ValidationHints=remaining suspicious matches found; inspect these before finalizing:'
            $remaining | ForEach-Object { Write-Output "$($_.Path):$($_.LineNumber): $($_.Line)" }
        } else {
            Write-Output 'ValidationHints=no suspicious CJK-adjacent halfwidth punctuation or YAML fullwidth-key matches in changed files'
        }
    }
} else {
    Write-Output "Files=$($files.Count) Changed=$($changedFiles.Count) DryRun=$($DryRun.IsPresent)"
}
