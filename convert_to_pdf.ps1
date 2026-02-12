# PowerShell script to convert SYSTEM_ARCHITECTURE.md to PDF
# This script provides multiple conversion options

Write-Host "=== Markdown to PDF Converter ===" -ForegroundColor Cyan
Write-Host ""

$markdownFile = "SYSTEM_ARCHITECTURE.md"
$pdfFile = "SYSTEM_ARCHITECTURE.pdf"

if (-not (Test-Path $markdownFile)) {
    Write-Host "Error: $markdownFile not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Found: $markdownFile" -ForegroundColor Green
Write-Host ""

# Method 1: Check for Node.js and md-to-pdf
Write-Host "Method 1: Using Node.js (md-to-pdf)" -ForegroundColor Yellow
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "  Node.js found!" -ForegroundColor Green
    
    # Check if md-to-pdf is installed globally
    $mdToPdfInstalled = npm list -g md-to-pdf 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  md-to-pdf is installed. Converting..." -ForegroundColor Green
        node convert_to_pdf.js
    } else {
        Write-Host "  Installing md-to-pdf..." -ForegroundColor Yellow
        npm install -g md-to-pdf
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Converting..." -ForegroundColor Green
            node convert_to_pdf.js
        } else {
            Write-Host "  Installation failed. Try manual installation:" -ForegroundColor Red
            Write-Host "    npm install -g md-to-pdf" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  Node.js not found. Skipping this method." -ForegroundColor Gray
}

Write-Host ""

# Method 2: Check for Pandoc
Write-Host "Method 2: Using Pandoc" -ForegroundColor Yellow
if (Get-Command pandoc -ErrorAction SilentlyContinue) {
    Write-Host "  Pandoc found! Converting..." -ForegroundColor Green
    pandoc $markdownFile -o $pdfFile --pdf-engine=xelatex -V geometry:margin=1in
    if (Test-Path $pdfFile) {
        Write-Host "  ✅ Successfully created: $pdfFile" -ForegroundColor Green
    }
} else {
    Write-Host "  Pandoc not found. Install from: https://pandoc.org/installing.html" -ForegroundColor Gray
}

Write-Host ""

# Method 3: Provide manual instructions
Write-Host "Method 3: Manual Conversion Options" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option A - VS Code Extension:" -ForegroundColor Cyan
Write-Host "  1. Install 'Markdown PDF' extension in VS Code" -ForegroundColor White
Write-Host "  2. Open SYSTEM_ARCHITECTURE.md" -ForegroundColor White
Write-Host "  3. Right-click → 'Markdown PDF: Export (pdf)'" -ForegroundColor White
Write-Host ""
Write-Host "Option B - Online Converter:" -ForegroundColor Cyan
Write-Host "  1. Visit: https://www.markdowntopdf.com/" -ForegroundColor White
Write-Host "  2. Upload SYSTEM_ARCHITECTURE.md" -ForegroundColor White
Write-Host "  3. Download the PDF" -ForegroundColor White
Write-Host ""
Write-Host "Option C - Chrome/Edge Browser:" -ForegroundColor Cyan
Write-Host "  1. Install 'Markdown Preview Plus' extension" -ForegroundColor White
Write-Host "  2. Open SYSTEM_ARCHITECTURE.md" -ForegroundColor White
Write-Host "  3. Print to PDF (Ctrl+P → Save as PDF)" -ForegroundColor White
Write-Host ""

if (Test-Path $pdfFile) {
    Write-Host "✅ PDF file created successfully: $pdfFile" -ForegroundColor Green
    Write-Host "   Location: $(Resolve-Path $pdfFile)" -ForegroundColor Gray
} else {
    Write-Host "⚠ PDF file not created. Please use one of the methods above." -ForegroundColor Yellow
}
