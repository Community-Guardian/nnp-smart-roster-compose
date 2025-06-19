# PowerShell Script to Convert Markdown Documents to Word (.docx)
# Prerequisites: Install Pandoc (https://pandoc.org/installing.html)

# Check if Pandoc is installed
Write-Host "Checking if Pandoc is installed..." -ForegroundColor Green
try {
    $pandocVersion = pandoc --version
    Write-Host "Pandoc is installed: $($pandocVersion[0])" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Pandoc is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Pandoc from: https://pandoc.org/installing.html" -ForegroundColor Yellow
    exit 1
}

# Define source and destination directories
$sourceDir = Split-Path -Parent $PSScriptRoot
$outputDir = $PSScriptRoot

Write-Host "Source Directory: $sourceDir" -ForegroundColor Cyan
Write-Host "Output Directory: $outputDir" -ForegroundColor Cyan

# Define the documents to convert
$documents = @(
    @{
        Source = "client-requirements-form.md"
        Output = "01-Client-Requirements-Form.docx"
        Title = "NNP Smart Roster - Client Requirements Form"
    },
    @{
        Source = "implementation-cost-analysis.md"
        Output = "02-Implementation-Cost-Analysis.docx"
        Title = "NNP Smart Roster - Implementation Cost Analysis"
    },
    @{
        Source = "technical-architecture-requirements.md"
        Output = "03-Technical-Architecture-Requirements.docx"
        Title = "NNP Smart Roster - Technical Architecture Requirements"
    },
    @{
        Source = "data-requirements-migration.md"
        Output = "04-Data-Requirements-Migration.docx"
        Title = "NNP Smart Roster - Data Requirements & Migration"
    },
    @{
        Source = "training-change-management.md"
        Output = "05-Training-Change-Management.docx"
        Title = "NNP Smart Roster - Training & Change Management"
    },
    @{
        Source = "deployment-go-live-strategy.md"
        Output = "06-Deployment-Go-Live-Strategy.docx"
        Title = "NNP Smart Roster - Deployment & Go-Live Strategy"
    },
    @{
        Source = "security-compliance-specifications.md"
        Output = "07-Security-Compliance-Specifications.docx"
        Title = "NNP Smart Roster - Security & Compliance Specifications"
    },
    @{
        Source = "system-features-functionality.md"
        Output = "08-System-Features-Functionality.docx"
        Title = "NNP Smart Roster - System Features & Functionality"
    }
)

Write-Host "`nStarting conversion process..." -ForegroundColor Green
Write-Host "=" * 50

$successCount = 0
$errorCount = 0

foreach ($doc in $documents) {
    $sourcePath = Join-Path $sourceDir $doc.Source
    $outputPath = Join-Path $outputDir $doc.Output
    
    Write-Host "`nConverting: $($doc.Source)" -ForegroundColor Cyan
    
    if (Test-Path $sourcePath) {
        try {
            # Convert with enhanced formatting options
            $pandocArgs = @(
                $sourcePath,
                "-o", $outputPath,
                "--from", "markdown",
                "--to", "docx",
                "--metadata", "title=$($doc.Title)",
                "--metadata", "author=NNP Smart Roster Team",
                "--metadata", "date=$(Get-Date -Format 'yyyy-MM-dd')",
                "--table-of-contents",
                "--toc-depth=3",
                "--number-sections",
                "--highlight-style=tango",
                "--reference-doc=reference-template.docx"
            )
            
            # Remove reference-doc if template doesn't exist
            $templatePath = Join-Path $outputDir "reference-template.docx"
            if (-not (Test-Path $templatePath)) {
                $pandocArgs = $pandocArgs | Where-Object { $_ -ne "--reference-doc=reference-template.docx" }
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

Write-Host "`n" + ("=" * 50)
Write-Host "Conversion Summary:" -ForegroundColor Yellow
Write-Host "✓ Successful conversions: $successCount" -ForegroundColor Green
Write-Host "✗ Failed conversions: $errorCount" -ForegroundColor Red

if ($successCount -gt 0) {
    Write-Host "`nWord documents created in: $outputDir" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Review and format the Word documents as needed" -ForegroundColor White
    Write-Host "2. Add company branding/logos" -ForegroundColor White
    Write-Host "3. Adjust styles and formatting" -ForegroundColor White
    Write-Host "4. Add signatures and approval sections" -ForegroundColor White
}

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
