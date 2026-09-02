pageextension 60333 "CXW Purchase Order Subform" extends "Purchase Order Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("CXW Sales Order No."; Rec."CXW Sales Order No.")
            {
                ApplicationArea = All;
                Editable = false;
                DrillDown = true;
                ToolTip = 'Specifies the linked sales order number for this purchase line.';

                trigger OnDrillDown()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    if Rec."CXW Sales Order No." = '' then
                        exit;

                    if SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."CXW Sales Order No.") then
                        Page.RunModal(Page::"Sales Order", SalesHeader);
                end;
            }
            field("CXW Sales Line No."; Rec."CXW Sales Line No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the linked sales order line number for this purchase line.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action("CXW Link Sales Line")
            {
                ApplicationArea = All;
                Caption = 'Link Sales Line';
                ToolTip = 'Links the selected purchase line to an open on-demand sales line for the same item.';

                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line";
                    SalesLine: Record "Sales Line";
                begin
                    GetSingleSelectedPurchaseLine(PurchaseLine);
                    if not OnDemandLinkMgt.LookupSalesLineForPurchaseLine(PurchaseLine, SalesLine) then
                        exit;

                    OnDemandLinkMgt.LinkSalesLineToPurchaseLine(SalesLine, PurchaseLine);
                    CurrPage.Update(false);
                end;
            }
            action("CXW Reset On-Demand Link")
            {
                ApplicationArea = All;
                Caption = 'Reset On-Demand Link';
                ToolTip = 'Removes the purchase-to-sales link from the selected purchase lines.';

                trigger OnAction()
                var
                    TempSelectedPurchaseLines: Record "Purchase Line" temporary;
                    PurchaseLine: Record "Purchase Line";
                begin
                    GetSelectedPurchaseLines(TempSelectedPurchaseLines);
                    if TempSelectedPurchaseLines.FindSet() then
                        repeat
                            PurchaseLine.Get(TempSelectedPurchaseLines."Document Type", TempSelectedPurchaseLines."Document No.", TempSelectedPurchaseLines."Line No.");
                            OnDemandLinkMgt.ResetPurchaseLineLink(PurchaseLine);
                        until TempSelectedPurchaseLines.Next() = 0;

                    CurrPage.Update(false);
                end;
            }
            action("CXW Open On-Demand Purchase Lines")
            {
                ApplicationArea = All;
                Caption = 'Open On-Demand Purchase Lines';
                ToolTip = 'Opens the work list of open on-demand purchase lines without a sales assignment.';

                trigger OnAction()
                begin
                    Page.RunModal(Page::"CXW On Demand Purchase Lines");
                end;
            }
        }
    }

    local procedure GetSelectedPurchaseLines(var TempSelectedPurchaseLines: Record "Purchase Line" temporary)
    begin
        CurrPage.SetSelectionFilter(Rec);
        if not Rec.FindSet() then
            Error(NoPurchaseLinesSelectedErr);

        repeat
            TempSelectedPurchaseLines := Rec;
            TempSelectedPurchaseLines.Insert();
        until Rec.Next() = 0;
    end;

    local procedure GetSingleSelectedPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        TempSelectedPurchaseLines: Record "Purchase Line" temporary;
    begin
        GetSelectedPurchaseLines(TempSelectedPurchaseLines);
        if TempSelectedPurchaseLines.Count <> 1 then
            Error(SingleLineRequiredErr);

        TempSelectedPurchaseLines.FindFirst();
        PurchaseLine.Get(TempSelectedPurchaseLines."Document Type", TempSelectedPurchaseLines."Document No.", TempSelectedPurchaseLines."Line No.");
    end;

    var
        OnDemandLinkMgt: Codeunit "CXW On Demand Link Mgt";
        NoPurchaseLinesSelectedErr: Label 'Please select at least one purchase line.';
        SingleLineRequiredErr: Label 'Please select exactly one purchase line.';
}
