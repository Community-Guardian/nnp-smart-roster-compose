# Simple PowerShell Script to Convert .md Files to .docx Using Pandoc
# Prerequisite: Pandoc must be installed and available in PATH

# Get the folder this script is running from
$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Find all Markdown files in this folder
$mdFiles = Get-ChildItem -Path $sourceDir -Filter *.md

# Exit if no markdown files found
if ($mdFiles.Count -eq 0) {
    Write-Host "No markdown files found in $sourceDir" -ForegroundColor Red
    exit 1
}

# Convert each markdown file
foreach ($file in $mdFiles) {
    $mdPath = $file.FullName
    $docxPath = [System.IO.Path]::ChangeExtension($mdPath, ".docx")

    Write-Host "Converting $($file.Name) to Word..."

    & pandoc $mdPath -o $docxPath

    if (Test-Path $docxPath) {
        Write-Host "✓ Created: $($file.BaseName).docx" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to convert: $($file.Name)" -ForegroundColor Red
    }
}
