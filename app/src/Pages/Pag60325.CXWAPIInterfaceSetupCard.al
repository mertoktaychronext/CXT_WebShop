page 60325 "CXW API Interface Setup Card"
{
    Caption = 'API Interface Setup Card';
    PageType = Card;
    SourceTable = "CXW API Interface Setup";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("CXW Auth Type"; Rec."CXW Auth Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how requests to this endpoint are authenticated.';

                    trigger OnValidate()
                    begin
                        ShowApiKeyField := Rec.IsApiKeyFieldRelevant();
                        ShowAwsFields := Rec.IsAwsFieldsRelevant();
                        CurrPage.Update(true);
                    end;
                }
                field("CXW Http Method"; Rec."CXW Http Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the HTTP method used to send requests to this endpoint.';
                }
                field("CXW SOAP Action"; Rec."CXW SOAP Action")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value sent in the SOAPAction header. Leave blank to omit the header.';
                }
                field("CXW Source Table No."; Rec."CXW Source Table No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which table this interface transmits data for.';
                }
                field("CXW Active"; Rec."CXW Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this interface can be selected and used for sending data.';
                }
            }
            group(Authentication)
            {
                Caption = 'Authentication';

                // Field-level Visible is only evaluated when the page opens; group-level Visible is
                // re-evaluated on CurrPage.Update, so the auth-type specific fields live in subgroups.
                group(ApiKeyGroup)
                {
                    ShowCaption = false;
                    Visible = ShowApiKeyField;

                    field(ApiKey; g_txtApiKey)
                    {
                        ApplicationArea = All;
                        Caption = 'API Key';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the API key or token used to authenticate against the endpoint. The value is stored securely and is not shown again once saved.';

                        trigger OnValidate()
                        begin
                            Rec.SetApiKey(g_txtApiKey);
                            g_txtApiKey := '';
                            UpdateSecretHints();
                        end;
                    }
                    field(ApiKeyHint; g_txtApiKeyHint)
                    {
                        ApplicationArea = All;
                        Caption = 'Stored API Key';
                        Editable = false;
                        ToolTip = 'Specifies the last 4 characters of the stored API key, so you can check which key is in use without revealing it.';
                    }
                }
                group(AwsGroup)
                {
                    ShowCaption = false;
                    Visible = ShowAwsFields;

                    field("CXW AWS Access Key ID"; Rec."CXW AWS Access Key ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the AWS Access Key ID used to sign requests with AWS Signature V4.';
                    }
                    field("CXW AWS Region"; Rec."CXW AWS Region")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the AWS region used when signing requests with AWS Signature V4.';
                    }
                    field("CXW AWS Service"; Rec."CXW AWS Service")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the AWS service name used when signing requests with AWS Signature V4, typically execute-api for API Gateway.';
                    }
                    field(AwsSecretAccessKey; g_txtAwsSecretAccessKey)
                    {
                        ApplicationArea = All;
                        Caption = 'AWS Secret Access Key';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the AWS Secret Access Key used to sign requests with AWS Signature V4. The value is stored securely and is not shown again once saved.';

                        trigger OnValidate()
                        begin
                            Rec.SetAwsSecretAccessKey(g_txtAwsSecretAccessKey);
                            g_txtAwsSecretAccessKey := '';
                            UpdateSecretHints();
                        end;
                    }
                    field(AwsSecretAccessKeyHint; g_txtAwsSecretAccessKeyHint)
                    {
                        ApplicationArea = All;
                        Caption = 'Stored AWS Secret Access Key';
                        Editable = false;
                        ToolTip = 'Specifies the last 4 characters of the stored AWS Secret Access Key, so you can check which key is in use without revealing it.';
                    }
                    field(AwsSessionToken; g_txtAwsSessionToken)
                    {
                        ApplicationArea = All;
                        Caption = 'AWS Session Token';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the AWS Session Token used for temporary/STS-issued credentials when signing requests with AWS Signature V4. Leave blank for long-lived credentials. The value is stored securely and is not shown again once saved.';

                        trigger OnValidate()
                        begin
                            Rec.SetAwsSessionToken(g_txtAwsSessionToken);
                            g_txtAwsSessionToken := '';
                            UpdateSecretHints();
                        end;
                    }
                    field(AwsSessionTokenHint; g_txtAwsSessionTokenHint)
                    {
                        ApplicationArea = All;
                        Caption = 'Stored AWS Session Token';
                        Editable = false;
                        ToolTip = 'Specifies the last 4 characters of the stored AWS Session Token, so you can check which token is in use without revealing it.';
                    }
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ShowApiKeyField := Rec.IsApiKeyFieldRelevant();
        ShowAwsFields := Rec.IsAwsFieldsRelevant();
        UpdateSecretHints();
    end;

    local procedure UpdateSecretHints()
    begin
        g_txtApiKeyHint := Rec.GetApiKeyHint();
        g_txtAwsSecretAccessKeyHint := Rec.GetAwsSecretAccessKeyHint();
        g_txtAwsSessionTokenHint := Rec.GetAwsSessionTokenHint();
    end;

    var
        g_txtApiKey: Text;
        g_txtAwsSecretAccessKey: Text;
        g_txtAwsSessionToken: Text;
        g_txtApiKeyHint: Text;
        g_txtAwsSecretAccessKeyHint: Text;
        g_txtAwsSessionTokenHint: Text;
        ShowApiKeyField: Boolean;
        ShowAwsFields: Boolean;
}
