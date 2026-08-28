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

        QueueAvailabilityChange(Rec."Item No.", Rec."Variant Code", Rec."Location Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySalesLine(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if Rec."No." = '' then
            exit;

        if not IsRelevantSalesLine(Rec) then
            exit;

        QueueAvailabilityChange(Rec."No.", Rec."Variant Code", Rec."Location Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if not IsRelevantSalesLine(Rec) then
            exit;

        QueueAvailabilityChange(Rec."No.", Rec."Variant Code", Rec."Location Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteReservationEntry(var Rec: Record "Reservation Entry"; RunTrigger: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        if not TryGetRelevantSalesOrderLineFromReservation(Rec, SalesLine) then
            exit;

        QueueAvailabilityChange(SalesLine."No.", SalesLine."Variant Code", SalesLine."Location Code");
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

    local procedure TryGetRelevantSalesOrderLineFromReservation(ReservationEntry: Record "Reservation Entry"; var SalesLine: Record "Sales Line"): Boolean
    begin
        if ReservationEntry.IsTemporary() then
            exit(false);

        if ReservationEntry."Source Type" <> Database::"Sales Line" then
            exit(false);

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", ReservationEntry."Source ID");
        SalesLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        if not SalesLine.FindFirst() then
            exit(false);

        if not IsRelevantSalesLine(SalesLine) then
            exit(false);

        // Reservation deletions caused by posting should not enqueue exports.
        if SalesLine."Outstanding Quantity" = 0 then
            exit(false);

        exit(true);
    end;

    local procedure QueueAvailabilityChange(ItemNo: Code[20]; VariantCode: Code[20]; LocationCode: Code[10])
    var
        AvailabilityChangeEntry: Record "CXW Availability Change Entry";
    begin
        AvailabilityChangeEntry.SetRange("CXW Item No.", ItemNo);
        AvailabilityChangeEntry.SetRange("CXW Variant Code", VariantCode);
        AvailabilityChangeEntry.SetRange("CXW Location Code", LocationCode);
        AvailabilityChangeEntry.SetRange("CXW Exported", false);
        if AvailabilityChangeEntry.FindFirst() then
            exit;

        AvailabilityChangeEntry.Init();
        AvailabilityChangeEntry."CXW Item No." := ItemNo;
        AvailabilityChangeEntry."CXW Variant Code" := VariantCode;
        AvailabilityChangeEntry."CXW Location Code" := LocationCode;
        AvailabilityChangeEntry."CXW Inserted At" := CurrentDateTime;
        AvailabilityChangeEntry.Insert();
    end;

    local procedure IsAvailabilityLocation(LocationCode: Code[10]): Boolean
    begin
        exit(LocationCode = GetAvailabilityLocationCode());
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
        SetupValuesRef: RecordRef;
        ValueFieldRef: FieldRef;
    begin
        SetupValuesRef.Open(50116);
        ApplySetupValueFilter(SetupValuesRef, 'Setup Code', 'AVAILIBILITY');
        ApplySetupValueFilter(SetupValuesRef, 'Category Code', 'WEBSHOP');

        if not SetupValuesRef.FindFirst() then
            exit;

        ValueFieldRef := GetFieldRefByName(SetupValuesRef, 'Value');
        LocationCode := CopyStr(Format(ValueFieldRef.Value), 1, MaxStrLen(LocationCode));
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
        CachedAvailabilityLocationCode: Code[10];
}
