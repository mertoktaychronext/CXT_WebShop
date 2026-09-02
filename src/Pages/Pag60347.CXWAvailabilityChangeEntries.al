page 60347 "CXWAvailabilityChange Entries"
{
    Caption = 'Availability Change Entries';
    PageType = List;
    SourceTable = "CXW Availability Change Entry";
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
                field("CXW Entry No."; Rec."CXW Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number of this availability change entry.';
                }
                field("CXW Item No."; Rec."CXW Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number of the moved article.';
                }
                field("CXW Variant Code"; Rec."CXW Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the variant code of the moved article.';
                }
                field("CXW Location Code"; Rec."CXW Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the location code involved in the availability change.';
                }
                field("CXW Inserted At"; Rec."CXW Inserted At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the availability change entry was created.';
                }
                field("CXW Exported"; Rec."CXW Exported")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the availability change entry has already been exported.';
                }
                field("CXW Exported At"; Rec."CXW Exported At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the availability change entry was exported.';
                }
            }
        }
    }
}
