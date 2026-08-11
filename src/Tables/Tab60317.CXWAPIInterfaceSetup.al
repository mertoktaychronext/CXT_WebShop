table 60317 "CXW API Interface Setup"
{
    Caption = 'API Interface Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "CXW Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = ToBeClassified;
            NotBlank = true;
        }
        field(2; "CXW Description"; Text[100])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }
        field(3; "CXW Endpoint URL"; Text[250])
        {
            Caption = 'Endpoint URL';
            DataClassification = ToBeClassified;
        }
        field(4; "CXW Auth Type"; Enum "CXW API Auth Type")
        {
            Caption = 'Auth Type';
            DataClassification = ToBeClassified;
        }
        field(5; "CXW Active"; Boolean)
        {
            Caption = 'Active';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                if "CXW Active" then begin
                    TestField("CXW Endpoint URL");
                    if ("CXW Auth Type" <> "CXW Auth Type"::None) and ("CXW Auth Type" <> "CXW Auth Type"::AWSSigV4) and (GetApiKey() = '') then
                        Error(MissingApiKeyErr, "CXW Auth Type");
                    if "CXW Auth Type" = "CXW Auth Type"::AWSSigV4 then
                        if ("CXW AWS Access Key ID" = '') or ("CXW AWS Region" = '') or ("CXW AWS Service" = '') or (GetAwsSecretAccessKey() = '') then
                            Error(MissingAwsCredentialsErr);
                end;
            end;
        }
        field(6; "CXW Source Table No."; Integer)
        {
            Caption = 'Source Table No.';
            DataClassification = ToBeClassified;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(7; "CXW AWS Access Key ID"; Text[128])
        {
            Caption = 'AWS Access Key ID';
            DataClassification = ToBeClassified;
        }
        field(8; "CXW AWS Region"; Text[20])
        {
            Caption = 'AWS Region';
            DataClassification = ToBeClassified;
        }
        field(9; "CXW AWS Service"; Text[50])
        {
            Caption = 'AWS Service';
            DataClassification = ToBeClassified;
        }
        field(10; "CXW Http Method"; Enum "CXW Http Method")
        {
            Caption = 'HTTP Method';
            DataClassification = ToBeClassified;
        }
        field(11; "CXW SOAP Action"; Text[250])
        {
            Caption = 'SOAP Action';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "CXW Code")
        {
            Clustered = true;
        }
    }

    procedure SetApiKey(NewApiKey: Text)
    var
        ApiKeyIsolatedStorageKey: Text;
    begin
        ApiKeyIsolatedStorageKey := GetApiKeyIsolatedStorageKey();
        if NewApiKey = '' then begin
            if IsolatedStorage.Contains(ApiKeyIsolatedStorageKey, DataScope::Module) then
                IsolatedStorage.Delete(ApiKeyIsolatedStorageKey, DataScope::Module);
            exit;
        end;
        IsolatedStorage.Set(ApiKeyIsolatedStorageKey, NewApiKey, DataScope::Module);
    end;

    procedure GetApiKey(): Text
    var
        ApiKeyValue: Text;
    begin
        if IsolatedStorage.Get(GetApiKeyIsolatedStorageKey(), DataScope::Module, ApiKeyValue) then
            exit(ApiKeyValue);
        exit('');
    end;

    local procedure GetApiKeyIsolatedStorageKey(): Text
    begin
        exit(StrSubstNo('SLAPIInterfaceSetup_ApiKey_%1', "CXW Code"));
    end;

    procedure SetAwsSecretAccessKey(NewKey: Text)
    var
        AwsSecretAccessKeyIsolatedStorageKey: Text;
    begin
        AwsSecretAccessKeyIsolatedStorageKey := GetAwsSecretAccessKeyIsolatedStorageKey();
        if NewKey = '' then begin
            if IsolatedStorage.Contains(AwsSecretAccessKeyIsolatedStorageKey, DataScope::Module) then
                IsolatedStorage.Delete(AwsSecretAccessKeyIsolatedStorageKey, DataScope::Module);
            exit;
        end;
        IsolatedStorage.Set(AwsSecretAccessKeyIsolatedStorageKey, NewKey, DataScope::Module);
    end;

    procedure GetAwsSecretAccessKey(): Text
    var
        AwsSecretAccessKeyValue: Text;
    begin
        if IsolatedStorage.Get(GetAwsSecretAccessKeyIsolatedStorageKey(), DataScope::Module, AwsSecretAccessKeyValue) then
            exit(AwsSecretAccessKeyValue);
        exit('');
    end;

    local procedure GetAwsSecretAccessKeyIsolatedStorageKey(): Text
    begin
        exit(StrSubstNo('SLAPIInterfaceSetup_AwsSecretAccessKey_%1', "CXW Code"));
    end;

    procedure SetAwsSessionToken(NewToken: Text)
    var
        AwsSessionTokenIsolatedStorageKey: Text;
    begin
        AwsSessionTokenIsolatedStorageKey := GetAwsSessionTokenIsolatedStorageKey();
        if NewToken = '' then begin
            if IsolatedStorage.Contains(AwsSessionTokenIsolatedStorageKey, DataScope::Module) then
                IsolatedStorage.Delete(AwsSessionTokenIsolatedStorageKey, DataScope::Module);
            exit;
        end;
        IsolatedStorage.Set(AwsSessionTokenIsolatedStorageKey, NewToken, DataScope::Module);
    end;

    procedure GetAwsSessionToken(): Text
    var
        AwsSessionTokenValue: Text;
    begin
        if IsolatedStorage.Get(GetAwsSessionTokenIsolatedStorageKey(), DataScope::Module, AwsSessionTokenValue) then
            exit(AwsSessionTokenValue);
        exit('');
    end;

    local procedure GetAwsSessionTokenIsolatedStorageKey(): Text
    begin
        exit(StrSubstNo('SLAPIInterfaceSetup_AwsSessionToken_%1', "CXW Code"));
    end;

    var
        MissingApiKeyErr: Label 'Auth Type is set to %1, but no API key has been entered for this interface.', Comment = '%1 = selected authentication type';
        MissingAwsCredentialsErr: Label 'Auth Type is set to AWS Signature V4, but the AWS Access Key ID, Region, Service, or Secret Access Key has not been fully entered for this interface.';
}
