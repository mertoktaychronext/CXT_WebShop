## Context

`SendToApiInterface` (`Codeunit 60329`) currently supports three request-auth modes via `"CXW Auth Type"` (Enum 60335): `None`, `ApiKeyHeader` (raw value in the `Authorization` header), `BasicAuth` (`Authorization: Basic <base64>`). The SalesPrice export endpoint responds `HTTP 403` with a body listing missing `Credential`/`Signature`/`SignedHeaders`/`X-Amz-Date` — the exact rejection text AWS API Gateway (or another AWS-fronted service) returns when a request isn't signed with AWS Signature Version 4 (SigV4). None of the three existing modes can produce that signature, so every SalesPrice transmission fails today, unconditionally.

AL has no built-in "sign this AWS request" helper. The signing primitives have to be assembled from `Codeunit "Cryptography Management"` (System Application) and `Codeunit "Base64 Convert"` (both already usable — `Base64 Convert` is in fact already a variable in `Codeunit 60329` today, used for `BasicAuth`). Verified directly against the Base/System Application AL source shipped in `.alpackages` (not assumed) — see Decision 2 for the exact procedures and why a naive approach breaks.

## Goals / Non-Goals

**Goals:**
- `"CXW Auth Type" = AWSSigV4` produces a request AWS API Gateway (IAM-authorized) accepts, using SigV4's standard algorithm (`AWS4-HMAC-SHA256`).
- New configuration lives on the existing `"CXW API Interface Setup"` table/page, following the exact patterns already established there (plain fields for non-secret config, Isolated-Storage `Set`/`Get` pairs for secrets, masked transient page variables) — no new table, no new setup page, no parallel configuration mechanism.
- SellWatch (`Table 60301`, hardcoded `X-API-KEY` header, never reads `"CXW Auth Type"`) is completely unaffected.

**Non-Goals:**
- No AWS SDK, no external library, no DotNet interop types — pure AL using platform-provided cryptography/encoding codeunits, so this works unmodified in BC SaaS.
- No credential rotation/expiry automation for the Session Token — if the endpoint requires temporary/STS credentials, refreshing them into the setup record is a manual (or separately job-queued) operation, not part of this change.
- No support for signing payloads via streamed/chunked transfer encoding (`STREAMING-AWS4-HMAC-SHA256-PAYLOAD`) — the existing `HttpContentObj.WriteFrom(pJsonText)` pattern sends the whole JSON body in one piece, so only the simple, single-chunk SigV4 signing profile is implemented.
- No change to how `WriteBackAndArchive`/`CreateExternalInterfaceFile` build the JSON payload itself — this change only affects how the already-built request is authenticated.

## Decisions

### 1. New fields on the existing `"CXW API Interface Setup"` table, not a new table
Adding `"CXW AWS Access Key ID"`, `"CXW AWS Region"`, `"CXW AWS Service"` as plain fields (same style as `"CXW Endpoint URL"`), and `SetAwsSecretAccessKey`/`GetAwsSecretAccessKey` + `SetAwsSessionToken`/`GetAwsSessionToken` as Isolated-Storage-backed procedure pairs (same style as `SetApiKey`/`GetApiKey`, same `StrSubstNo('...API InterfaceSetup_...%1', "CXW Code")`-style key naming, scoped per interface `"CXW Code"` so multiple interfaces can each hold independent AWS credentials). Matches the user's explicit ask to stay within the existing Interface Setup structure, and means Page 60324 only needs new fields added to its existing layout, not a new page.

**Alternative considered:** a separate `"CXW AWS Credentials"` table linked by code. Rejected — the existing table already carries this exact shape of data (one secret via Isolated Storage + a few plain config fields) for `ApiKeyHeader`; splitting AWS's five values into a second table would be structurally inconsistent with the table's own established pattern, not more scalable.

### 2. HMAC key-chaining via `GenerateBase64KeyedHashAsBase64String`, not the hex-returning `GenerateHash` overload
SigV4's derived-key algorithm requires **raw-byte chaining**:
```
kSecret  = "AWS4" + SecretAccessKey                          (UTF-8 bytes)
kDate    = HMAC-SHA256(kSecret,  yyyyMMdd)                    (raw 32 bytes, used as next key)
kRegion  = HMAC-SHA256(kDate,    Region)                      (raw 32 bytes, used as next key)
kService = HMAC-SHA256(kRegion,  Service)                     (raw 32 bytes, used as next key)
kSigning = HMAC-SHA256(kService, "aws4_request")               (raw 32 bytes, used as next key)
Signature = lowercase-hex( HMAC-SHA256(kSigning, StringToSign) )
```
`Codeunit "Cryptography Management"`'s `GenerateHash(InputString: Text; Key: SecretText; HashAlgorithmType): Text` — the obvious-looking choice — internally does `Encoding.UTF8().GetBytes(Key.Unwrap())`: it always treats `Key` as a **UTF-8 text string**, and its **output is a hex string** (`Byte.ToString('X2')`, uppercase). Feeding one step's hex-string output back in as the next step's `Key` would UTF-8-encode the *hex characters themselves* as the key bytes — not the 32 raw bytes they represent. That produces a signature that will never match AWS's, with no compile-time or obvious runtime signal that anything is wrong (verified by reading `CryptographyManagementImpl.Codeunit.al` directly, not assumed).

The codeunit has a second HMAC overload built for exactly this problem: `GenerateBase64KeyedHashAsBase64String(InputString: Text; Key: SecretText; HashAlgorithmType): Text`, which internally does `Convert.FromBase64String(Key.Unwrap())` for the key and `Convert.ToBase64String(...)` for the output — i.e. it treats **both** the key and the result as Base64 encodings of raw bytes, which round-trip losslessly. Using this overload for every step in the chain (seeding it with `Base64Convert.ToBase64('AWS4' + SecretAccessKey)` as the first key) keeps the actual raw bytes intact end to end.

The one place this still needs a manual fix: the *final* signature must be **lowercase hex**, not Base64, to go into the `Signature=` part of the `Authorization` header. So the last HMAC call's Base64 result is decoded back to raw bytes via `Codeunit "Base64 Convert"`.`FromBase64(Base64Text, OutStream)`, then hex-encoded manually (a small nibble-lookup loop against a `'0123456789abcdef'` literal — no DotNet type needed). The same manual lowercasing applies to the plain (non-HMAC) `GenerateHash(..., HashAlgorithmType::SHA256)` calls used for the payload hash and the canonical-request hash, since their hex output is uppercase by default and AWS requires lowercase.

**Alternative considered:** implement the whole HMAC chain via DotNet interop types (`DotNet HashAlgorithm`, `DotNet KeyedHashAlgorithm`) directly in this codeunit, bypassing the wrapper. Rejected — DotNet variable types are unsupported/blocked in BC SaaS for customer extensions; would only work on-premises, contradicting "noch nirgends deployed" and this app's SaaS-oriented design elsewhere (e.g. `Codeunit "Base64 Convert"` is already used instead of DotNet `Convert` for the same reason).

### 3. `"CXW AWS Service"` is a configurable field, not hardcoded to `execute-api`
The 403 body strongly suggests API Gateway with IAM auth (service `execute-api`), but the field stays free-text with a tooltip suggesting that default, rather than being hardcoded — the same interface-setup mechanism could point at a different AWS service in the future without a code change.

### 4. Signed headers kept minimal: `content-type;host;x-amz-date`
AWS requires `host` to be signed; `x-amz-date` is the timestamp SigV4 authenticates against; `content-type` is included since it's already being set today for the other auth types and including more signed headers only strengthens integrity. `Authorization` itself is obviously never signed. This mirrors the minimal-but-correct signed-header sets AWS's own documentation examples use, keeping the canonical-request construction as simple as this endpoint requires rather than signing every header the `HttpClient` might implicitly add.

### 5. Session Token is optional and only affects the request when non-blank
If `GetAwsSessionToken()` is blank, no `X-Amz-Security-Token` header is sent and it's excluded from `SignedHeaders` — valid for long-lived IAM user credentials. If non-blank, it's sent and included in the signed-headers set (`x-amz-security-token` becomes part of the sorted list) — required for temporary/STS-issued credentials. This is a runtime branch, not a separate Auth Type value, since it's a variant of the same signing algorithm rather than a different one.

## Risks / Trade-offs

- **[Risk]** Hand-rolled SigV4 is easy to get subtly wrong (canonical query-string encoding, header value trimming/collapsing, timestamp format) and a wrong byte anywhere produces the same generic 403 with no differentiated error from AWS → **Mitigation**: tasks.md includes verifying the derived-key chain against AWS's published SigV4 test vectors (fixed, known-good key/date/region/service/expected-signature values) *before* wiring the signing code into the real HTTP send path, so implementation correctness is checked independently of having live AWS credentials to test against.
- **[Risk]** `SendToApiInterface` still isn't a `[TryFunction]` (see the `sales-price-checking-writeback`/design history) — an unexpected error inside the new signing branch (e.g. a blank required AWS field slipping past the activation guard) would still abort the whole "Upload Sales Price" batch, not just the one line → **Mitigation**: none in this change — matches existing behavior for the other auth types' `TestField` calls today; not reintroducing a new failure mode, just not fixing the pre-existing one either. Flagged as a candidate follow-up, out of scope here.
- **[Risk]** Long-lived IAM Access Key/Secret pairs stored in Isolated Storage are a standing credential with no expiry — if compromised, valid until manually rotated → **Mitigation**: Session Token support (Decision 5) means this design also supports temporary/STS credentials, which is the AWS-recommended posture; whether to actually use temporary credentials is an operational decision for whoever owns the AWS side, not something this change can enforce from the BC side.
- **[Risk]** `"CXW AWS Service"` free-text field could be filled in incorrectly (e.g. `apigateway` instead of `execute-api`) with no validation, producing another opaque 403 → **Mitigation**: tooltip documents the expected value for the common case; no `TestField` beyond non-blank, since valid values are AWS-side knowledge this app can't authoritatively validate.

## Migration Plan

No data migration — purely additive fields/enum value. Existing interfaces using `None`/`ApiKeyHeader`/`BasicAuth` are completely unaffected (new fields stay blank, new enum value unused, existing branches in `SendToApiInterface` untouched). Deploy via normal `AL: Publish`. Rollback is a normal code revert; no data is restructured, so reverting just makes the new fields/values inert again (any AWS credentials already entered stay in Isolated Storage but become unused, harmless).

## Open Questions

- Confirm with the endpoint owner: is `execute-api` actually the correct service, and is the region the BC environment's own hosting region or a fixed target region independent of where BC runs? (These are AWS-side facts this document can't verify from inside the codebase.)
- Are the credentials being issued static (long-lived IAM user Access Key/Secret) or temporary (STS, requiring the Session Token field and periodic manual refresh)? Affects whether Session Token support is exercised from day one or sits unused.
