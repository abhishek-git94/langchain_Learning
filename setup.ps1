# Setup: env ke saare packages install karta hai aur Jupyter kernel register karta hai.
# Chalao:  .\setup.ps1
# "Stop" yahan use mat karna: PS 5.1 me native exe ka stderr bhi terminating error ban jaata hai,
# aur pip apna "new release available" notice stderr par likhta hai -> script bewajah fail ho jaati hai.
# Isliye har native call ke baad $LASTEXITCODE khud check karte hain.
$ErrorActionPreference = "Continue"
$py = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $py)) {
    Write-Host ".venv\Scripts\python.exe nahi mila. Pehle env banao:" -ForegroundColor Red
    Write-Host "  py -3.12 -m venv .venv"
    exit 1
}

# NOTE: pip ka self-upgrade yahan jaan-boojh kar nahi hai. Project Dropbox ke andar hai,
# aur sync beech me files lock kar deta hai -> `pip install --upgrade pip` WinError 32 de kar
# pip ko hi tod chuka hai. Upgrade karna ho to Dropbox pause karke alag se karna.
Write-Host "`n[1/2] requirement.txt install..." -ForegroundColor Cyan
& $py -m pip install -r (Join-Path $PSScriptRoot "requirement.txt")
if ($LASTEXITCODE -ne 0) { Write-Host "pip install fail hua." -ForegroundColor Red; exit 1 }

Write-Host "[2/2] Jupyter kernel register..." -ForegroundColor Cyan
& $py -m ipykernel install --user --name langchain --display-name "Python (Langchain)"
if ($LASTEXITCODE -ne 0) { Write-Host "kernel register fail hua." -ForegroundColor Red; exit 1 }

Write-Host "`nVerify..." -ForegroundColor Cyan
$env:PYTHONNOUSERSITE = "1"   # user-site band -> venv ki asli sehat dikhegi
& $py -c @"
import importlib
mods = {
    'langchain_community': 'langchain-community',
    'langchain_text_splitters': 'langchain-text-splitters',
    'dotenv': 'python-dotenv',
    'pypdf': 'pypdf',
    'bs4': 'beautifulsoup4',
    'arxiv': 'arxiv',
    'pymupdf': 'pymupdf',
    'chromadb': 'chromadb',
    'ipykernel': 'ipykernel',
    'jupyter_client': 'jupyter-client (ipykernel dep)',
    'zmq': 'pyzmq (ipykernel dep)',
    'IPython': 'ipython (ipykernel dep)',
}
bad = []
for m, name in mods.items():
    try:
        importlib.import_module(m)
        print(f'  ok    {name}')
    except ImportError:
        print(f'  MISS  {name}')
        bad.append(name)
import arxiv
major = int(arxiv.__version__.split('.')[0]) if hasattr(arxiv, '__version__') else 2
if major >= 3:
    print(f'  WARN  arxiv {arxiv.__version__} langchain ke saath toota hai, `pip install \"arxiv<3\"` chalao')
raise SystemExit(1 if bad else 0)
"@

$verifyFailed = ($LASTEXITCODE -ne 0)
Remove-Item Env:\PYTHONNOUSERSITE -ErrorAction SilentlyContinue
if ($verifyFailed) { Write-Host "`nKuch packages missing hain." -ForegroundColor Red; exit 1 }

Write-Host "`nSetup ho gaya." -ForegroundColor Green
Write-Host "VS Code me notebook kholo -> upar right 'Select Kernel' -> 'Python (Langchain)'"
