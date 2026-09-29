page 60350 "CXW Realtime Inventory"
{
    Caption = 'Realtime Inventory';
    PageType = List;
    SourceTable = "CXW Realtime Inventory";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("CXW Serial No."; Rec."CXW Serial No.") { ApplicationArea = All; }
                field("CXW Item No."; Rec."CXW Item No.") { ApplicationArea = All; }
                field("CXW Variant Code"; Rec."CXW Variant Code") { ApplicationArea = All; }
                field("CXW Quantity"; Rec."CXW Quantity") { ApplicationArea = All; }
                field("CXW Location Code"; Rec."CXW Location Code") { ApplicationArea = All; }
                field("CXW Brand"; Rec."CXW Brand") { ApplicationArea = All; }
                field("CXW Model"; Rec."CXW Model") { ApplicationArea = All; }
                field("CXW Reference"; Rec."CXW Reference") { ApplicationArea = All; }
                field("CXW Variant Category"; Rec."CXW Variant Category") { ApplicationArea = All; }
                field("CXW Condition"; Rec."CXW Condition") { ApplicationArea = All; }
                field("CXW Certificate"; Rec."CXW Certificate") { ApplicationArea = All; }
                field("CXW Visibility"; Rec."CXW Visibility") { ApplicationArea = All; }
                field("CXW Sales Price"; Rec."CXW Sales Price") { ApplicationArea = All; }
                field("CXW Purchase Price"; Rec."CXW Purchase Price") { ApplicationArea = All; }
                field("CXW Differential Taxation"; Rec."CXW Differential Taxation") { ApplicationArea = All; }
                field("CXW Posting Date"; Rec."CXW Posting Date") { ApplicationArea = All; }
                field("CXW Purchase Order No."; Rec."CXW Purchase Order No.") { ApplicationArea = All; }
                field("CXW Vendor No."; Rec."CXW Vendor No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                ApplicationArea = All;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Rebuilds the realtime inventory for the current company from open item ledger entries.';

                trigger OnAction()
                var
                    RealtimeInventoryMgt: Codeunit "CXW Realtime Inventory Mgt.";
                begin
                    if not Confirm(RefreshQst, false) then
                        exit;
                    RealtimeInventoryMgt.RefreshCurrentCompany();
                    CurrPage.Update(false);
                    Message(RefreshDoneMsg);
                end;
            }
        }
    }

    var
        RefreshQst: Label 'Do you want to refresh the realtime inventory for the current company?';
        RefreshDoneMsg: Label 'Realtime inventory has been refreshed.';
}
