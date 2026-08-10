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
                    if ("CXW Auth Type" <> "CXW Auth Type"::None) and (GetApiKey() = '') then
                        Error(MissingApiKeyErr, "CXW Auth Type");
                end;
            end;
        }
        field(6; "CXW Source Table No."; Integer)
        {
            Caption = 'Source Table No.';
            DataClassification = ToBeClassified;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
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

    var
        MissingApiKeyErr: Label 'Auth Type is set to %1, but no API key has been entered for this interface.', Comment = '%1 = selected authentication type';
}
