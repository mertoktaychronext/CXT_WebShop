codeunit 60335 "CXW Workshop Line Mgt."
{
    // Copies the purchase order and watch data the workshop needs onto the workshop line
    // (snapshot at hand-over), used by "Send to Workshop" and by the upgrade of existing lines.
    procedure FillPurchaseData(var WorkshopLine: Record "CXW Workshop Line"; PurchLine: Record "Purchase Line")
    var
        PurchHeader: Record "Purchase Header";
    begin
        if PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.") then begin
            WorkshopLine."CXW Vendor Order No." := PurchHeader."Vendor Order No.";
            WorkshopLine."CXW Vendor No." := PurchHeader."Buy-from Vendor No.";
            WorkshopLine."CXW Vendor Name" := PurchHeader."Buy-from Vendor Name";
            WorkshopLine."CXW Currency Code" := GetCurrencyCode(PurchHeader."Currency Code");
        end;

        WorkshopLine."CXW Variant Code" := PurchLine."Variant Code";
        WorkshopLine."CXW Description" := PurchLine.Description;
        WorkshopLine."CXW Quantity" := PurchLine.Quantity;
        WorkshopLine."CXW Unit Price" := PurchLine."Direct Unit Cost";
        WorkshopLine."CXW Used Goods" := PurchLine."Used Good";

        // Attribute IDs as agreed with the workshop; a missing value leaves the field empty.
        WorkshopLine."CXW Brand" := GetItemAttributeValue(PurchLine."No.", BrandAttributeId());
        WorkshopLine."CXW Model" := GetItemAttributeValue(PurchLine."No.", ModelAttributeId());
        WorkshopLine."CXW Sub Model" := GetItemAttributeValue(PurchLine."No.", SubModelAttributeId());
        WorkshopLine."CXW Reference" := GetItemAttributeValue(PurchLine."No.", ReferenceAttributeId());
        WorkshopLine."CXW Year" := GetItemAttributeInteger(PurchLine."No.", YearAttributeId());
        WorkshopLine."CXW Condition" := GetItemAttributeValue(PurchLine."No.", ConditionAttributeId());
        WorkshopLine."CXW Box" := GetItemAttributeValue(PurchLine."No.", BoxAttributeId());
        WorkshopLine."CXW Certificate" := GetItemAttributeValue(PurchLine."No.", CertificateAttributeId());
    end;

    local procedure GetCurrencyCode(pCurrencyCode: Code[10]): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        // The workshop always gets a currency code, also for orders in local currency.
        if pCurrencyCode <> '' then
            exit(pCurrencyCode);
        GLSetup.Get();
        exit(GLSetup."LCY Code");
    end;

    local procedure GetItemAttributeValue(pItemNo: Code[20]; pAttributeId: Integer): Text[250]
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        if not ItemAttributeValueMapping.Get(Database::Item, pItemNo, pAttributeId) then
            exit('');
        if not ItemAttributeValue.Get(pAttributeId, ItemAttributeValueMapping."Item Attribute Value ID") then
            exit('');
        exit(ItemAttributeValue.Value);
    end;

    local procedure GetItemAttributeInteger(pItemNo: Code[20]; pAttributeId: Integer): Integer
    var
        Result: Integer;
    begin
        // Non-numeric values (e.g. a year range) are sent as 0.
        if Evaluate(Result, GetItemAttributeValue(pItemNo, pAttributeId)) then
            exit(Result);
        exit(0);
    end;

    local procedure BrandAttributeId(): Integer
    begin
        exit(1);
    end;

    local procedure ModelAttributeId(): Integer
    begin
        exit(2);
    end;

    local procedure SubModelAttributeId(): Integer
    begin
        exit(3);
    end;

    local procedure ReferenceAttributeId(): Integer
    begin
        exit(5);
    end;

    local procedure YearAttributeId(): Integer
    begin
        exit(8);
    end;

    local procedure ConditionAttributeId(): Integer
    begin
        exit(10);
    end;

    local procedure BoxAttributeId(): Integer
    begin
        exit(11);
    end;

    local procedure CertificateAttributeId(): Integer
    begin
        exit(13);
    end;
}
