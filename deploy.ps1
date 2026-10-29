<#
.SYNOPSIS
    Deploys the First Gear Gym backend (same Supabase + Xendit setup as student_shop).

.DESCRIPTION
    Links this folder to the BMC-ecom1 Supabase project, uploads Edge Function
    secrets, deploys create-invoice and xendit-webhook, then applies SQL
    migrations. Secrets are read from supabase/.env.local (git ignored).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File deploy.ps1
#>
param(
    [string]$Token = $env:SUPABASE_ACCESS_TOKEN
)

$ErrorActionPreference = 'Stop'
$projectRef = 'kfvxqsxycpmawgbwugyr'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$secretsFile = Join-Path $root 'supabase\.env.local'

function Get-Supabase {
    $npm = Join-Path $env:APPDATA 'npm\supabase.cmd'
    if (Test-Path $npm) { return $npm }

    $command = Get-Command supabase.cmd -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $command = Get-Command supabase -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    throw 'The Supabase CLI was not found. Install it with: npm install -g supabase'
}

$supabase = Get-Supabase
Write-Host "Using $supabase" -ForegroundColor DarkGray

if (-not (Test-Path $secretsFile)) {
    throw "Missing $secretsFile - copy supabase/.env.local.example and add the secrets."
}

Set-Location $root

$tokenFile = Join-Path $env:USERPROFILE '.supabase\access-token'
if (-not $Token -and -not (Test-Path $tokenFile)) {
    Write-Host 'No Supabase access token found.' -ForegroundColor Yellow
    Write-Host 'Run "supabase login" first, then start this script again.'
    exit 1
}

$linkArgs = @('link', '--project-ref', $projectRef)
if ($Token) { $linkArgs += @('--token', $Token) }
if ($env:SUPABASE_DB_PASSWORD) { $linkArgs += @('--password', $env:SUPABASE_DB_PASSWORD) }

Write-Host 'Linking the project ...' -ForegroundColor Cyan
& $supabase @linkArgs
if ($LASTEXITCODE -ne 0) { throw 'supabase link failed' }

Write-Host 'Uploading the edge function secrets ...' -ForegroundColor Cyan
& $supabase secrets set --env-file $secretsFile --project-ref $projectRef
if ($LASTEXITCODE -ne 0) { throw 'supabase secrets set failed' }

Write-Host 'Deploying the edge functions ...' -ForegroundColor Cyan
& $supabase functions deploy create-invoice --project-ref $projectRef
if ($LASTEXITCODE -ne 0) { throw 'deploying create-invoice failed' }
& $supabase functions deploy xendit-webhook --project-ref $projectRef
if ($LASTEXITCODE -ne 0) { throw 'deploying xendit-webhook failed' }

Write-Host 'Applying the database migrations ...' -ForegroundColor Cyan
$pushArgs = @('db', 'push', '--project-ref', $projectRef)
if ($env:SUPABASE_DB_PASSWORD) { $pushArgs += @('--password', $env:SUPABASE_DB_PASSWORD) }
& $supabase @pushArgs

Write-Host 'Done. The webhook url for the Xendit dashboard is:' -ForegroundColor Green
Write-Host "  https://$projectRef.supabase.co/functions/v1/xendit-webhook"
