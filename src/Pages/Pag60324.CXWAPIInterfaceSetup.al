page 60324 "CXW API Interface Setup"
{
    Caption = 'API Interface Setup';
    PageType = List;
    SourceTable = "CXW API Interface Setup";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("CXW Code"; Rec."CXW Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code of this API interface.';
                }
                field("CXW Description"; Rec."CXW Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of this API interface.';
                }
                field("CXW Endpoint URL"; Rec."CXW Endpoint URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the endpoint URL that data is sent to.';
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
                field("CXW Auth Type"; Rec."CXW Auth Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how requests to this endpoint are authenticated.';
                }
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
                    end;
                }
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
                    end;
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
                    end;
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
        }
    }

    var
        g_txtApiKey: Text;
        g_txtAwsSecretAccessKey: Text;
        g_txtAwsSessionToken: Text;
}
