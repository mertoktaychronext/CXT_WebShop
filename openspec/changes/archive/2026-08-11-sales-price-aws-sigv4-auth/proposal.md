## Why

Every SalesPrice HTTP transmission (`Codeunit 60329`'s `SendToApiInterface`) currently fails with `HTTP 403: "Authorization header requires 'Credential' parameter. Authorization header requires 'Signature' parameter. Authorization header requires 'SignedHeaders' parameter. Authorization header requires existence of either a 'X-Amz-Date'..."`. This is the standard rejection response from an AWS-fronted endpoint (almost certainly API Gateway with IAM authorization) expecting a request signed with AWS Signature Version 4 (SigV4). `"CXW API Auth Type"` (Enum 60335) only supports `None`, `ApiKeyHeader`, and `BasicAuth` — none of which can ever produce a SigV4 signature, so this isn't a misconfiguration of an existing auth mode, it's a missing one. Every price export to this endpoint fails until SigV4 support exists.

## What Changes

- Add a fourth value `AWSSigV4` to `"CXW API Auth Type"` (Enum 60335), alongside the existing three.
- Extend `"CXW API Interface Setup"` (Table 60317) with the additional configuration a SigV4-signed request needs, following the table's existing pattern (plain fields for non-secret config, Isolated-Storage-backed `Set`/`Get` procedure pairs for secrets, matching how `"CXW Endpoint URL"`/`SetApiKey`/`GetApiKey` already work today):
  - `"CXW AWS Access Key ID"` (plain field)
  - `"CXW AWS Region"` (plain field)
  - `"CXW AWS Service"` (plain field — typically `execute-api` for API Gateway, but left configurable rather than hardcoded)
  - AWS Secret Access Key (new Isolated-Storage-backed secret, `SetAwsSecretAccessKey`/`GetAwsSecretAccessKey`, mirroring `SetApiKey`/`GetApiKey`)
  - AWS Session Token (new Isolated-Storage-backed secret, optional — only used if non-blank, for temporary/STS-issued credentials; `SetAwsSessionToken`/`GetAwsSessionToken`)
- Extend the `"CXW Active"` activation guard on Table 60317 to also require the AWS-specific fields to be filled in when `"CXW Auth Type" = AWSSigV4`, mirroring the existing "no API key, can't activate" check for the other auth types.
- Add the new fields to Page 60324 "CXW API Interface Setup", following the existing layout pattern (plain fields inline, secrets via a transient masked page variable + `OnValidate` that calls the `Set...` procedure and clears itself — exactly like the existing `ApiKey` field).
- Implement AWS SigV4 request signing in `Codeunit 60329`'s `SendToApiInterface`: a new branch alongside the existing `ApiKeyHeader`/`BasicAuth` cases that builds the canonical request, computes the derived signing key via the HMAC-SHA256 chain (`Codeunit "Cryptography Management"`), and sets the `Authorization` and `X-Amz-Date` (and `X-Amz-Content-Sha256`) headers before the request is sent.
- `BuildRedactedRequestText` gains SigV4-aware redaction: the computed `Authorization` header value (which embeds the Access Key ID and a derived signature, not the raw secret, but still sensitive enough to redact) is replaced the same way the existing `Authorization` header is redacted for the other auth types today.
- **BREAKING**: none. Purely additive — existing `None`/`ApiKeyHeader`/`BasicAuth` interfaces (including SellWatch's hardcoded `X-API-KEY` flow, which doesn't read `"CXW Auth Type"` at all) are untouched.

## Capabilities

### New Capabilities
- `sales-price-aws-sigv4-auth`: AWS SigV4 request signing for the SalesPrice export HTTP call, including the new interface-setup credentials it depends on.

### Modified Capabilities
(none — no existing spec covers API interface authentication yet, so this is purely additive)

## Impact

- `src/Enums/Enum60335.CXWAPIAuthType.al` — new enum value.
- `src/Tables/Tab60317.CXWAPIInterfaceSetup.al` — new fields, new Isolated-Storage secret procedures, extended activation guard.
- `src/Pages/Pag60324.CXWAPIInterfaceSetup.al` — new fields in the layout, new transient page variables for the secret fields.
- `src/Codeunits/Codeunit60329.CXWExportGatewaySalesPrice.al` — new SigV4 signing logic in `SendToApiInterface`, redaction update in `BuildRedactedRequestText`.
- No impact on SellWatch (`Table 60301`'s `CreateEntryInexternalFile`) — it sends a hardcoded `X-API-KEY` header and never branches on `"CXW Auth Type"`.
- No new permission-set entries needed — no new objects, only new fields/enum values on already-permitted objects.
- New translatable strings: field captions and tooltips on Table 60317/Page 60324 (German translation needed in `Translations/CHX.Webshop.de-DE.xlf`).
