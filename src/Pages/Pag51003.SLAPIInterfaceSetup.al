page 51003 "SL API Interface Setup"
{
    Caption = 'API Interface Setup';
    PageType = List;
    SourceTable = "SL API Interface Setup";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code of this API interface.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of this API interface.';
                }
                field("Endpoint URL"; Rec."Endpoint URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the endpoint URL that data is sent to.';
                }
                field("Auth Type"; Rec."Auth Type")
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
                field("Source Table No."; Rec."Source Table No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which table this interface transmits data for.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this interface can be selected and used for sending data.';
                }
            }
        }
    }

    var
        g_txtApiKey: Text;
}
