page 60343 "CXW On Demand Purch. Lookup"
{
    Caption = 'Purchase Order Lines';
    PageType = List;
    SourceTable = "Purchase Line";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the purchase order number.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the purchase order line number.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor on the purchase order.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number on the purchase line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description on the purchase line.';
                }
                field("Outstanding Quantity"; Rec."Outstanding Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the outstanding quantity on the purchase line.';
                }
                field("Quantity Received"; Rec."Quantity Received")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how much quantity has already been received on the purchase line.';
                }
                field(PurchaseStatusTxt; PurchaseStatusTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Status';
                    Editable = false;
                    ToolTip = 'Specifies the current status of the purchase order line.';
                }
                field("CXW Sales Order No."; Rec."CXW Sales Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the linked sales order number, if any.';
                }
                field("CXW Sales Line No."; Rec."CXW Sales Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the linked sales order line number, if any.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        SalesLine: Record "Sales Line";
    begin
        Clear(PurchaseStatusTxt);

        if (Rec."CXW Sales Order No." = '') or (Rec."CXW Sales Line No." = 0) then begin
            if PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then
                case PurchaseHeader.Status of
                    PurchaseHeader.Status::Released:
                        PurchaseStatusTxt := ReleasedLbl;
                    else
                        PurchaseStatusTxt := OpenLbl;
                end;
            exit;
        end;

        if SalesLine.Get(SalesLine."Document Type"::Order, Rec."CXW Sales Order No.", Rec."CXW Sales Line No.") then
            PurchaseStatusTxt := OnDemandLinkMgt.GetPurchaseStatusText(SalesLine);
    end;

    var
        OnDemandLinkMgt: Codeunit "CXW On Demand Link Mgt";
        PurchaseHeader: Record "Purchase Header";
        PurchaseStatusTxt: Text[50];
        ReleasedLbl: Label 'Released';
        OpenLbl: Label 'Open';
}
