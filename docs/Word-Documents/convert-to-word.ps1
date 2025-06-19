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

# Define source and destination directories
$sourceDir = Split-Path -Parent $PSScriptRoot
$outputDir = $PSScriptRoot

Write-Host "Source Directory: $sourceDir" -ForegroundColor Cyan
Write-Host "Output Directory: $outputDir" -ForegroundColor Cyan

# Documents to convert
$documents = @(
    @{ Source = "client-requirements-form.md"; Output = "01-Client-Requirements-Form.docx"; Title = "Signox LogX - Client Requirements Form" },
    @{ Source = "implementation-cost-analysis.md"; Output = "02-Implementation-Cost-Analysis.docx"; Title = "Signox LogX - Implementation Cost Analysis" },
    @{ Source = "technical-architecture-requirements.md"; Output = "03-Technical-Architecture-Requirements.docx"; Title = "Signox LogX - Technical Architecture Requirements" },
    @{ Source = "data-requirements-migration.md"; Output = "04-Data-Requirements-Migration.docx"; Title = "Signox LogX - Data Requirements & Migration" },
    @{ Source = "training-change-management.md"; Output = "05-Training-Change-Management.docx"; Title = "Signox LogX - Training & Change Management" },
    @{ Source = "deployment-go-live-strategy.md"; Output = "06-Deployment-Go-Live-Strategy.docx"; Title = "Signox LogX - Deployment & Go-Live Strategy" },
    @{ Source = "security-compliance-specifications.md"; Output = "07-Security-Compliance-Specifications.docx"; Title = "Signox LogX - Security & Compliance Specifications" },
    @{ Source = "system-features-functionality.md"; Output = "08-System-Features-Functionality.docx"; Title = "Signox LogX - System Features & Functionality" }
)

Write-Host "`nStarting conversion process..." -ForegroundColor Green
Write-Host ("=" * 50)

$successCount = 0
$errorCount = 0

foreach ($doc in $documents) {
    $sourcePath = Join-Path $sourceDir $doc.Source
    $outputPath = Join-Path $outputDir $doc.Output

    Write-Host "`nConverting: $($doc.Source)" -ForegroundColor Cyan

    if (Test-Path $sourcePath) {
        try {
            $pandocArgs = @(
                $sourcePath
                "-o", $outputPath
                "--from=markdown"
                "--to=docx"
                "--metadata=title:$($doc.Title)"
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
                Write-Host "✓ Successfully created: $($doc.Output)" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "✗ Failed to create: $($doc.Output)" -ForegroundColor Red
                $errorCount++
            }
        } catch {
            Write-Host "✗ Error converting $($doc.Source): $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    } else {
        Write-Host "✗ Source file not found: $($doc.Source)" -ForegroundColor Red
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
