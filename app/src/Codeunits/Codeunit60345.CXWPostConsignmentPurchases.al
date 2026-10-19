codeunit 60345 "CXW Post Consignment Purchases"
{
    trigger OnRun()
    begin
        ProcessDueEntries();
    end;

    local procedure ProcessDueEntries()
    var
        ConsignmentPostingEntry: Record "CXW Consignment Posting Entry";
    begin
        ConsignmentPostingEntry.SetRange("CXW Status", ConsignmentPostingEntry."CXW Status"::Open);
        ConsignmentPostingEntry.SetFilter("CXW Due Date", '<=%1', Today);
        if ConsignmentPostingEntry.FindSet() then
            repeat
                ProcessEntryWithErrorHandling(ConsignmentPostingEntry);
            until ConsignmentPostingEntry.Next() = 0;
    end;

    local procedure ProcessEntryWithErrorHandling(ConsignmentPostingEntry: Record "CXW Consignment Posting Entry")
    begin
        if TryProcessEntry(ConsignmentPostingEntry) then begin
            ConsignmentPostingEntry.Get(ConsignmentPostingEntry."CXW Entry No");
            ConsignmentPostingEntry."CXW Status" := ConsignmentPostingEntry."CXW Status"::Posted;
            ConsignmentPostingEntry."CXW Error Text" := '';
            ConsignmentPostingEntry.Modify();
            Commit();
        end else begin
            ConsignmentPostingEntry.Get(ConsignmentPostingEntry."CXW Entry No");
            ConsignmentPostingEntry."CXW Status" := ConsignmentPostingEntry."CXW Status"::Error;
            ConsignmentPostingEntry."CXW Error Text" := CopyStr(GetLastErrorText(), 1, MaxStrLen(ConsignmentPostingEntry."CXW Error Text"));
            ConsignmentPostingEntry.Modify();
            Commit();
        end;
    end;

    [TryFunction]
    local procedure TryProcessEntry(var ConsignmentPostingEntry: Record "CXW Consignment Posting Entry")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ConsignmentSaleDetection: Codeunit "CXW Consignment Sale Detection";
        QtyToInvoice: Decimal;
    begin
        // Bei Eintraegen, die bereits bei der Ersterkennung ohne PO-Zuordnung angelegt wurden
        // (0 oder >1 Treffer, siehe Codeunit "CXW Consignment Sale Detection"), erneut versuchen,
        // die offene Bestellung zu ermitteln - sonst laeuft "Erneut versuchen" auf der List-Page ins Leere.
        if ConsignmentPostingEntry."CXW Purchase Order No." = '' then begin
            ConsignmentSaleDetection.SetPurchaseOrder(ConsignmentPostingEntry, ConsignmentPostingEntry."CXW Item No.");
            if ConsignmentPostingEntry."CXW Status" = ConsignmentPostingEntry."CXW Status"::Error then
                Error(ConsignmentPostingEntry."CXW Error Text");
            // Sofort persistieren, sonst ueberschreibt der Erfolgs-Zweig in ProcessEntryWithErrorHandling
            // (Get() per Entry No) die hier ermittelte PO-Nr. wieder mit dem noch leeren Altwert aus der DB.
            ConsignmentPostingEntry.Modify();
        end;

        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, ConsignmentPostingEntry."CXW Purchase Order No.");

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();

        QtyToInvoice := PurchaseLine."Quantity Received" - PurchaseLine."Quantity Invoiced";
        if QtyToInvoice <= 0 then
            Error(NothingToInvoiceErr, PurchaseLine."Document No.");

        if PurchaseHeader."Vendor Invoice No." = '' then begin
            PurchaseHeader.Validate("Vendor Invoice No.", CopyStr(ConsignmentPostingEntry."CXW Sales Invoice No." + '-CONS', 1, MaxStrLen(PurchaseHeader."Vendor Invoice No.")));
            PurchaseHeader.Modify(true);
        end;

        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);

        PurchaseHeader.Receive := false;
        PurchaseHeader.Invoice := true;
        if not Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader) then
            Error(GetLastErrorText());
    end;

    var
        NothingToInvoiceErr: Label 'Purchase order %1 has no remaining received, not yet invoiced quantity.', Comment = '%1 = purchase order number';
}
