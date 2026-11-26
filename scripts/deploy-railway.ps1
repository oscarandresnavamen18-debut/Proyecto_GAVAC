[CmdletBinding()]
param(
    [switch]$SkipDocker,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

function Check-File($Path) {
    if (-not (Test-Path $Path)) {
        throw "No existe el archivo requerido: $Path"
    }
    Write-Host "[OK] $Path" -ForegroundColor Green
}

function Run-NativeCommand($Command, [string[]]$Arguments) {
    $oldPref = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        & $Command @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "El comando '$Command $($Arguments -join ' ')' finalizó con código de error $LASTEXITCODE."
        }
    } finally {
        $ErrorActionPreference = $oldPref
    }
}

Write-Host "`n=== GAVAC: VALIDACIÓN DE DESPLIEGUE RAILWAY ===" -ForegroundColor Cyan
Write-Host "Directorio raíz: $ProjectRoot"

# 1. Validar archivos esenciales del Backend
Write-Host "`n--- Validando archivos del Backend ---" -ForegroundColor Yellow
Check-File "backend/Dockerfile"
Check-File "backend/requirements.txt"
Check-File "backend/app/main.py"
Check-File "backend/alembic.ini"
Check-File "backend/alembic/env.py"

# 2. Validar Railway CLI
Write-Host "`n--- Validando Railway CLI ---" -ForegroundColor Yellow
if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
    throw "Railway CLI no está instalado o no se encuentra en el PATH. Instálalo con: npm i -g @railway/cli"
}
Write-Host "[OK] Railway CLI está instalado." -ForegroundColor Green

# 3. Estado de Git
Write-Host "`n--- Estado de Git ---" -ForegroundColor Yellow
Run-NativeCommand "git" @("status", "--short")

# 4. Preflight con Docker
if (-not $SkipDocker) {
    Write-Host "`n--- Validando construcción Docker local ---" -ForegroundColor Yellow
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $dockerRunning = $false
        $oldPref = $ErrorActionPreference
        try {
            $ErrorActionPreference = "Continue"
            & docker info 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $dockerRunning = $true
            }
        } catch {
            $dockerRunning = $false
        } finally {
            $ErrorActionPreference = $oldPref
        }

        if ($dockerRunning) {
            Run-NativeCommand "docker" @("build", "-t", "gavac-api:preflight", ".\backend")
            Write-Host "[OK] Imagen Docker construida localmente sin errores." -ForegroundColor Green
        } else {
            Write-Warning "Docker Daemon no está en ejecución. Se omite la validación de build local."
        }
    } else {
        Write-Warning "Docker no está instalado. Se omite la validación de build local."
    }
} else {
    Write-Host "`n--- Validación Docker omitida (-SkipDocker) ---" -ForegroundColor Gray
}

# 5. Estado del proyecto en Railway
Write-Host "`n--- Conexión con Railway ---" -ForegroundColor Yellow
Run-NativeCommand "railway" @("status")

Write-Host "`nEstructura validada correctamente." -ForegroundColor Green
Write-Host "Comprueba que en Railway el servicio tenga:" -ForegroundColor Gray
Write-Host "  - Root Directory: backend" -ForegroundColor Gray
Write-Host "  - Dockerfile Path: backend/Dockerfile" -ForegroundColor Gray

# 6. Confirmación de despliegue
if (-not $Force) {
    $Confirm = Read-Host "`n¿Deseas ejecutar el despliegue en Railway ahora? (Escribe 'SI')"
    if ($Confirm -cne "SI") {
        Write-Host "Despliegue cancelado por el usuario. No se ejecutaron cambios." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`n=== DESPLEGANDO GAVAC EN RAILWAY ===" -ForegroundColor Cyan
Run-NativeCommand "railway" @("up")
Write-Host "`n[ÉXITO] Despliegue en Railway finalizado." -ForegroundColor Green
