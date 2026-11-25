# Mock TM Clock API generated from api/openapi.yaml (Prism), on http://localhost:4010.
# Every request is checked against the spec, so a wrong field name, a missing header or a
# bad ID fails here the same way it would on the real API.
#
#   .\tool\mock_api.ps1            # random but valid data on each call (default)
#   .\tool\mock_api.ps1 -Static    # fixed answers from the spec's schemas ("string", 0, ...)
#
# Then point an app at it (note: no /v1 — Prism serves the paths at the root):
#   flutter run -d chrome -t lib/main_crew.dart --dart-define=USE_FAKE_DATA=false --dart-define=API_BASE_URL=http://localhost:4010
#
# Check every repository call against it:
#   dart run tool/check_api.dart http://localhost:4010
#
# Needs Node.js 18+. api/openapi.yaml is a copy of tm-clock-api/api/openapi.yaml; refresh it when that changes.
param([switch]$Static, [int]$Port = 4010)

$spec = Join-Path $PSScriptRoot '..\api\openapi.yaml'
$prismArgs = @('--yes', '@stoplight/prism-cli@5.16.0', 'mock', $spec, '--port', $Port, '--host', '127.0.0.1')
if (-not $Static) { $prismArgs += '--dynamic' }
Write-Host "Mock API: http://localhost:$Port  (Ctrl+C to stop)"
& npx @prismArgs
