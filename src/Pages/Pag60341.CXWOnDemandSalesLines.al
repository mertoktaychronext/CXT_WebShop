page 60341 "CXW On Demand Sales Lines"
{
    Caption = 'On Demand Sales Lines';
    PageType = List;
    SourceTable = "Sales Line";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Options)
            {
                field(SelectedVendorNo; SelectedVendorNo)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor No.';
                    TableRelation = Vendor."No.";
                    ToolTip = 'Specifies the vendor used when creating a purchase order for the selected on-demand sales lines.';
                }
            }
            repeater(Lines)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sales order number.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sales order line number.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer on the sales order.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number on the sales line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item description on the sales line.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity on the sales line.';
                }
                field("Outstanding Quantity"; Rec."Outstanding Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the outstanding quantity on the sales line.';
                }
                field("CXW Purchase Order No."; Rec."CXW Purchase Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the linked purchase order number.';
                }
                field("CXW Purchase Line No."; Rec."CXW Purchase Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the linked purchase order line number.';
                }
                field(PurchaseStatusTxt; PurchaseStatusTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Status';
                    Editable = false;
                    ToolTip = 'Specifies the current status of the linked purchase order line.';
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
                ToolTip = 'Reloads the list of on-demand sales lines that are still open, not released, and without reservation.';

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                end;
            }
            action(LinkPurchaseLine)
            {
                ApplicationArea = All;
                Caption = 'Link Purchase Line';
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Links the selected sales line to an existing purchase order line for the same item.';

                trigger OnAction()
                var
                    SalesLine: Record "Sales Line";
                    PurchaseLine: Record "Purchase Line";
                begin
                    GetSingleSelectedSalesLine(SalesLine);
                    if not OnDemandLinkMgt.LookupPurchaseLineForSalesLine(SalesLine, PurchaseLine) then
                        exit;

                    OnDemandLinkMgt.LinkSalesLineToPurchaseLine(SalesLine, PurchaseLine);
                    LoadLines();
                    CurrPage.Update(false);
                end;
            }
            action(CreatePurchaseOrder)
            {
                ApplicationArea = All;
                Caption = 'Create Purchase Order';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Creates one new purchase order for the selected sales lines and links each new purchase line back to its sales line.';

                trigger OnAction()
                var
                    TempSelectedSalesLines: Record "Sales Line" temporary;
                    PurchaseHeader: Record "Purchase Header";
                    PurchaseOrderNo: Code[20];
                begin
                    GetSelectedSalesLines(TempSelectedSalesLines);
                    PurchaseOrderNo := OnDemandLinkMgt.CreatePurchaseOrderForSalesLines(TempSelectedSalesLines, SelectedVendorNo);
                    if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderNo) then
                        Page.RunModal(Page::"Purchase Order", PurchaseHeader);

                    LoadLines();
                    CurrPage.Update(false);
                end;
            }
            action(ResetLink)
            {
                ApplicationArea = All;
                Caption = 'Reset Link';
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Removes the sales-to-purchase link from the selected sales lines so they can be linked again.';

                trigger OnAction()
                var
                    TempSelectedSalesLines: Record "Sales Line" temporary;
                    SalesLine: Record "Sales Line";
                begin
                    GetSelectedSalesLines(TempSelectedSalesLines);
                    if TempSelectedSalesLines.FindSet() then
                        repeat
                            SalesLine.Get(TempSelectedSalesLines."Document Type", TempSelectedSalesLines."Document No.", TempSelectedSalesLines."Line No.");
                            OnDemandLinkMgt.ResetSalesLineLink(SalesLine);
                        until TempSelectedSalesLines.Next() = 0;

                    LoadLines();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(OpenSalesOrder)
            {
                ApplicationArea = All;
                Caption = 'Open Sales Order';
                ToolTip = 'Opens the sales order of the selected line.';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                    SalesLine: Record "Sales Line";
                begin
                    GetSingleSelectedSalesLine(SalesLine);
                    if SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
                        Page.RunModal(Page::"Sales Order", SalesHeader);
                end;
            }
            action(OpenPurchaseOrder)
            {
                ApplicationArea = All;
                Caption = 'Open Purchase Order';
                ToolTip = 'Opens the linked purchase order of the selected line.';

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                    SalesLine: Record "Sales Line";
                begin
                    GetSingleSelectedSalesLine(SalesLine);
                    SalesLine.TestField("CXW Purchase Order No.");
                    if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, SalesLine."CXW Purchase Order No.") then
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
    begin
        PurchaseStatusTxt := OnDemandLinkMgt.GetPurchaseStatusText(Rec);
    end;

    local procedure LoadLines()
    var
        SalesLine: Record "Sales Line";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("Outstanding Quantity", '>0');
        if SalesLine.FindSet() then
            repeat
                if OnDemandLinkMgt.SalesLineNeedsOnDemandAssignment(SalesLine) then begin
                    Rec := SalesLine;
                    Rec.Insert();
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure GetSelectedSalesLines(var TempSelectedSalesLines: Record "Sales Line" temporary)
    begin
        CurrPage.SetSelectionFilter(Rec);
        if not Rec.FindSet() then
            Error(NoSalesLinesSelectedErr);

        repeat
            TempSelectedSalesLines := Rec;
            TempSelectedSalesLines.Insert();
        until Rec.Next() = 0;
    end;

    local procedure GetSingleSelectedSalesLine(var SalesLine: Record "Sales Line")
    var
        TempSelectedSalesLines: Record "Sales Line" temporary;
    begin
        GetSelectedSalesLines(TempSelectedSalesLines);
        if TempSelectedSalesLines.Count <> 1 then
            Error(SingleLineRequiredErr);

        TempSelectedSalesLines.FindFirst();
        SalesLine.Get(TempSelectedSalesLines."Document Type", TempSelectedSalesLines."Document No.", TempSelectedSalesLines."Line No.");
    end;

    var
        OnDemandLinkMgt: Codeunit "CXW On Demand Link Mgt";
        SelectedVendorNo: Code[20];
        PurchaseStatusTxt: Text[50];
        NoSalesLinesSelectedErr: Label 'Please select at least one sales line.';
        SingleLineRequiredErr: Label 'Please select exactly one sales line.';
}
