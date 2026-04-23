# split-docs.ps1
# Splits llms-full.txt into individual .md files in docs/swiftlys2/
# Each section starts with: # Title (/docs/path)

$inputFile = Join-Path $PSScriptRoot "docs\llms-full.txt"
$outputDir = Join-Path $PSScriptRoot "docs\swiftlys2"

if (-not (Test-Path $inputFile)) {
    Write-Error "Input file not found: $inputFile"
    exit 1
}

# Ensure output directory exists
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$content = Get-Content $inputFile -Raw
# Regex: match lines like "# Some Title (/docs/some/path)"
$sectionPattern = '(?m)^# .+? \(/[^)]+\)'

$sections = [regex]::Matches($content, $sectionPattern)

if ($sections.Count -eq 0) {
    Write-Error "No sections found in $inputFile"
    exit 1
}

Write-Host "Found $($sections.Count) section(s) in llms-full.txt"

$filesWritten = 0

for ($i = 0; $i -lt $sections.Count; $i++) {
    $section = $sections[$i]
    $startIndex = $section.Index

    # End index is the start of the next section, or end of file
    if ($i -lt $sections.Count - 1) {
        $endIndex = $sections[$i + 1].Index
    } else {
        $endIndex = $content.Length
    }

    $sectionContent = $content.Substring($startIndex, $endIndex - $startIndex).TrimEnd()

    # Extract the path from the header, e.g. "# Title (/docs/development/commands)" -> "/docs/development/commands"
    $pathMatch = [regex]::Match($section.Value, '\((/[^)]+)\)')
    if ($pathMatch.Success) {
        $docPath = $pathMatch.Groups[1].Value
    } else {
        Write-Warning "Could not extract path from: $($section.Value)"
        continue
    }

    # Derive filename from path
    if ($docPath -eq "/docs") {
        $fileName = "introduction.md"
    } else {
        # Strip leading "/" and replace "/" with "-"
        $fileName = ($docPath.TrimStart("/") -replace "/", "-") + ".md"
    }

    $outputPath = Join-Path $outputDir $fileName
    Set-Content -Path $outputPath -Value $sectionContent -Encoding UTF8 -NoNewline
    $filesWritten++
    Write-Host "  Written: $fileName"
}

Write-Host "`nDone. $filesWritten file(s) written to $outputDir"
