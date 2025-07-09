# Pandoc Installation Guide for Windows

## Method 1: Download Installer (Recommended)

1. **Visit**: https://pandoc.org/installing.html
2. **Download**: Windows installer (.msi file)
3. **Run**: The installer with administrator privileges
4. **Verify**: Open PowerShell and run `pandoc --version`

## Method 2: Using Chocolatey

If you have Chocolatey installed:
```powershell
choco install pandoc
```

## Method 3: Using Winget

If you have Windows Package Manager:
```powershell
winget install JohnMacFarlane.Pandoc
```

## Method 4: Using Scoop

If you have Scoop installed:
```powershell
scoop install pandoc
```

## Verification

After installation, verify Pandoc is working:
```powershell
pandoc --version
```

You should see output similar to:
```
pandoc 3.1.8
Features: +server +lua
Scripting engine: Lua 5.4
User data directory: C:\Users\[username]\AppData\Roaming\pandoc
```

## Troubleshooting

### Issue: "pandoc is not recognized"
**Solution**: Add Pandoc to your PATH environment variable:
1. Open System Properties > Environment Variables
2. Add Pandoc installation directory to PATH
3. Restart PowerShell/Command Prompt

### Issue: Conversion fails
**Solution**: 
1. Ensure source Markdown files exist
2. Check file permissions
3. Verify output directory is writable

## Alternative Tools

If you prefer not to use Pandoc:

1. **Typora**: Markdown editor with export to Word
2. **Mark Text**: Another Markdown editor with export options
3. **Online converters**: Various web-based conversion tools
4. **VS Code extensions**: Markdown to Word extensions

## Next Steps

Once Pandoc is installed:
1. Navigate to the Word-Documents folder
2. Double-click `convert-to-word.bat`
3. Wait for conversion to complete
4. Open the generated .docx files in Microsoft Word
