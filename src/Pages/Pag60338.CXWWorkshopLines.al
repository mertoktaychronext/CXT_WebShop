page 60338 "CXW Workshop Lines"
{
    Caption = 'Workshop Lines';
    PageType = List;
    SourceTable = "CXW Workshop Line";
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
                field("CXW Document Type"; Rec."CXW Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the purchase document type this workshop line belongs to.';
                }
                field("CXW Document No."; Rec."CXW Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the purchase document number this workshop line belongs to.';
                }
                field("CXW Line No."; Rec."CXW Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the purchase line number this workshop line belongs to.';
                }
                field("CXW Item No."; Rec."CXW Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item that was sent to the workshop.';
                }
                field("CXW Manufacturer Serial No."; Rec."CXW Manufacturer Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the manufacturer serial number captured when the item was sent to the workshop.';
                }
                field("CXW Status"; Rec."CXW Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current workshop review status.';
                }
                field("CXW Genuine"; Rec."CXW Genuine")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the workshop confirmed the item as genuine.';
                }
                field("CXW Attribute 1"; Rec."CXW Attribute 1")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies attribute 1 as reported by the workshop.';
                }
                field("CXW Attribute 2"; Rec."CXW Attribute 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies attribute 2 as reported by the workshop.';
                }
                field("CXW Attribute 3"; Rec."CXW Attribute 3")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies attribute 3 as reported by the workshop.';
                }
                field("CXW Attribute 4"; Rec."CXW Attribute 4")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies attribute 4 as reported by the workshop.';
                }
                field("CXW Attribute 5"; Rec."CXW Attribute 5")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies attribute 5 as reported by the workshop.';
                }
                field("CXW Attribute 6"; Rec."CXW Attribute 6")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies attribute 6 as reported by the workshop.';
                }
                field("CXW Attribute 7"; Rec."CXW Attribute 7")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies attribute 7 as reported by the workshop.';
                }
                field("CXW Attribute 8"; Rec."CXW Attribute 8")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies attribute 8 as reported by the workshop.';
                }
                field("CXW Attribute 9"; Rec."CXW Attribute 9")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies attribute 9 as reported by the workshop.';
                }
                field("CXW Attribute 10"; Rec."CXW Attribute 10")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies attribute 10 as reported by the workshop.';
                }
                field("CXW Created At"; Rec."CXW Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this workshop line was created.';
                }
                field("CXW Checked At"; Rec."CXW Checked At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the workshop set the status to "WS checked".';
                }
                field("CXW Last Error"; Rec."CXW Last Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last error encountered while processing this workshop line.';
                }
            }
        }
    }
}
