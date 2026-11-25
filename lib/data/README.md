# data

- `api/` — generated client from `tm-clock-api/api/openapi.yaml` (do not edit by hand):
  `npx @openapitools/openapi-generator-cli generate -i ../tm-clock-api/api/openapi.yaml -g dart-dio -o lib/data/api`
- `models/` — app-side models / mappers on top of the generated DTOs.
- `repositories/` — one per feature area (punches, timecards, employees…); pages talk to these, never to `api/` directly.
