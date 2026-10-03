# Notebook ko terminal se poora chalata hai (fresh kernel, top se bottom tak).
# Chalao:  .\run.ps1                              -> DATAingestion.ipynb chalta hai
#          .\run.ps1 3.3textsplitter.ipynb        -> jo notebook do wahi chalta hai
#          .\run.ps1 3.3textsplitter.ipynb -NoSave -> sirf check, notebook chhedta nahi
param([string]$Notebook = "DATAingestion.ipynb", [switch]$NoSave)

$py = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
$nb = if ([System.IO.Path]::IsPathRooted($Notebook)) { $Notebook } else { Join-Path $PSScriptRoot $Notebook }

if (-not (Test-Path $py)) { Write-Host ".venv\Scripts\python.exe nahi mila. Pehle .\setup.ps1 chalao." -ForegroundColor Red; exit 1 }
if (-not (Test-Path $nb)) { Write-Host "Notebook nahi mila: $nb" -ForegroundColor Red; exit 1 }

$hasNbconvert = & $py -c "import importlib.util,sys; sys.stdout.write('1' if importlib.util.find_spec('nbconvert') else '0')"
if ($hasNbconvert -ne "1") {
    Write-Host "nbconvert install kar raha hoon..." -ForegroundColor Cyan
    & $py -m pip install nbconvert --quiet
}

Write-Host "Running $(Split-Path $nb -Leaf) ..." -ForegroundColor Cyan
$args = @("-m", "nbconvert", "--to", "notebook", "--execute", $nb, "--ExecutePreprocessor.timeout=300")
if ($NoSave) {
    $out = Join-Path $env:TEMP "nb-run-check.ipynb"
    $args += @("--output", $out)
} else {
    $args += "--inplace"
}
& $py @args

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSaare cells bina error ke chal gaye." -ForegroundColor Green
} else {
    Write-Host "`nKoi cell fail hua - upar traceback dekho." -ForegroundColor Red
    exit 1
}
