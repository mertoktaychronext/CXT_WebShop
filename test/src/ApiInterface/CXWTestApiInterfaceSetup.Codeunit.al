namespace CHX.Webshop.Test;

using System.TestLibraries.Utilities;

/// <summary>
/// Rules of the "CXW API Interface Setup" table: which fields are relevant per auth type, when an interface
/// can be activated, and how secrets are shown. No posting, no HTTP - the simplest tests of the app and a good
/// starting point for readers.
/// Sources: openspec/specs/api-interface-setup, api-interface-setup-conditional-fields, sales-price-aws-sigv4-auth.
///
/// How a test works:
/// - [Test] marks a test method. The test runner calls every [Test] method of this codeunit.
/// - Each test starts with Initialize(), so error texts are compared in English, whatever the session language.
/// - [GIVEN] sets up data, [WHEN] runs the code under test, [THEN] checks the result with LibraryAssert.
/// - "asserterror" expects the next statement to fail; LibraryAssert.ExpectedError then checks the error text.
/// - Test isolation rolls back all data after each test, so tests do not affect each other or the sandbox.
/// </summary>
codeunit 50400 "CXW Test API Interface Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        TestLibrary: Codeunit "CXW Test Library";
        EndpointUrlTok: Label 'https://interface.test.invalid/api', Locked = true;
        EndpointUrlMissingErr: Label 'Endpoint URL must have a value', Locked = true;
        ApiKeyMissingErr: Label 'but no API key has been entered for this interface', Locked = true;
        AwsCredentialsMissingErr: Label 'the AWS Access Key ID, Region, or Service has not been fully entered', Locked = true;
        NotStoredTok: Label '(not stored)', Locked = true;

    #region Field relevance per auth type

    [Test]
    procedure ApiKeyFieldIsRelevantForKeyBasedAndAwsAuth()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        Initialize();
        // Spec api-interface-setup-conditional-fields: Scenario "API Key field is relevant for key-based and AWS SigV4 auth types"
        // [GIVEN] An interface
        // [WHEN] The auth type is API key, basic authentication or AWS Signature V4
        // [THEN] The API key field is relevant
        ApiInterfaceSetup."CXW Auth Type" := ApiInterfaceSetup."CXW Auth Type"::ApiKeyHeader;
        LibraryAssert.IsTrue(ApiInterfaceSetup.IsApiKeyFieldRelevant(), 'API key must be relevant for API Key (Header).');
        ApiInterfaceSetup."CXW Auth Type" := ApiInterfaceSetup."CXW Auth Type"::BasicAuth;
        LibraryAssert.IsTrue(ApiInterfaceSetup.IsApiKeyFieldRelevant(), 'API key must be relevant for Basic Authentication.');
        ApiInterfaceSetup."CXW Auth Type" := ApiInterfaceSetup."CXW Auth Type"::AWSSigV4;
        LibraryAssert.IsTrue(ApiInterfaceSetup.IsApiKeyFieldRelevant(), 'API key must be relevant for AWS Signature V4.');
    end;

    [Test]
    procedure ApiKeyFieldIsNotRelevantWithoutAuth()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        Initialize();
        // Spec api-interface-setup-conditional-fields: Scenario "API Key field is not relevant when no authentication is used"
        // [GIVEN] An interface without authentication
        ApiInterfaceSetup."CXW Auth Type" := ApiInterfaceSetup."CXW Auth Type"::None;
        // [WHEN] Asking whether the API key field is relevant
        // [THEN] It is not
        LibraryAssert.IsFalse(ApiInterfaceSetup.IsApiKeyFieldRelevant(), 'API key must not be relevant without authentication.');
    end;

    [Test]
    procedure AwsFieldsAreRelevantOnlyForAwsSigV4()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        Initialize();
        // Spec api-interface-setup-conditional-fields: Scenarios "AWS-specific fields are relevant only for AWS Signature V4"
        // and "AWS-specific fields are not relevant for other auth types"
        // [GIVEN] An interface
        // [WHEN] Going through all auth types
        // [THEN] Only AWS Signature V4 makes the AWS fields relevant
        ApiInterfaceSetup."CXW Auth Type" := ApiInterfaceSetup."CXW Auth Type"::AWSSigV4;
        LibraryAssert.IsTrue(ApiInterfaceSetup.IsAwsFieldsRelevant(), 'AWS fields must be relevant for AWS Signature V4.');
        ApiInterfaceSetup."CXW Auth Type" := ApiInterfaceSetup."CXW Auth Type"::None;
        LibraryAssert.IsFalse(ApiInterfaceSetup.IsAwsFieldsRelevant(), 'AWS fields must not be relevant without authentication.');
        ApiInterfaceSetup."CXW Auth Type" := ApiInterfaceSetup."CXW Auth Type"::ApiKeyHeader;
        LibraryAssert.IsFalse(ApiInterfaceSetup.IsAwsFieldsRelevant(), 'AWS fields must not be relevant for API Key (Header).');
        ApiInterfaceSetup."CXW Auth Type" := ApiInterfaceSetup."CXW Auth Type"::BasicAuth;
        LibraryAssert.IsFalse(ApiInterfaceSetup.IsAwsFieldsRelevant(), 'AWS fields must not be relevant for Basic Authentication.');
    end;

    #endregion

    #region Activation guard

    [Test]
    procedure ActivationRequiresEndpointUrl()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        Initialize();
        // Spec api-interface-setup: Scenario "Endpoint URL is required"
        // [GIVEN] An interface without endpoint URL
        TestLibrary.CreateApiInterface(ApiInterfaceSetup, Enum::"CXW API Auth Type"::None, 0);
        // [WHEN] Activating it
        asserterror ApiInterfaceSetup.Validate("CXW Active", true);
        // [THEN] Activation is rejected because the URL is missing
        LibraryAssert.ExpectedError(EndpointUrlMissingErr);
    end;

    [Test]
    procedure ActivationWithoutAuthNeedsNoApiKey()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        Initialize();
        // Code: an interface without authentication only needs the endpoint URL
        // [GIVEN] An interface without authentication, with endpoint URL and without API key
        TestLibrary.CreateApiInterface(ApiInterfaceSetup, Enum::"CXW API Auth Type"::None, 0);
        ApiInterfaceSetup."CXW Endpoint URL" := EndpointUrlTok;
        // [WHEN] Activating it
        ApiInterfaceSetup.Validate("CXW Active", true);
        // [THEN] It is active
        LibraryAssert.IsTrue(ApiInterfaceSetup."CXW Active", 'Interface without authentication must be activatable.');
    end;

    [Test]
    procedure ActivationRequiresApiKeyForKeyBasedAuth()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        Initialize();
        // Code: key-based authentication cannot be activated without a stored API key
        // [GIVEN] An API key interface with endpoint URL but without API key
        TestLibrary.CreateApiInterface(ApiInterfaceSetup, Enum::"CXW API Auth Type"::ApiKeyHeader, 0);
        ApiInterfaceSetup."CXW Endpoint URL" := EndpointUrlTok;
        // [WHEN] Activating it
        asserterror ApiInterfaceSetup.Validate("CXW Active", true);
        // [THEN] Activation is rejected because the API key is missing
        LibraryAssert.ExpectedError(ApiKeyMissingErr);
    end;

    [Test]
    procedure ActivationIsBlockedForIncompleteAwsConfiguration()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        Initialize();
        // Spec sales-price-aws-sigv4-auth: Scenario "Activating an incomplete AWS SigV4 interface is blocked"
        // Spec api-interface-setup-conditional-fields: Scenario "Activation still blocked for incomplete AWS Signature V4 configuration"
        // [GIVEN] An AWS Signature V4 interface with access key ID and region, but without service
        CreateAwsInterface(ApiInterfaceSetup);
        ApiInterfaceSetup."CXW AWS Service" := '';
        // [WHEN] Activating it
        asserterror ApiInterfaceSetup.Validate("CXW Active", true);
        // [THEN] Activation is rejected
        LibraryAssert.ExpectedError(AwsCredentialsMissingErr);
    end;

    [Test]
    procedure ActivationSucceedsForCompleteAwsConfiguration()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        Initialize();
        // Spec sales-price-aws-sigv4-auth: Scenario "Activating a complete AWS SigV4 interface succeeds"
        // [GIVEN] An AWS Signature V4 interface with access key ID, region, service and secret access key
        CreateAwsInterface(ApiInterfaceSetup);
        ApiInterfaceSetup.SetAwsSecretAccessKey(TestLibrary.NewText());
        // [WHEN] Activating it
        ApiInterfaceSetup.Validate("CXW Active", true);
        // [THEN] It is active
        LibraryAssert.IsTrue(ApiInterfaceSetup."CXW Active", 'Complete AWS interface must be activatable.');
    end;

    [Test]
    procedure MissingAwsSecretAccessKeyDoesNotBlockActivation()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        Initialize();
        // Spec sales-price-aws-sigv4-auth: Scenario "Missing Secret Access Key does not block activation"
        // [GIVEN] An AWS Signature V4 interface with all plain fields, but without secret access key and API key
        CreateAwsInterface(ApiInterfaceSetup);
        // [WHEN] Activating it
        ApiInterfaceSetup.Validate("CXW Active", true);
        // [THEN] It is active
        LibraryAssert.IsTrue(ApiInterfaceSetup."CXW Active", 'Missing secret access key must not block activation.');
    end;

    #endregion

    #region Secrets

    [Test]
    procedure StoredSecretIsShownOnlyAsHint()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
        Hint: Text;
    begin
        Initialize();
        // Spec api-interface-setup: Scenario "Secret is not visible after saving"
        // [GIVEN] An interface with a stored API key
        TestLibrary.CreateApiInterface(ApiInterfaceSetup, Enum::"CXW API Auth Type"::ApiKeyHeader, 0);
        ApiInterfaceSetup.SetApiKey('secretvalue1234');
        // [WHEN] Getting the hint shown on the page
        Hint := ApiInterfaceSetup.GetApiKeyHint();
        // [THEN] Only the last 4 characters are visible, the key itself can still be read by the code
        LibraryAssert.IsTrue(Hint.EndsWith('1234'), 'Hint must end with the last 4 characters.');
        LibraryAssert.AreEqual(0, StrPos(Hint, 'secretvalue'), 'Hint must not reveal the rest of the secret.');
        LibraryAssert.AreEqual('secretvalue1234', ApiInterfaceSetup.GetApiKey(), 'Stored API key');
    end;

    [Test]
    procedure ShortSecretIsFullyMasked()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
        Hint: Text;
    begin
        Initialize();
        // Code: secrets of 4 characters or less are fully masked, otherwise the hint would reveal them
        // [GIVEN] An interface with a 4 character AWS session token
        TestLibrary.CreateApiInterface(ApiInterfaceSetup, Enum::"CXW API Auth Type"::AWSSigV4, 0);
        ApiInterfaceSetup.SetAwsSessionToken('abcd');
        // [WHEN] Getting the hint
        Hint := ApiInterfaceSetup.GetAwsSessionTokenHint();
        // [THEN] Nothing of the token is visible
        LibraryAssert.AreEqual(0, StrPos(Hint, 'abcd'), 'Hint must not reveal a short secret.');
        LibraryAssert.AreNotEqual(NotStoredTok, Hint, 'A stored secret must not be shown as not stored.');
    end;

    [Test]
    procedure EmptySecretRemovesStoredValue()
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        Initialize();
        // Spec sales-price-aws-sigv4-auth: Scenario "AWS Session Token is optional"
        // [GIVEN] An interface with a stored AWS secret access key
        TestLibrary.CreateApiInterface(ApiInterfaceSetup, Enum::"CXW API Auth Type"::AWSSigV4, 0);
        ApiInterfaceSetup.SetAwsSecretAccessKey(TestLibrary.NewText());
        // [WHEN] Entering an empty value
        ApiInterfaceSetup.SetAwsSecretAccessKey('');
        // [THEN] The secret is removed and shown as not stored
        LibraryAssert.AreEqual('', ApiInterfaceSetup.GetAwsSecretAccessKey(), 'Secret access key must be removed.');
        LibraryAssert.AreEqual(NotStoredTok, ApiInterfaceSetup.GetAwsSecretAccessKeyHint(), 'Hint for a removed secret');
    end;

    #endregion

    local procedure CreateAwsInterface(var ApiInterfaceSetup: Record "CXW API Interface Setup")
    begin
        TestLibrary.CreateApiInterface(ApiInterfaceSetup, Enum::"CXW API Auth Type"::AWSSigV4, 0);
        ApiInterfaceSetup."CXW Endpoint URL" := EndpointUrlTok;
        ApiInterfaceSetup."CXW AWS Access Key ID" := 'AKIATESTACCESSKEY';
        ApiInterfaceSetup."CXW AWS Region" := 'eu-central-1';
        ApiInterfaceSetup."CXW AWS Service" := 'execute-api';
        ApiInterfaceSetup.Modify(false);
    end;

    local procedure Initialize()
    begin
        // Compare texts in English, independent of the session language.
        GlobalLanguage(1033);
    end;
}
