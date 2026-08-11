page 60323 "CXW Sales Price Archive"
{
    Caption = 'Sales Price Archive';
    PageType = List;
    SourceTable = "CXW Sales Price Archive";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("CXW Item No."; Rec."CXW Item No.")
                {
                    ApplicationArea = All;
                }
                field("CXW Currency Code"; Rec."CXW Currency Code")
                {
                    ApplicationArea = All;
                }
                field("CXW Stock Price"; Rec."CXW Stock Price")
                {
                    ApplicationArea = All;
                }
                field("CXW Old Stock Price"; Rec."CXW Old Stock Price")
                {
                    ApplicationArea = All;
                }
                field("CXW Recom. Retail Price"; Rec."CXW Recom. Retail Price")
                {
                    ApplicationArea = All;
                }
                field("CXW Strike Price"; Rec."CXW Strike Price")
                {
                    ApplicationArea = All;
                }
                field("CXW Reason Code"; Rec."CXW Reason Code")
                {
                    ApplicationArea = All;
                }
                field("CXW Comment"; Rec."CXW Comment")
                {
                    ApplicationArea = All;
                }
                field("CXW Version No."; Rec."CXW Version No.")
                {
                    ApplicationArea = All;
                }
                field("CXW Last Modified UserID"; Rec."CXW Last Modified UserID")
                {
                    ApplicationArea = All;
                }
                field("CXW Last Modified Date"; Rec."CXW Last Modified Date")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
