page 51002 "SL Sales Price Archive"
{
    Caption = 'Sales Price Archive';
    PageType = List;
    SourceTable = "SL Sales Price Archive";
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
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field("Stock Price"; Rec."Stock Price")
                {
                    ApplicationArea = All;
                }
                field("Old Stock Price"; Rec."Old Stock Price")
                {
                    ApplicationArea = All;
                }
                field("Recom. Retail Price"; Rec."Recom. Retail Price")
                {
                    ApplicationArea = All;
                }
                field("Strike Price"; Rec."Strike Price")
                {
                    ApplicationArea = All;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                }
                field("Country Code"; Rec."Country Code")
                {
                    ApplicationArea = All;
                }
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = All;
                }
                field("Last Modified UserID"; Rec."Last Modified UserID")
                {
                    ApplicationArea = All;
                }
                field("Last Modified Date"; Rec."Last Modified Date")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
