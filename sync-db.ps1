param(
  [Parameter(Mandatory=$true)][ValidateSet("LocalAWeb","WebALocal")]$Direccion,
  [string]$LocalPassword = $env:POSTGRES_PASSWORD
)

$WebUrl = Read-Host "Pega el DATABASE_PUBLIC_URL de Railway (postgresql://...)"
if (-not $LocalPassword) { $LocalPassword = Read-Host "POSTGRES_PASSWORD local (el de tu .env)" }

$img = "postgres:18-alpine"
$dir = (Get-Location).Path

if ($Direccion -eq "LocalAWeb") {
  Write-Host "Respaldando la web antes de sobrescribir..."
  docker run --rm -v "${dir}:/dump" $img pg_dump -Fc -f /dump/web-backup.dump "$WebUrl"

  Write-Host "Exportando base local..."
  docker run --rm -v "${dir}:/dump" -e PGPASSWORD=$LocalPassword $img pg_dump -h host.docker.internal -p 5438 -U ganadero -d gestion_ganadera -Fc -f /dump/local.dump

  $ok = Read-Host "Esto SOBRESCRIBE la base de la web. Escribe SI para continuar"
  if ($ok -ne "SI") { exit }
  docker run --rm -v "${dir}:/dump" $img pg_restore --clean --if-exists --no-owner --no-privileges -d "$WebUrl" /dump/local.dump
}
else {
  Write-Host "Respaldando la base local..."
  docker run --rm -v "${dir}:/dump" -e PGPASSWORD=$LocalPassword $img pg_dump -h host.docker.internal -p 5438 -U ganadero -d gestion_ganadera -Fc -f /dump/local-backup.dump

  Write-Host "Exportando base web..."
  docker run --rm -v "${dir}:/dump" $img pg_dump -Fc -f /dump/web.dump "$WebUrl"

  $ok = Read-Host "Esto SOBRESCRIBE la base local. Escribe SI para continuar"
  if ($ok -ne "SI") { exit }
  docker run --rm -v "${dir}:/dump" -e PGPASSWORD=$LocalPassword $img pg_restore -h host.docker.internal -p 5438 -U ganadero -d gestion_ganadera --clean --if-exists --no-owner --no-privileges /dump/web.dump
}
Write-Host "Listo."
