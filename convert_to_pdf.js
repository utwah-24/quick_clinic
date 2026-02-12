// Markdown to PDF Converter Script
// Converts SYSTEM_ARCHITECTURE.md to PDF

const fs = require('fs');
const path = require('path');

// Check if md-to-pdf is available, if not provide instructions
try {
  const mdToPdf = require('md-to-pdf');
  
  async function convertToPdf() {
    const markdownFile = path.join(__dirname, 'SYSTEM_ARCHITECTURE.md');
    const outputFile = path.join(__dirname, 'SYSTEM_ARCHITECTURE.pdf');
    
    if (!fs.existsSync(markdownFile)) {
      console.error('Error: SYSTEM_ARCHITECTURE.md not found!');
      process.exit(1);
    }
    
    console.log('Converting SYSTEM_ARCHITECTURE.md to PDF...');
    
    try {
      const pdf = await mdToPdf({ path: markdownFile }, {
        dest: outputFile,
        pdf_options: {
          format: 'A4',
          margin: {
            top: '20mm',
            right: '15mm',
            bottom: '20mm',
            left: '15mm'
          },
          printBackground: true
        },
        stylesheet: `
          body {
            font-family: 'Segoe UI', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
          }
          h1 {
            color: #0B2D5B;
            border-bottom: 3px solid #0B2D5B;
            padding-bottom: 10px;
          }
          h2 {
            color: #0B2D5B;
            margin-top: 30px;
            border-bottom: 2px solid #e0e0e0;
            padding-bottom: 5px;
          }
          h3 {
            color: #555;
            margin-top: 20px;
          }
          code {
            background-color: #f4f4f4;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
          }
          pre {
            background-color: #f4f4f4;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
          }
          table {
            border-collapse: collapse;
            width: 100%;
            margin: 15px 0;
          }
          th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
          }
          th {
            background-color: #0B2D5B;
            color: white;
          }
        `
      });
      
      if (pdf) {
        console.log(`✅ Successfully created: ${outputFile}`);
      } else {
        console.error('Error: PDF conversion failed');
        process.exit(1);
      }
    } catch (error) {
      console.error('Error during conversion:', error.message);
      process.exit(1);
    }
  }
  
  convertToPdf();
  
} catch (error) {
  console.log('md-to-pdf package not found. Installing...');
  console.log('\nPlease run the following commands:');
  console.log('  npm install -g md-to-pdf');
  console.log('  node convert_to_pdf.js');
  console.log('\nOr use one of these alternative methods:');
  console.log('\n1. Online converter:');
  console.log('   - Visit https://www.markdowntopdf.com/');
  console.log('   - Upload SYSTEM_ARCHITECTURE.md');
  console.log('   - Download the PDF');
  console.log('\n2. VS Code extension:');
  console.log('   - Install "Markdown PDF" extension');
  console.log('   - Open SYSTEM_ARCHITECTURE.md');
  console.log('   - Right-click → "Markdown PDF: Export (pdf)"');
  console.log('\n3. Pandoc (if installed):');
  console.log('   pandoc SYSTEM_ARCHITECTURE.md -o SYSTEM_ARCHITECTURE.pdf');
}
