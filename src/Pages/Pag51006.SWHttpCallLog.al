page 51006 "SW Http Call Log"
{
    Caption = 'SW Http Call Log';
    PageType = List;
    SourceTable = "SW Http Call Log";
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
                field("Entry No"; Rec."Entry No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number of this log entry.';
                }
                field("Call DateTime"; Rec."Call DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the HTTP call was made.';
                }
                field("Source Entry No"; Rec."Source Entry No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Watch Online Approval entry that triggered this call.';
                }
                field("Endpoint URL"; Rec."Endpoint URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the endpoint the request was sent to.';
                }
                field(Success; Rec.Success)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the call completed successfully.';
                }
                field("HTTP Status Code"; Rec."HTTP Status Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the HTTP status code returned by the endpoint, if a response was received.';
                }
                field("Error Message"; Rec."Error Message")
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
                    Rec.CalcFields(Request);
                    Rec.Request.CreateInStream(InStr, TextEncoding::UTF8);
                    FileName := StrSubstNo('SWHttpCallLog_%1_Request.txt', Rec."Entry No");
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
                    Rec.CalcFields(Response);
                    Rec.Response.CreateInStream(InStr, TextEncoding::UTF8);
                    FileName := StrSubstNo('SWHttpCallLog_%1_Response.txt', Rec."Entry No");
                    DownloadFromStream(InStr, '', '', '', FileName);
                end;
            }
        }
    }
}
