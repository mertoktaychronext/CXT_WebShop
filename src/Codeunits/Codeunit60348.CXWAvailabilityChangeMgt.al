codeunit 60348 "CXW Availability Change Mgt"
{
    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertItemLedgerEntry(var Rec: Record "Item Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if (Rec."Item No." = '') or (Rec."Location Code" = '') then
            exit;

        if not IsAvailabilityLocation(Rec."Location Code") then
            exit;

        QueueItemLedgerEntryChange(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySalesLine(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if Rec."No." = '' then
            exit;

        if not IsRelevantSalesLine(Rec) then
            exit;

        QueueAvailabilityChange(Rec."No.", Rec."Variant Code", Rec."Location Code", 0, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if not IsRelevantSalesLine(Rec) then
            exit;

        QueueAvailabilityChange(Rec."No.", Rec."Variant Code", Rec."Location Code", 0, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertTransferLine(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        QueueTransferLineChange(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyTransferLine(var Rec: Record "Transfer Line"; var xRec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        QueueTransferLineChange(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteTransferLine(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        QueueTransferLineChange(Rec);
    end;

    local procedure IsRelevantSalesLine(SalesLine: Record "Sales Line"): Boolean
    begin
        if SalesLine.IsTemporary() then
            exit(false);

        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            exit(false);

        if SalesLine.Type <> SalesLine.Type::Item then
            exit(false);

        if (SalesLine."No." = '') or (SalesLine."Location Code" = '') then
            exit(false);

        exit(IsAvailabilityLocation(SalesLine."Location Code"));
    end;

    local procedure QueueItemLedgerEntryChange(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        QueueAvailabilityChange(
            ItemLedgerEntry."Item No.", ItemLedgerEntry."Variant Code", ItemLedgerEntry."Location Code",
            ItemLedgerEntry."Entry No.", ItemLedgerEntry."CXB Margin Taxation");
    end;

    local procedure QueueTransferLineChange(TransferLine: Record "Transfer Line")
    begin
        if TransferLine.IsTemporary() then
            exit;
        if TransferLine."Item No." = '' then
            exit;

        if IsAvailabilityLocation(TransferLine."Transfer-from Code") then
            QueueAvailabilityChange(TransferLine."Item No.", TransferLine."Variant Code", TransferLine."Transfer-from Code", 0, false)
        else
            if IsAvailabilityLocation(TransferLine."Transfer-to Code") then
                QueueAvailabilityChange(TransferLine."Item No.", TransferLine."Variant Code", TransferLine."Transfer-to Code", 0, false);
    end;

    local procedure QueueAvailabilityChange(ItemNo: Code[20]; VariantCode: Code[20]; LocationCode: Code[10]; ItemLedgerEntryNo: Integer; DifferentialTaxationPurchase: Boolean)
    var
        AvailabilityChangeEntry: Record "CXW Availability Change Entry";
    begin
        AvailabilityChangeEntry.SetRange("CXW Item No.", ItemNo);
        AvailabilityChangeEntry.SetRange("CXW Variant Code", VariantCode);
        AvailabilityChangeEntry.SetRange("CXW Location Code", LocationCode);
        AvailabilityChangeEntry.SetRange("CXW Item Ledger Entry No.", ItemLedgerEntryNo);
        AvailabilityChangeEntry.SetRange("CXW Differential Taxation Purchase", DifferentialTaxationPurchase);
        AvailabilityChangeEntry.SetRange("CXW Exported", false);
        if AvailabilityChangeEntry.FindFirst() then begin
            AvailabilityChangeEntry.Modify(true);
            RefreshAvailabilityChangeDetails(AvailabilityChangeEntry);
            exit;
        end;

        // A sales or transfer line can already have created an aggregate open queue entry before
        // its reservation is linked to an item ledger entry. Promote that entry to the detailed
        // item-ledger-entry message instead of sending both representations.
        if ItemLedgerEntryNo <> 0 then begin
            AvailabilityChangeEntry.SetRange("CXW Item Ledger Entry No.", 0);
            if AvailabilityChangeEntry.FindFirst() then begin
                AvailabilityChangeEntry."CXW Item Ledger Entry No." := ItemLedgerEntryNo;
                AvailabilityChangeEntry.Modify(true);
                RefreshAvailabilityChangeDetails(AvailabilityChangeEntry);
                exit;
            end;
        end;

        AvailabilityChangeEntry.Init();
        AvailabilityChangeEntry."CXW Item No." := ItemNo;
        AvailabilityChangeEntry."CXW Variant Code" := VariantCode;
        AvailabilityChangeEntry."CXW Location Code" := LocationCode;
        AvailabilityChangeEntry."CXW Item Ledger Entry No." := ItemLedgerEntryNo;
        AvailabilityChangeEntry."CXW Differential Taxation Purchase" := DifferentialTaxationPurchase;
        AvailabilityChangeEntry.Insert();
        RefreshAvailabilityChangeDetails(AvailabilityChangeEntry);
    end;

    procedure PrepareItemForExport(ItemNo: Code[20])
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.SetRange("Item No.", ItemNo);
        if ItemVariant.FindSet() then
            repeat
                PrepareItemVariantForExport(ItemNo, ItemVariant.Code);
            until ItemVariant.Next() = 0
        else
            PrepareItemVariantForExport(ItemNo, '');

        // The direct export from the item card is a complete snapshot. Re-export the
        // calculated time records even if their calculated value has not changed.
        MarkTimeRecordsForExport(ItemNo);
    end;

    local procedure MarkTimeRecordsForExport(ItemNo: Code[20])
    var
        AvailabilityDeliveryTime: Record "CXW Availability Delivery Time";
        AvailabilityInventoryTime: Record "CXW Availability Inv. Time";
    begin
        AvailabilityDeliveryTime.SetRange("CXW Item No.", ItemNo);
        AvailabilityDeliveryTime.ModifyAll("CXW Exported", false);
        AvailabilityDeliveryTime.ModifyAll("CXW Exported At", 0DT);

        AvailabilityInventoryTime.SetRange("CXW Item No.", ItemNo);
        AvailabilityInventoryTime.ModifyAll("CXW Exported", false);
        AvailabilityInventoryTime.ModifyAll("CXW Exported At", 0DT);
    end;

    local procedure PrepareItemVariantForExport(ItemNo: Code[20]; VariantCode: Code[20])
    var
        AvailabilityLocationCode: Code[10];
    begin
        AvailabilityLocationCode := GetFirstAvailabilityLocationCode();
        QueueAvailabilityChange(ItemNo, VariantCode, AvailabilityLocationCode, 0, false);
        QueueAvailabilityChange(ItemNo, VariantCode, AvailabilityLocationCode, 0, true);
        RefreshDeliveryTimes(ItemNo, VariantCode);
    end;

    procedure RefreshAvailabilityChangeDetails(var AvailabilityChangeEntry: Record "CXW Availability Change Entry")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if AvailabilityChangeEntry."CXW Item Ledger Entry No." <> 0 then begin
            Clear(AvailabilityChangeEntry."CXW Differential Taxation Purchase");

            if ItemLedgerEntry.Get(AvailabilityChangeEntry."CXW Item Ledger Entry No.") then
                AvailabilityChangeEntry."CXW Differential Taxation Purchase" := ItemLedgerEntry."CXB Margin Taxation";
        end;

        AvailabilityChangeEntry."CXW Inventory Quantity" := GetAvailableInventoryQuantity(
            AvailabilityChangeEntry."CXW Item No.",
            AvailabilityChangeEntry."CXW Variant Code",
            AvailabilityChangeEntry."CXW Location Code",
            AvailabilityChangeEntry."CXW Differential Taxation Purchase");

        AvailabilityChangeEntry."CXW Changed At" := CurrentDateTime;
        AvailabilityChangeEntry.Modify(true);
    end;

    local procedure GetAvailableInventoryQuantity(ItemNo: Code[20]; VariantCode: Code[20]; LocationCode: Code[10]; DifferentialTaxationPurchase: Boolean): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        AvailableQuantity: Decimal;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.SetFilter("Location Code", GetAvailabilityLocationFilter());
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange("CXB Margin Taxation", DifferentialTaxationPurchase);
        if ItemLedgerEntry.FindSet() then
            repeat begin
                ItemLedgerEntry.CalcFields("Reserved Quantity");
                AvailableQuantity += ItemLedgerEntry."Remaining Quantity" - Abs(ItemLedgerEntry."Reserved Quantity");
            end;
            until ItemLedgerEntry.Next() = 0;

        if AvailableQuantity < 0 then
            exit(0);

        exit(AvailableQuantity);
    end;

    procedure RefreshDeliveryTimes(ItemNo: Code[20]; VariantCode: Code[20])
    var
        AvailabilityCalculation: Codeunit "CXW Availability Calculation";
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.SetRange("CXW Webshop Delivery Time Active", true);
        if not CountryRegion.FindSet() then
            exit;

        repeat
            RefreshDeliveryTimeForCountry(ItemNo, GetDeliveryTimeVariantCode(ItemNo, VariantCode), CountryRegion.Code, AvailabilityCalculation);
            RefreshInventoryTimesForCountry(ItemNo, GetDeliveryTimeVariantCode(ItemNo, VariantCode), CountryRegion.Code, AvailabilityCalculation);
        until CountryRegion.Next() = 0;
    end;

    procedure RefreshDeliveryTimesForCountry(CountryRegionCode: Code[10])
    var
        AvailabilityCalculation: Codeunit "CXW Availability Calculation";
        CountryRegion: Record "Country/Region";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if not CountryRegion.Get(CountryRegionCode) then
            exit;
        if not CountryRegion."CXW Webshop Delivery Time Active" then
            exit;

        if not Item.FindSet() then
            exit;

        repeat
            ItemVariant.SetRange("Item No.", Item."No.");
            if ItemVariant.FindSet() then
                repeat
                    RefreshDeliveryTimeForCountry(Item."No.", ItemVariant.Code, CountryRegion.Code, AvailabilityCalculation);
                    RefreshInventoryTimesForCountry(Item."No.", ItemVariant.Code, CountryRegion.Code, AvailabilityCalculation);
                until ItemVariant.Next() = 0
            else begin
                RefreshDeliveryTimeForCountry(Item."No.", Item."No.", CountryRegion.Code, AvailabilityCalculation);
                RefreshInventoryTimesForCountry(Item."No.", Item."No.", CountryRegion.Code, AvailabilityCalculation);
            end;
        until Item.Next() = 0;
    end;

    procedure RefreshDeliveryTimesForActiveCountries()
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.SetRange("CXW Webshop Delivery Time Active", true);
        if not CountryRegion.FindSet() then
            exit;

        repeat
            RefreshDeliveryTimesForCountry(CountryRegion.Code);
        until CountryRegion.Next() = 0;
    end;

    local procedure RefreshDeliveryTimeForCountry(ItemNo: Code[20]; VariantCode: Code[20]; CountryRegionCode: Code[10]; AvailabilityCalculation: Codeunit "CXW Availability Calculation")
    var
        DeliveryDays: Integer;
    begin
        if AvailabilityCalculation.TryGetArticleDeliveryDays(ItemNo, CountryRegionCode, '', '', DeliveryDays) then
            UpsertDeliveryTime(ItemNo, VariantCode, CountryRegionCode, DeliveryDays)
        else
            UpsertDeliveryTime(ItemNo, VariantCode, CountryRegionCode, -1);
    end;

    local procedure GetDeliveryTimeVariantCode(ItemNo: Code[20]; VariantCode: Code[20]): Code[20]
    var
        ItemVariant: Record "Item Variant";
    begin
        if VariantCode <> '' then
            exit(VariantCode);

        ItemVariant.SetRange("Item No.", ItemNo);
        if not ItemVariant.FindFirst() then
            exit(ItemNo);

        exit('');
    end;

    local procedure RefreshInventoryTimesForCountry(ItemNo: Code[20]; VariantCode: Code[20]; CountryRegionCode: Code[10]; AvailabilityCalculation: Codeunit "CXW Availability Calculation")
    var
        DeliveryDays: Integer;
    begin
        if AvailabilityCalculation.TryGetStockDeliveryDays(ItemNo, CountryRegionCode, DeliveryDays) then
            UpsertInventoryTime(ItemNo, VariantCode, CountryRegionCode, InventoryTimeStockTypeLbl, DeliveryDays)
        else
            UpsertInventoryTime(ItemNo, VariantCode, CountryRegionCode, InventoryTimeStockTypeLbl, 0);

        if AvailabilityCalculation.TryGetNonStockDeliveryDays(ItemNo, CountryRegionCode, DeliveryDays) then
            UpsertInventoryTime(ItemNo, VariantCode, CountryRegionCode, InventoryTimeNonStockTypeLbl, DeliveryDays)
        else
            UpsertInventoryTime(ItemNo, VariantCode, CountryRegionCode, InventoryTimeNonStockTypeLbl, 0);
    end;

    local procedure UpsertInventoryTime(ItemNo: Code[20]; VariantCode: Code[20]; CountryRegionCode: Code[10]; InventoryType: Code[10]; DeliveryDays: Integer)
    var
        AvailabilityInventoryTime: Record "CXW Availability Inv. Time";
    begin
        if AvailabilityInventoryTime.Get(ItemNo, VariantCode, CountryRegionCode, InventoryType) then begin
            if AvailabilityInventoryTime."CXW Delivery Days" = DeliveryDays then
                exit;

            AvailabilityInventoryTime."CXW Delivery Days" := DeliveryDays;
            AvailabilityInventoryTime."CXW Exported" := false;
            Clear(AvailabilityInventoryTime."CXW Exported At");
            AvailabilityInventoryTime.Modify(true);
            exit;
        end;

        AvailabilityInventoryTime.Init();
        AvailabilityInventoryTime."CXW Item No." := ItemNo;
        AvailabilityInventoryTime."CXW Variant Code" := VariantCode;
        AvailabilityInventoryTime."CXW Country/Region Code" := CountryRegionCode;
        AvailabilityInventoryTime."CXW Inventory Type" := InventoryType;
        AvailabilityInventoryTime."CXW Delivery Days" := DeliveryDays;
        AvailabilityInventoryTime.Insert(true);
    end;

    local procedure UpsertDeliveryTime(ItemNo: Code[20]; VariantCode: Code[20]; CountryRegionCode: Code[10]; DeliveryDays: Integer)
    var
        AvailabilityDeliveryTime: Record "CXW Availability Delivery Time";
    begin
        if AvailabilityDeliveryTime.Get(ItemNo, VariantCode, CountryRegionCode) then begin
            if AvailabilityDeliveryTime."CXW Delivery Days" = DeliveryDays then
                exit;

            AvailabilityDeliveryTime."CXW Delivery Days" := DeliveryDays;
            AvailabilityDeliveryTime."CXW Exported" := false;
            Clear(AvailabilityDeliveryTime."CXW Exported At");
            AvailabilityDeliveryTime.Modify(true);
            exit;
        end;

        AvailabilityDeliveryTime.Init();
        AvailabilityDeliveryTime."CXW Item No." := ItemNo;
        AvailabilityDeliveryTime."CXW Variant Code" := VariantCode;
        AvailabilityDeliveryTime."CXW Country/Region Code" := CountryRegionCode;
        AvailabilityDeliveryTime."CXW Delivery Days" := DeliveryDays;
        AvailabilityDeliveryTime.Insert(true);
    end;

    local procedure IsAvailabilityLocation(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        Location.SetFilter(Code, GetAvailabilityLocationFilter());
        if Location.FindSet() then
            repeat
                if Location.Code = LocationCode then
                    exit(true);
            until Location.Next() = 0;

        exit(false);
    end;

    local procedure GetFirstAvailabilityLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetFilter(Code, GetAvailabilityLocationFilter());
        if Location.FindFirst() then
            exit(Location.Code);

        exit('HL');
    end;

    local procedure GetAvailabilityLocationFilter(): Text
    begin
        if CachedAvailabilityLocationFilter = '' then begin
            if not TryLoadAvailabilityLocationFilter(CachedAvailabilityLocationFilter) then
                CachedAvailabilityLocationFilter := '';

            if CachedAvailabilityLocationFilter = '' then
                CachedAvailabilityLocationFilter := 'HL';
        end;

        exit(CachedAvailabilityLocationFilter);
    end;

    [TryFunction]
    local procedure TryLoadAvailabilityLocationFilter(var LocationFilter: Text)
    var
        SetupValuesRef: RecordRef;
        ValueFieldRef: FieldRef;
    begin
        SetupValuesRef.Open(50116);
        ApplySetupValueFilter(SetupValuesRef, 'Setup Code', 'AVAILIBILITY');
        ApplySetupValueFilter(SetupValuesRef, 'Category Code', 'WEBSHOP');

        if not SetupValuesRef.FindFirst() then
            exit;

        ValueFieldRef := GetFieldRefByName(SetupValuesRef, 'Value');
        LocationFilter := Format(ValueFieldRef.Value);
    end;

    local procedure ApplySetupValueFilter(var SetupValuesRef: RecordRef; FieldName: Text; FilterValue: Text)
    var
        SetupFieldRef: FieldRef;
    begin
        SetupFieldRef := GetFieldRefByName(SetupValuesRef, FieldName);
        SetupFieldRef.SetRange(FilterValue);
    end;

    local procedure GetFieldRefByName(var SourceRecordRef: RecordRef; FieldName: Text): FieldRef
    var
        FieldMetadata: Record Field;
    begin
        FieldMetadata.SetRange(TableNo, SourceRecordRef.Number);
        FieldMetadata.SetRange(FieldName, FieldName);
        FieldMetadata.FindFirst();

        exit(SourceRecordRef.Field(FieldMetadata."No."));
    end;

    var
        CachedAvailabilityLocationFilter: Text;
        InventoryTimeStockTypeLbl: Label 'stock', Locked = true;
        InventoryTimeNonStockTypeLbl: Label 'non-stock', Locked = true;
}
