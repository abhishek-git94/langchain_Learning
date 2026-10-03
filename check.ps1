# Notebook ka error pakadta hai aur .last_error.log me likhta hai - notebook ko chhedta nahi.
# Chalao:  .\check.ps1                                   -> DATAingestion.ipynb
#          .\check.ps1 3.3textsplitter.ipynb             -> jo notebook do
#          .\check.ps1 -Cell "from langchain import ..."  -> ek chhota snippet bhi check karo
#
# Iske baad opencode me bas "error check kar" likh do.
param(
  [Parameter(Position = 0)][string]$Notebook = "DATAingestion.ipynb",
  [string]$Cell,
  [switch]$Keep
)

$ErrorActionPreference = "Continue"
$py = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
$log = Join-Path $PSScriptRoot ".last_error.log"
$out = Join-Path $env:TEMP "nb-check-$PID.ipynb"

if (-not (Test-Path $py)) { Write-Host ".venv nahi mila. Pehle .\setup.ps1" -ForegroundColor Red; exit 1 }

function Save-Log([string]$text) {
  Set-Content -LiteralPath $log -Value $text -Encoding UTF8
  Write-Host "log likha: $log" -ForegroundColor DarkGray
}

# --- Case 1: ek chhota snippet ---
if ($Cell) {
  $tmp = Join-Path $env:TEMP "snippet-$PID.py"
  Set-Content -LiteralPath $tmp -Value $Cell -Encoding UTF8
  $r = & $py $tmp 2>&1 | Out-String
  if ($LASTEXITCODE -eq 0) {
    Write-Host "`nOK - koi error nahi." -ForegroundColor Green
    Save-Log "STATUS: OK (snippet chal gaya, koi error nahi)`n`n$Cell"
  } else {
    Write-Host "`nFAIL:" -ForegroundColor Red
    Write-Host $r
    Save-Log "STATUS: FAIL (snippet)`n`n--- CODE ---`n$Cell`n`n--- ERROR ---`n$r"
  }
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  exit $(if ($LASTEXITCODE -eq 0) { 0 } else { 1 })
}

# --- Case 2: pura notebook ---
if (-not (Test-Path $Notebook)) { Write-Host "Notebook nahi mila: $Notebook" -ForegroundColor Red; exit 1 }

Write-Host "Check kar raha hoon: $Notebook" -ForegroundColor Cyan
& $py -m nbconvert --to notebook --execute $Notebook --output $out --ExecutePreprocessor.timeout=300 2>&1 |
  Out-Null

if ($LASTEXITCODE -eq 0) {
  Write-Host "`nSab cells pass. Koi error nahi." -ForegroundColor Green
  Save-Log "STATUS: PASS - $Notebook ke saare cells bina error ke chal gaye."
  Remove-Item $out -Force -ErrorAction SilentlyContinue
  exit 0
}

# Notebook chal gaya -> asli error uske cells me hai (stderr, cell ka code, filename).
$pyCode = @'
import json, sys, os, re
src, out = sys.argv[1], sys.argv[2]
nb = json.load(open(src, encoding="utf-8"))
lines = ["STATUS: FAIL - %s" % os.path.basename(src), ""]
found = False
for i, c in enumerate(nb["cells"]):
    if c.get("cell_type") != "code":
        continue
    for o in c.get("outputs", []):
        if o.get("output_type") != "error":
            continue
        found = True
        lines += ["=" * 60, "CELL %d FAILED" % (i + 1), "=" * 60,
                  "Error : %s: %s" % (o.get("ename"), o.get("evalue")), "",
                  "--- cell code ---"]
        lines += c.get("source", [])
        lines += ["", "--- traceback ---"]
        for t in o.get("traceback", []):
            lines.append(re.sub(r"\x1b\[[0-9;]*m", "", t))
        lines.append("")
if not found:
    lines += ["Notebook fail hui par kisi cell me error output nahi mila.",
              "Shayad kernel crash / import-time error. Raw log dekho:", ""]
json.dump(lines, open(os.path.join(os.path.dirname(out), "check_lines.json"), "w", encoding="utf-8"))
print("CELLS_ERRORS_FOUND" if found else "NO_CELL_ERROR")
'@
$pyFile = Join-Path $env:TEMP "extract-$PID.py"
Set-Content -LiteralPath $pyFile -Value $pyCode -Encoding UTF8
$flag = & $py $pyFile $Notebook $out 2>&1 | Out-String

$linesFile = Join-Path $env:TEMP "check_lines.json"
if ((Test-Path $linesFile) -and $flag -match "CELLS_ERRORS_FOUND") {
  $lines = & $py -c "import json,sys; sys.stdout.write('\n'.join(json.load(open(sys.argv[1],encoding='utf-8'))))" $linesFile 2>&1 | Out-String
  Save-Log $lines
  Write-Host "`n$lines"
} else {
  Save-Log "STATUS: FAIL - $Notebook`n$flag"
  Write-Host "`nError log: $log" -ForegroundColor Red
}

Remove-Item $pyFile, $linesFile -Force -ErrorAction SilentlyContinue
if (-not $Keep) { Remove-Item $out -Force -ErrorAction SilentlyContinue }
exit 1
