## 1. Enum: new Auth Type value

- [x] 1.1 In `src/Enums/Enum60335.CXWAPIAuthType.al`, add `value(3; AWSSigV4) { Caption = 'AWS Signature V4'; }`.

## 2. Table: AWS credential fields and secrets

- [x] 2.1 In `src/Tables/Tab60317.CXWAPIInterfaceSetup.al`, add plain fields `"CXW AWS Access Key ID"` (Text[128]), `"CXW AWS Region"` (Text[20]), `"CXW AWS Service"` (Text[50], tooltip mentions `execute-api` as the typical API Gateway value).
- [x] 2.2 Add `SetAwsSecretAccessKey(NewKey: Text)` / `GetAwsSecretAccessKey(): Text`, mirroring `SetApiKey`/`GetApiKey` exactly (same Isolated Storage pattern, `DataScope::Module`, own storage key via a new `local procedure GetAwsSecretAccessKeyIsolatedStorageKey(): Text`).
- [x] 2.3 Add `SetAwsSessionToken(NewToken: Text)` / `GetAwsSessionToken(): Text`, same pattern, own storage key.
- [x] 2.4 Extend the `"CXW Active"` field's `OnValidate` trigger: when `"CXW Auth Type" = AWSSigV4`, additionally require `"CXW AWS Access Key ID"`, `"CXW AWS Region"`, `"CXW AWS Service"` non-blank and `GetAwsSecretAccessKey() <> ''`, erroring the same way the existing `MissingApiKeyErr` check does for the other auth types (new label, e.g. `MissingAwsCredentialsErr`).

## 3. Page: expose the new fields

- [x] 3.1 In `src/Pages/Pag60324.CXWAPIInterfaceSetup.al`, add `"CXW AWS Access Key ID"`, `"CXW AWS Region"`, `"CXW AWS Service"` as plain fields with `ApplicationArea = All` and tooltips, placed after the existing `ApiKey` field.
- [x] 3.2 Add two new masked transient-variable fields (`AwsSecretAccessKey`, `AwsSessionToken`), each with `ExtendedDatatype = Masked` and an `OnValidate` that calls the corresponding `Set...` procedure and clears the variable — exact mirror of the existing `ApiKey`/`g_txtApiKey` field.
- [x] 3.3 Add the two new transient variables (`g_txtAwsSecretAccessKey`, `g_txtAwsSessionToken`) to the page's `var` section.

## 4. Codeunit: SigV4 signing primitives

- [x] 4.1 In `src/Codeunits/Codeunit60329.CXWExportGatewaySalesPrice.al`, add a `local procedure HexEncode(pInStream: InStream): Text` that reads all bytes from the stream and hex-encodes them lowercase via a `'0123456789abcdef'` lookup (two-nibble-per-byte), per design.md Decision 2 — no DotNet types.
- [x] 4.2 Add `local procedure Sha256HexLower(pText: Text): Text` wrapping `CryptographyManagement.GenerateHash(pText, HashAlgorithmType::SHA256)` and `LowerCase(...)`, for the payload hash and canonical-request hash.
- [x] 4.3 Add `local procedure HmacChainStep(pBase64Key: Text; pMessage: Text): Text` wrapping `CryptographyManagement.GenerateBase64KeyedHashAsBase64String(pMessage, pBase64Key, HashAlgorithmType::HMACSHA256)` — returns Base64, per design.md Decision 2 (raw-byte-preserving chaining, not the hex-returning overload).
- [x] 4.4 Add `local procedure DeriveSigningKey(pSecretAccessKey: Text; pDateStamp: Text; pRegion: Text; pService: Text): Text` implementing the 4-step chain (`kDate → kRegion → kService → kSigning`) via repeated `HmacChainStep` calls, seeded with `Base64Convert.ToBase64('AWS4' + pSecretAccessKey)`; returns the final `kSigning` as Base64.
- [x] 4.5 Add `local procedure HmacSignatureHexLower(pBase64Key: Text; pMessage: Text): Text` that calls `HmacChainStep` for the final signature step, then decodes the Base64 result via `Base64Convert.FromBase64(...)` into a stream and hex-encodes it lowercase via `HexEncode` (4.1) — this is the one step that needs hex output instead of Base64.
- [x] 4.6 **Verification checkpoint (do this before 4.7):** write a small throwaway test (temp codeunit, or a page action gated behind a debug flag — remove before merging either way) that runs 4.1–4.5 against AWS's published SigV4 test vectors (fixed known Secret Key/Date/Region/Service/StringToSign → known expected signature, from AWS's official "Signature Calculation" documentation) and confirms the computed signature matches exactly. Do not proceed to 4.7 until this passes — per design.md Risks, a byte-encoding mistake here produces the same generic 403 with no differentiating error message.
  - Done via an independent Node.js replica of the exact planned operation sequence (Base64 key-chaining via HMAC-SHA256, final hex decode) run against AWS's official published "get-vanilla" test vector (from `docs.aws.amazon.com` and the `aws-sig-v4-test-suite` GitHub repo) — computed signature matched AWS's published signature exactly (`5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31`). No live BC server was reachable in this session to run the AL code directly (`AL: Publish` requires interactive browser auth against the `ChronextDEV` sandbox) — task 6.1/8.1 still needs a real compile+publish+run in that environment before this is considered fully verified.

## 5. Codeunit: wire signing into SendToApiInterface

- [x] 5.1 Add a `local procedure BuildSigV4Headers(pApiInterfaceSetup: Record "CXW API Interface Setup"; pMethod: Text; pUrlPath: Text; pHost: Text; pPayload: Text; var vAuthorizationHeader: Text; var vAmzDate: Text)` that builds the canonical request (method, URI, empty query string, canonical headers `content-type`/`host`/`x-amz-date`[/`x-amz-security-token`] sorted and lowercased, matching `SignedHeaders`, payload hash via 4.2), the string-to-sign, derives the signing key (4.4), computes the signature (4.5), and assembles the final `Authorization` header value (`AWS4-HMAC-SHA256 Credential=.../SignedHeaders=.../Signature=...`) plus the `X-Amz-Date` value (`yyyyMMdd'T'HHmmss'Z'`, UTC).
- [x] 5.2 In `SendToApiInterface`'s `case ApiInterfaceSetup."CXW Auth Type" of`, add an `AWSSigV4` branch that calls `BuildSigV4Headers` and sets the `Authorization`, `X-Amz-Date`, and (if session token present) `X-Amz-Security-Token` headers on `HttpRequest` accordingly — placed alongside the existing `ApiKeyHeader`/`BasicAuth` branches, same structural pattern (`HttpRequest.GetHeaders(...); HttpHeadersObj.Add(...)`).
- [x] 5.3 Update `BuildRedactedRequestText` so the AWS SigV4 case redacts the `Authorization` header (and `X-Amz-Security-Token` if present) the same way the existing `Authorization: ***redacted***` line works for the other auth types — do not log the real Access Key ID, Secret, Session Token, or computed signature.

## 6. Build Verification

- [x] 6.1 Compile the app and resolve every error.
  - Compiled locally with the AL compiler (`ms-dynamics-smb.al-17.0.2273547/bin/win32/alc.exe`) against `.alpackages`. First pass caught a real bug: `HashAlgorithmType::SHA256`/`::HMACSHA256` don't resolve against `Cryptography Management`'s anonymous `Option` parameters without a matching local `Option` variable of the same name — fixed by declaring `HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;` (and the HMAC variant) locally in `Sha256HexLower`/`HmacChainStep`. Second pass compiled clean (only one pre-existing, unrelated warning in `Codeunit60330.CXWImportSalesPrices.al`).
- [x] 6.2 Confirm the throwaway SigV4 test-vector check (4.6) passed and has been removed from the shipped code (or gated so it never runs in production).
  - Removed; verification was done externally via Node.js (see 4.6 note) rather than as in-app AL code, so there was nothing to remove from the codeunit itself.
- [x] 6.3 Manually reason through every scenario in `specs/sales-price-aws-sigv4-auth/spec.md`: activation guard (blocked/allowed), session-token present/absent header behavior, redaction.
  - All scenarios verified against the implementation: enum selectability, plain-field storage, Isolated Storage secret storage, session-token optionality, activation guard block/allow, signed-headers set, session-token header inclusion/omission, and full-header redaction (Authorization and X-Amz-Security-Token are replaced wholesale, never partially, so the Access Key ID/Secret/Session Token/signature never appear in logs).
- [x] 6.4 Confirm SellWatch (`Table 60301`, `Codeunit 60305`) compiles and behaves identically — it doesn't read `"CXW Auth Type"` at all, so this should be a no-op check, not a real risk, but confirm nothing on the shared `"CXW API Interface Setup"` table broke its existing `GetApiKey()`/`"CXW Endpoint URL"` usage.
  - Confirmed: `Codeunit60305.CXWSellWatchMgt.al` contains no reference to `"CXW Auth Type"`, `GetApiKey`, or `"CXW Endpoint URL"` — unaffected. Full-project compile (35 files, includes SellWatch) succeeded.

## 7. Documentation

- [x] 7.1 Update `docs/developer-manual-de.md` / `-en.md`: document the new `AWSSigV4` auth type, the new setup fields, and a one-line pointer to this change's design.md for the signing algorithm details — mirroring how the HTTP-logging update was documented.
- [x] 7.2 New translatable strings (field captions/tooltips on Table 60317 and Page 60324, the new error label) need German translations in `Translations/CHX.Webshop.de-DE.xlf` — follow the `managing-bc-translations` skill's sync procedure.
  - Recompiled to regenerate `Translations/CHX.Webshop.g.xlf`, identified the 12 new AWS-related trans-units, and inserted German translations into `CHX.Webshop.de-DE.xlf` at the matching positions (AWS terminology follows AWS's own official German IAM console wording — "Zugriffsschlüssel-ID", "Geheimer Zugriffsschlüssel", "Sitzungstoken" — with "AWS Signature V4" itself left untranslated as a protocol name). Verified via script: all 12 present with non-empty targets, 0 placeholder (`%1`) mismatches, XML well-formed, full project still compiles clean. Left 1 unrelated missing unit and 8 unrelated orphaned units (pre-existing drift from other in-progress work, e.g. the uncommitted `Pag60323.CXWSalesPriceArchive.al` change) untouched as out of scope for this change.

## 8. Final Check

- [x] 8.1 With real AWS credentials configured (Access Key ID, Secret, Region, Service, optionally Session Token) against the actual failing endpoint, run "Upload Sales Price" for at least one line and confirm the `HTTP 403` is gone — this is the only step that can be verified end-to-end without a real AWS credential, so it must happen before considering this change actually resolved (not just "compiles and matches test vectors").
  - Confirmed by the user against the live endpoint after the follow-up fixes discovered during that same live testing: `HttpHeaders.TryAddWithoutValidation` for the Authorization header (AWS SigV4's `Credential=.../.../.../aws4_request` value fails .NET's strict header-format validation), an `X-API-Key` header alongside the SigV4 signature (the endpoint layers a usage-plan API key on top of IAM auth), and a configurable HTTP method/SOAPAction (the endpoint requires PATCH, not POST).
