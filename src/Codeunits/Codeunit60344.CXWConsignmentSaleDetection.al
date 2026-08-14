codeunit 60344 "CXW Consignment Sale Detection"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDocCreateConsignmentEntries(var SalesHeader: Record "Sales Header"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean; WhseShip: Boolean; WhseReceiv: Boolean; PreviewMode: Boolean)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        Item: Record Item;
    begin
        // Nur bei tatsaechlicher Rechnungsbuchung (nicht bei reiner Lieferung oder Vorschau) reagieren;
        // die VK-Buchung darf durch diesen Subscriber nie gefaehrdet werden, daher wird jede Zeile einzeln
        // fehlertolerant verarbeitet (siehe TryCreateConsignmentEntry).
        if PreviewMode or (SalesInvHdrNo = '') then
            exit;

        SalesInvoiceLine.SetRange("Document No.", SalesInvHdrNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        if SalesInvoiceLine.FindSet() then
            repeat
                if Item.Get(SalesInvoiceLine."No.") and Item."CXB Consignment Sales" then
                    TryCreateConsignmentEntry(SalesInvoiceLine, SalesInvHdrNo);
            until SalesInvoiceLine.Next() = 0;
    end;

    [TryFunction]
    local procedure TryCreateConsignmentEntry(SalesInvoiceLine: Record "Sales Invoice Line"; SalesInvHdrNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchSetup: Record "Purchases & Payables Setup";
        ConsignmentPostingEntry: Record "CXW Consignment Posting Entry";
    begin
        SalesInvoiceHeader.Get(SalesInvHdrNo);
        PurchSetup.Get();

        ConsignmentPostingEntry.Init();
        ConsignmentPostingEntry."CXW Item No." := SalesInvoiceLine."No.";
        ConsignmentPostingEntry."CXW Sales Invoice No." := SalesInvHdrNo;
        ConsignmentPostingEntry."CXW Sales Posting Date" := SalesInvoiceHeader."Posting Date";
        ConsignmentPostingEntry."CXW Due Date" := SalesInvoiceHeader."Posting Date" + PurchSetup."CXW SW Consignment Invoice Delay (Days)";
        SetPurchaseOrder(ConsignmentPostingEntry, SalesInvoiceLine."No.");
        ConsignmentPostingEntry.Insert();
    end;

    procedure SetPurchaseOrder(var ConsignmentPostingEntry: Record "CXW Consignment Posting Entry"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        MatchCount: Integer;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.SetFilter("Quantity Received", '>0');
        PurchaseLine.SetFilter("Qty. to Invoice", '>0');
        MatchCount := PurchaseLine.Count();

        case MatchCount of
            1:
                begin
                    PurchaseLine.FindFirst();
                    ConsignmentPostingEntry."CXW Purchase Order No." := PurchaseLine."Document No.";
                    ConsignmentPostingEntry."CXW Status" := ConsignmentPostingEntry."CXW Status"::Open;
                end;
            0:
                begin
                    ConsignmentPostingEntry."CXW Status" := ConsignmentPostingEntry."CXW Status"::Error;
                    ConsignmentPostingEntry."CXW Error Text" := CopyStr(StrSubstNo(NoOpenPurchaseOrderErr, ItemNo), 1, MaxStrLen(ConsignmentPostingEntry."CXW Error Text"));
                end;
            else begin
                ConsignmentPostingEntry."CXW Status" := ConsignmentPostingEntry."CXW Status"::Error;
                ConsignmentPostingEntry."CXW Error Text" := CopyStr(StrSubstNo(MultipleOpenPurchaseOrdersErr, ItemNo), 1, MaxStrLen(ConsignmentPostingEntry."CXW Error Text"));
            end;
        end;
    end;

    var
        NoOpenPurchaseOrderErr: Label 'No open, received but not yet invoiced purchase order found for item %1.', Comment = '%1 = item number';
        MultipleOpenPurchaseOrdersErr: Label 'More than one open, received but not yet invoiced purchase order found for item %1.', Comment = '%1 = item number';
}
