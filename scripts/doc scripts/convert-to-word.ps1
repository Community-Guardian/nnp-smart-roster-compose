# PowerShell Script to Convert Markdown Documents to Word (.docx)
# Prerequisites: Install Pandoc (https://pandoc.org/installing.html)

# Ensure script context
if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Check if Pandoc is available
Write-Host "Checking if Pandoc is installed..." -ForegroundColor Green
if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Pandoc is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Pandoc from: https://pandoc.org/installing.html" -ForegroundColor Yellow
    exit 1
}
Write-Host "Pandoc is installed." -ForegroundColor Green

# Prompt for source directory or use script directory
$sourceDir = Read-Host "Enter the path to the folder containing .md files (leave blank for script directory)"
if ([string]::IsNullOrWhiteSpace($sourceDir)) {
    $sourceDir = $PSScriptRoot
}
$outputDir = $sourceDir

Write-Host "Source Directory: $sourceDir" -ForegroundColor Cyan
Write-Host "Output Directory: $outputDir" -ForegroundColor Cyan

# Find all .md files (recursively)
$mdFiles = Get-ChildItem -Path $sourceDir -Recurse -Filter *.md | Where-Object { -not $_.PSIsContainer }
if ($mdFiles.Count -eq 0) {
    Write-Host "No .md files found in $sourceDir" -ForegroundColor Red
    exit 1
}

Write-Host "`nStarting conversion process..." -ForegroundColor Green
Write-Host ("=" * 50)

$successCount = 0
$errorCount = 0

foreach ($file in $mdFiles) {
    $sourcePath = $file.FullName
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $outputPath = Join-Path $outputDir ("$baseName.docx")
    $title = ($baseName -replace "[-_]", " ") -replace "([a-z])([A-Z])", '$1 $2'
    $title = ($title.Substring(0,1).ToUpper() + $title.Substring(1))

    Write-Host "`nConverting: $($file.Name)" -ForegroundColor Cyan

    try {
        $pandocArgs = @(
            $sourcePath
            "-o", $outputPath
            "--from=markdown"
            "--to=docx"
            "--metadata=title:$title"
            "--metadata=author:Signox LogX Team"
            "--metadata=date:$(Get-Date -Format 'yyyy-MM-dd')"
            "--table-of-contents"
            "--toc-depth=3"
            "--number-sections"
            "--highlight-style=tango"
        )

        $templatePath = Join-Path $outputDir "reference-template.docx"
        if (Test-Path $templatePath) {
            $pandocArgs += "--reference-doc=$templatePath"
        }

        & pandoc @pandocArgs

        if (Test-Path $outputPath) {
            Write-Host "✓ Successfully created: $($baseName).docx" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "✗ Failed to create: $($baseName).docx" -ForegroundColor Red
            $errorCount++
        }
    } catch {
        Write-Host "✗ Error converting $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "`n$("=" * 50)"
Write-Host "Conversion Summary:" -ForegroundColor Yellow
Write-Host "✓ Successful conversions: $successCount" -ForegroundColor Green
Write-Host "✗ Failed conversions: $errorCount" -ForegroundColor Red

if ($successCount -gt 0) {
    Write-Host "`nWord documents created in: $outputDir" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Review and format the Word documents as needed"
    Write-Host "2. Add company branding/logos"
    Write-Host "3. Adjust styles and formatting"
    Write-Host "4. Add signatures and approval sections"
}

# Optional pause for interactive use only
if ($Host.Name -eq "ConsoleHost") {
    Write-Host "`nPress any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
