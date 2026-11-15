<#
.SYNOPSIS
  Compila y abre GAVAC en un celular Android conectado por USB (o en el emulador).

.DESCRIPTION
  -Api local       (por defecto) usa el API de Docker de este computador
                   (http://localhost:8001). El puerto se pasa al celular por el
                   cable USB con "adb reverse", así que no hace falta saber la IP
                   ni estar en la misma red Wi-Fi.
  -Api produccion  usa el API publicado en Railway (funciona con datos móviles).

  Requisitos del celular: Opciones de desarrollador y Depuración USB activadas,
  y aceptar el aviso "¿Permitir depuración USB?" al conectarlo.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File mobile\scripts\run_android.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File mobile\scripts\run_android.ps1 -Api produccion
#>
param(
  [ValidateSet('local', 'produccion')]
  [string]$Api = 'local'
)

$ErrorActionPreference = 'Stop'
$ProduccionUrl = 'https://proyectogavac-production.up.railway.app'

# SDK de Android: ANDROID_HOME o la ubicación por defecto de Android Studio.
$sdk = $env:ANDROID_HOME
if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$adb = Join-Path $sdk 'platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
  Write-Host "No se encontró adb en $adb. Instala el SDK de Android desde Android Studio." -ForegroundColor Red
  exit 1
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  if (Test-Path 'C:\src\flutter\bin\flutter.bat') {
    $env:Path += ';C:\src\flutter\bin'
  } else {
    Write-Host 'No se encontró Flutter en el PATH.' -ForegroundColor Red
    exit 1
  }
}

# Dispositivos conectados y autorizados.
$lineas = & $adb devices | Select-Object -Skip 1 | Where-Object { $_.Trim() }
$noAutorizados = $lineas | Where-Object { $_ -match '\sunauthorized$' }
$dispositivos = @($lineas | Where-Object { $_ -match '\sdevice$' } | ForEach-Object { ($_ -split '\s+')[0] })
if ($noAutorizados) {
  Write-Host 'El celular está conectado pero no autorizado: desbloquéalo y acepta "Permitir depuración USB".' -ForegroundColor Yellow
}
if ($dispositivos.Count -eq 0) {
  Write-Host 'No hay ningún celular ni emulador listo.' -ForegroundColor Red
  Write-Host '  1. Activa Opciones de desarrollador (toca 7 veces "Número de compilación" en Ajustes > Acerca del teléfono).'
  Write-Host '  2. En Opciones de desarrollador activa "Depuración USB".'
  Write-Host '  3. Conecta el cable USB (modo transferencia de archivos) y acepta el aviso en el celular.'
  exit 1
}
$dispositivo = $dispositivos[0]
if ($dispositivos.Count -gt 1) {
  Write-Host "Hay varios dispositivos; se usa $dispositivo." -ForegroundColor Yellow
}
$modelo = (& $adb -s $dispositivo shell getprop ro.product.model).Trim()
Write-Host "Dispositivo: $modelo ($dispositivo)" -ForegroundColor Green

if ($Api -eq 'local') {
  try {
    Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 'http://localhost:8001/health' | Out-Null
  } catch {
    Write-Host 'El API local no responde en http://localhost:8001. Levántalo con "docker compose up -d".' -ForegroundColor Red
    exit 1
  }
  # El celular ve el puerto 8001 del computador como su propio localhost.
  & $adb -s $dispositivo reverse tcp:8001 tcp:8001 | Out-Null
  $apiUrl = 'http://localhost:8001'
} else {
  $apiUrl = $ProduccionUrl
}
Write-Host "API: $apiUrl" -ForegroundColor Green

Set-Location (Join-Path $PSScriptRoot '..')
flutter run -d $dispositivo "--dart-define=API_BASE_URL=$apiUrl"
