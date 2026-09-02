codeunit 60349 "CXW Availability Calculation"
{
    procedure GetArticleAvailability(ItemNo: Code[20]): Decimal
    begin
        exit(
          GetInventoryAtAvailabilityLocation(ItemNo) +
          GetOpenPurchaseQuantity(ItemNo) -
          GetOpenSalesQuantity(ItemNo) +
          GetInboundTransferQuantity(ItemNo) -
          GetOutboundTransferQuantity(ItemNo));
    end;

    procedure GetArticleAvailabilityAtLocation(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    begin
        if LocationCode <> GetAvailabilityLocationCode() then
            exit(0);

        exit(GetArticleAvailability(ItemNo));
    end;

    procedure TryGetArticleDeliveryDate(ItemNo: Code[20]; CountryRegionCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; var DeliveryDate: Date): Boolean
    var
        Availability: Decimal;
        DeliveryFormula: DateFormula;
    begin
        Availability := GetArticleAvailability(ItemNo);
        if not TryGetBaseDeliveryFormula(ItemNo, Availability, DeliveryFormula) then
            exit(false);

        DeliveryDate := Today;
        ApplyDeliveryFormula(DeliveryDate, DeliveryFormula);
        ApplyCountryDeliveryTime(DeliveryDate, CountryRegionCode);

        if Availability > 0 then
            ApplyWarehouseDeliveryTime(DeliveryDate, ZoneCode, BinCode);

        exit(true);
    end;

    procedure TryGetArticleDeliveryDays(ItemNo: Code[20]; CountryRegionCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; var DeliveryDays: Integer): Boolean
    var
        DeliveryDate: Date;
    begin
        if not TryGetArticleDeliveryDate(ItemNo, CountryRegionCode, ZoneCode, BinCode, DeliveryDate) then
            exit(false);

        DeliveryDays := DeliveryDate - Today;
        exit(true);
    end;

    local procedure GetInventoryAtAvailabilityLocation(ItemNo: Code[20]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", GetAvailabilityLocationCode());
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.CalcSums("Remaining Quantity");

        exit(ItemLedgerEntry."Remaining Quantity");
    end;

    local procedure GetOpenPurchaseQuantity(ItemNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        OpenPurchaseQuantity: Decimal;
    begin
        if not IsReplenishable(ItemNo) then
            exit(0);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.SetRange("Location Code", GetAvailabilityLocationCode());
        PurchaseLine.SetFilter("Outstanding Qty. (Base)", '>0');
        if PurchaseLine.FindSet() then
            repeat
                if HasRelevantInboundDate(PurchaseLine."Expected Receipt Date", PurchaseLine."Promised Receipt Date") then
                    OpenPurchaseQuantity += PurchaseLine."Outstanding Qty. (Base)";
            until PurchaseLine.Next() = 0;

        exit(OpenPurchaseQuantity);
    end;

    local procedure GetOpenSalesQuantity(ItemNo: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.SetRange("Location Code", GetAvailabilityLocationCode());
        SalesLine.SetFilter("Outstanding Qty. (Base)", '>0');
        SalesLine.CalcSums("Outstanding Qty. (Base)");

        exit(SalesLine."Outstanding Qty. (Base)");
    end;

    local procedure GetOutboundTransferQuantity(ItemNo: Code[20]): Decimal
    begin
        exit(GetOpenTransferQuantity(ItemNo, GetAvailabilityLocationCode(), TransferLocationCodeLbl));
    end;

    local procedure GetInboundTransferQuantity(ItemNo: Code[20]): Decimal
    begin
        exit(GetOpenTransferQuantity(ItemNo, TransferLocationCodeLbl, GetAvailabilityLocationCode()));
    end;

    local procedure GetOpenTransferQuantity(ItemNo: Code[20]; TransferFromCode: Code[10]; TransferToCode: Code[10]): Decimal
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.SetRange("Transfer-from Code", TransferFromCode);
        TransferLine.SetRange("Transfer-to Code", TransferToCode);
        TransferLine.SetFilter("Outstanding Qty. (Base)", '>0');
        TransferLine.CalcSums("Outstanding Qty. (Base)");

        exit(TransferLine."Outstanding Qty. (Base)");
    end;

    local procedure HasRelevantInboundDate(ExpectedReceiptDate: Date; PromisedReceiptDate: Date): Boolean
    begin
        exit(((ExpectedReceiptDate <> 0D) and (ExpectedReceiptDate >= Today)) or
             ((PromisedReceiptDate <> 0D) and (PromisedReceiptDate >= Today)));
    end;

    local procedure TryGetBaseDeliveryFormula(ItemNo: Code[20]; Availability: Decimal; var DeliveryFormula: DateFormula): Boolean
    var
        Item: Record Item;
    begin
        if Availability > 0 then
            exit(TryGetSetupDeliveryFormula(StockSetupCategoryLbl, DeliveryFormula));

        if not IsReplenishable(ItemNo) then
            exit(false);

        if Item.Get(ItemNo) and (Format(Item."CXB Additional Delivery Time") <> '') then begin
            DeliveryFormula := Item."CXB Additional Delivery Time";
            exit(true);
        end;

        exit(TryGetSetupDeliveryFormula(DemandSetupCategoryLbl, DeliveryFormula));
    end;

    local procedure ApplyCountryDeliveryTime(var DeliveryDate: Date; CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegionCode = '' then
            exit;

        if not CountryRegion.Get(CountryRegionCode) then
            exit;

        ApplyDeliveryFormula(DeliveryDate, CountryRegion."CXB Additional Delivery Time");
    end;

    local procedure ApplyWarehouseDeliveryTime(var DeliveryDate: Date; ZoneCode: Code[10]; BinCode: Code[20])
    var
        Bin: Record Bin;
        Zone: Record Zone;
    begin
        if BinCode <> '' then begin
            Bin.SetRange("Location Code", GetAvailabilityLocationCode());
            Bin.SetRange(Code, BinCode);
            if Bin.FindFirst() then begin
                ApplyDeliveryFormula(DeliveryDate, Bin."CXB Additional Delivery Time");
                exit;
            end;
        end;

        if ZoneCode = '' then
            exit;

        Zone.SetRange("Location Code", GetAvailabilityLocationCode());
        Zone.SetRange(Code, ZoneCode);
        if Zone.FindFirst() then
            ApplyDeliveryFormula(DeliveryDate, Zone."CXB Additional Delivery Time");
    end;

    local procedure ApplyDeliveryFormula(var DeliveryDate: Date; DeliveryFormula: DateFormula)
    begin
        if Format(DeliveryFormula) = '' then
            exit;

        DeliveryDate := CalcDate(DeliveryFormula, DeliveryDate);
    end;

    local procedure TryGetSetupDeliveryFormula(CategoryCode: Text; var DeliveryFormula: DateFormula): Boolean
    var
        FormulaText: Text;
    begin
        if not TryLoadSetupValue(CategoryCode, FormulaText) then
            exit(false);

        if FormulaText = '' then
            exit(false);

        exit(Evaluate(DeliveryFormula, FormulaText));
    end;

    local procedure IsReplenishable(ItemNo: Code[20]): Boolean
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttribute.SetRange(Name, ReplenishmentAttributeNameLbl);
        if not ItemAttribute.FindFirst() then
            exit(false);

        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.SetRange(Value, ReplenishmentYesValueLbl);
        if not ItemAttributeValue.FindFirst() then
            exit(false);

        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", ItemNo);
        ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttribute.ID);
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", ItemAttributeValue.ID);

        exit(ItemAttributeValueMapping.FindFirst());
    end;

    local procedure GetAvailabilityLocationCode(): Code[10]
    begin
        if CachedAvailabilityLocationCode = '' then begin
            if not TryLoadAvailabilityLocationCode(CachedAvailabilityLocationCode) then
                CachedAvailabilityLocationCode := '';

            if CachedAvailabilityLocationCode = '' then
                CachedAvailabilityLocationCode := 'HL';
        end;

        exit(CachedAvailabilityLocationCode);
    end;

    [TryFunction]
    local procedure TryLoadAvailabilityLocationCode(var LocationCode: Code[10])
    var
        SetupValue: Text;
    begin
        if not TryLoadSetupValue(WebshopSetupCategoryLbl, SetupValue) then
            exit;

        LocationCode := CopyStr(SetupValue, 1, MaxStrLen(LocationCode));
    end;

    [TryFunction]
    local procedure TryLoadSetupValue(CategoryCode: Text; var SetupValue: Text)
    var
        SetupValuesRef: RecordRef;
        ValueFieldRef: FieldRef;
    begin
        SetupValuesRef.Open(50116);
        ApplySetupValueFilter(SetupValuesRef, 'Setup Code', 'AVAILIBILITY');
        ApplySetupValueFilter(SetupValuesRef, 'Category Code', CategoryCode);

        if not SetupValuesRef.FindFirst() then
            exit;

        ValueFieldRef := GetFieldRefByName(SetupValuesRef, 'Value');
        SetupValue := Format(ValueFieldRef.Value);
    end;

    local procedure ApplySetupValueFilter(var SetupValuesRef: RecordRef; FieldName: Text; FilterValue: Text)
    var
        SetupFieldRef: FieldRef;
    begin
        SetupFieldRef := GetFieldRefByName(SetupValuesRef, FieldName);
        SetupFieldRef.SetRange(FilterValue);
    end;

    local procedure GetFieldRefByName(var SourceRecordRef: RecordRef; SearchFieldName: Text): FieldRef
    var
        FieldMetadata: Record Field;
    begin
        FieldMetadata.SetRange(TableNo, SourceRecordRef.Number);
        FieldMetadata.SetRange(FieldName, SearchFieldName);
        FieldMetadata.FindFirst();

        exit(SourceRecordRef.Field(FieldMetadata."No."));
    end;

    var
        CachedAvailabilityLocationCode: Code[10];
        ReplenishmentAttributeNameLbl: Label 'Wiederbeschaffbarkeit', Locked = true;
        ReplenishmentYesValueLbl: Label 'ja', Locked = true;
        TransferLocationCodeLbl: Label 'W', Locked = true;
        WebshopSetupCategoryLbl: Label 'WEBSHOP', Locked = true;
        StockSetupCategoryLbl: Label 'STOCK', Locked = true;
        DemandSetupCategoryLbl: Label 'DEMAND', Locked = true;
}
