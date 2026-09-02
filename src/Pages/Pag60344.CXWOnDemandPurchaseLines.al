page 60344 "CXW On Demand Purchase Lines"
{
    Caption = 'On-Demand Purchase Lines';
    PageType = List;
    SourceTable = "Purchase Line";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = false;
    DeleteAllowed = false;
    Editable = false;
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
                    DrillDown = true;
                    ToolTip = 'Specifies the purchase order number.';

                    trigger OnDrillDown()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        if PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then
                            Page.RunModal(Page::"Purchase Order", PurchaseHeader);
                    end;
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
                    ToolTip = 'Specifies the current status of the purchase order.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshLines)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                ToolTip = 'Reloads the list of open on-demand purchase lines that are not yet linked to a sales line.';

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                end;
            }
            action(LinkSalesLine)
            {
                ApplicationArea = All;
                Caption = 'Link Sales Line';
                Promoted = true;
                PromotedCategory = Process;
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
                    LoadLines();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(OpenPurchaseOrder)
            {
                ApplicationArea = All;
                Caption = 'Open Purchase Order';
                ToolTip = 'Opens the purchase order of the selected line.';

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                    PurchaseLine: Record "Purchase Line";
                begin
                    GetSingleSelectedPurchaseLine(PurchaseLine);
                    if PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
                        Page.RunModal(Page::"Purchase Order", PurchaseHeader);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadLines();
    end;

    trigger OnAfterGetRecord()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Clear(PurchaseStatusTxt);

        if PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then
            case PurchaseHeader.Status of
                PurchaseHeader.Status::Released:
                    PurchaseStatusTxt := ReleasedLbl;
                else
                    PurchaseStatusTxt := OpenLbl;
            end;
    end;

    local procedure LoadLines()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetFilter("Outstanding Quantity", '>0');
        if PurchaseLine.FindSet() then
            repeat
                if OnDemandLinkMgt.PurchaseLineNeedsOnDemandAssignment(PurchaseLine) then begin
                    Rec := PurchaseLine;
                    Rec.Insert();
                end;
            until PurchaseLine.Next() = 0;
    end;

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
        PurchaseStatusTxt: Text[50];
        ReleasedLbl: Label 'Released';
        OpenLbl: Label 'Open';
        NoPurchaseLinesSelectedErr: Label 'Please select at least one purchase line.';
        SingleLineRequiredErr: Label 'Please select exactly one purchase line.';
}
