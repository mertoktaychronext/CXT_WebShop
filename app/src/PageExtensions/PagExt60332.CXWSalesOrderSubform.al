pageextension 60332 "CXW Sales Order Subform" extends "Sales Order Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("CXW Purchase Order No."; Rec."CXW Purchase Order No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the linked purchase order number for this sales line.';
            }
            field("CXW Purchase Line No."; Rec."CXW Purchase Line No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the linked purchase order line number for this sales line.';
            }
            field(CXWPurchaseStatus; PurchaseStatusTxt)
            {
                ApplicationArea = All;
                Caption = 'Purchase Status';
                Editable = false;
                ToolTip = 'Specifies the current status of the linked purchase order line.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PurchaseStatusTxt := OnDemandLinkMgt.GetPurchaseStatusText(Rec);
    end;

    var
        OnDemandLinkMgt: Codeunit "CXW On Demand Link Mgt";
        PurchaseStatusTxt: Text[50];
}
