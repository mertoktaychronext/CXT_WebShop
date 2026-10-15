namespace SalLicenseCheckApp.SalLicenseCheckApp;

/// <summary>
/// PIPELINE STUB of the codeunit of the same name in SalLicenseCheckApp.
/// Same ID, namespace and signature as the real app, so the Salini Base App compiles and runs against it,
/// but every tenant counts as licensed. Only for the throw-away CI build container - never deploy.
/// </summary>
codeunit 5729367 SLPLicenseExternalEvent
{
    procedure licenseCheck(appId: Guid; tenantIdCheck: Guid)
    begin
    end;
}
