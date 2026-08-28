page 60345 "CXW On Demand Sales Lookup"
{
    Caption = 'On-Demand Sales Lines';
    PageType = List;
    SourceTable = "Sales Line";
    SourceTableTemporary = true;
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
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadLines();
    end;

    procedure SetPurchaseLineFilter(PurchaseLine: Record "Purchase Line")
    begin
        FilterItemNo := PurchaseLine."No.";
    end;

    procedure GetRecord(var SalesLine: Record "Sales Line")
    begin
        CurrPage.SetSelectionFilter(Rec);
        if not Rec.FindFirst() then
            exit;

        SalesLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.");
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
        if FilterItemNo <> '' then
            SalesLine.SetRange("No.", FilterItemNo);

        if SalesLine.FindSet() then
            repeat
                if OnDemandLinkMgt.SalesLineNeedsOnDemandAssignment(SalesLine) and
                   (SalesLine."CXW Purchase Order No." = '') and
                   (SalesLine."CXW Purchase Line No." = 0)
                then begin
                    Rec := SalesLine;
                    Rec.Insert();
                end;
            until SalesLine.Next() = 0;
    end;

    var
        OnDemandLinkMgt: Codeunit "CXW On Demand Link Mgt";
        FilterItemNo: Code[20];
}
