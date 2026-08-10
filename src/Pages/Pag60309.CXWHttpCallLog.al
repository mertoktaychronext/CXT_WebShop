page 60309 "CXW Http Call Log"
{
    Caption = 'Http Call Log';
    PageType = List;
    SourceTable = "CXW Http Call Log";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("CXW Entry No"; Rec."CXW Entry No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number of this log entry.';
                }
                field("CXW Call DateTime"; Rec."CXW Call DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the HTTP call was made.';
                }
                field("CXW Source Table No."; Rec."CXW Source Table No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which source table (and therefore which feature) triggered this call.';
                }
                field("CXW Source Entry No"; Rec."CXW Source Entry No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry in the source table that triggered this call.';
                }
                field("CXW Endpoint URL"; Rec."CXW Endpoint URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the endpoint the request was sent to.';
                }
                field("CXW Success"; Rec."CXW Success")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the call completed successfully.';
                }
                field("CXW HTTP Status Code"; Rec."CXW HTTP Status Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the HTTP status code returned by the endpoint, if a response was received.';
                }
                field("CXW Error Message"; Rec."CXW Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message recorded for a failed call.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DownloadRequest)
            {
                Caption = 'Download Request';
                ApplicationArea = All;
                Image = Export;
                ToolTip = 'Download the logged request as a .txt file.';

                trigger OnAction()
                var
                    InStr: InStream;
                    FileName: Text;
                begin
                    Rec.CalcFields("CXW Request");
                    Rec."CXW Request".CreateInStream(InStr, TextEncoding::UTF8);
                    FileName := StrSubstNo('HttpCallLog_%1_Request.txt', Rec."CXW Entry No");
                    DownloadFromStream(InStr, '', '', '', FileName);
                end;
            }
            action(DownloadResponse)
            {
                Caption = 'Download Response';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Download the logged response as a .txt file.';

                trigger OnAction()
                var
                    InStr: InStream;
                    FileName: Text;
                begin
                    Rec.CalcFields("CXW Response");
                    Rec."CXW Response".CreateInStream(InStr, TextEncoding::UTF8);
                    FileName := StrSubstNo('HttpCallLog_%1_Response.txt', Rec."CXW Entry No");
                    DownloadFromStream(InStr, '', '', '', FileName);
                end;
            }
        }
    }
}
