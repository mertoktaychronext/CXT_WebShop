codeunit 60331 "CXW Process Workshop Lines"
{
    trigger OnRun()
    begin
        ProcessCheckedLines();
    end;

    local procedure ProcessCheckedLines()
    var
        WorkshopLine: Record "CXW Workshop Line";
    begin
        WorkshopLine.SetRange("CXW Status", WorkshopLine."CXW Status"::"WS checked");
        if WorkshopLine.FindSet() then
            repeat
                ProcessLineWithErrorHandling(WorkshopLine);
            until WorkshopLine.Next() = 0;
    end;

    local procedure ProcessLineWithErrorHandling(WorkshopLine: Record "CXW Workshop Line")
    begin
        if TryProcessLine(WorkshopLine) then
            Commit()
        else begin
            WorkshopLine.Get(WorkshopLine."CXW Document Type", WorkshopLine."CXW Document No.", WorkshopLine."CXW Line No.");
            WorkshopLine."CXW Last Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(WorkshopLine."CXW Last Error"));
            WorkshopLine."CXW Status" := WorkshopLine."CXW Status"::Error;
            WorkshopLine.Modify();
            Commit();
        end;
    end;

    [TryFunction]
    local procedure TryProcessLine(var WorkshopLine: Record "CXW Workshop Line")
    begin
        if WorkshopLine."CXW isAuthentic" then
            ProcessGenuineLine(WorkshopLine)
        else
            ProcessNonGenuineLine(WorkshopLine);
    end;

    local procedure ProcessGenuineLine(var WorkshopLine: Record "CXW Workshop Line")
    var
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        WorkshopLineMgt: Codeunit "CXW Workshop Line Mgt.";
        AttributeIndex: Integer;
        AttributeValue: Text[250];
    begin
        // Standardfall: eine Purchase Line = eine Purchase Order (siehe design.md, Non-Goals).
        PurchLine.Get(WorkshopLine."CXW Document Type", WorkshopLine."CXW Document No.", WorkshopLine."CXW Line No.");
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");

        PurchLine.Validate("Qty. to Receive", PurchLine.Quantity);
        PurchLine.Modify(true);

        PurchHeader.Receive := true;
        PurchHeader.Invoice := false;
        if not Codeunit.Run(Codeunit::"Purch.-Post", PurchHeader) then
            Error(GetLastErrorText());

        // Same mapping as the prefill in "CXW Workshop Line Mgt.". Values are written to the named attribute;
        // a value prefilled from the ChronextBC fallback and left unchanged by the workshop is skipped.
        for AttributeIndex := 1 to WorkshopLineMgt.WorkshopAttributeCount() do begin
            AttributeValue := WorkshopLineMgt.GetWorkshopAttributeValue(WorkshopLine, AttributeIndex);
            if (AttributeValue <> '') and
               not WorkshopLineMgt.IsUnchangedFallbackValue(WorkshopLine."CXW Item No.", AttributeIndex, AttributeValue)
            then
                SetItemAttributeValue(WorkshopLine."CXW Item No.", WorkshopLineMgt.GetWorkshopAttributeName(AttributeIndex), AttributeValue);
        end;

        WorkshopLine."CXW Last Error" := '';
        WorkshopLine."CXW Status" := WorkshopLine."CXW Status"::"Processed";
        WorkshopLine.Modify();
    end;

    local procedure ProcessNonGenuineLine(var WorkshopLine: Record "CXW Workshop Line")
    var
        PurchHeader: Record "Purchase Header";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        // Status zuerst auf Verarbeitet setzen, damit der Cascade-Delete-Schutz in
        // TabExt60321 "CXW Workshop Purchase Line" beim gleich folgenden PO-Löschen greift
        // und diese Workshop Line als Prüfnachweis stehen bleibt.
        WorkshopLine."CXW Last Error" := '';
        WorkshopLine."CXW Status" := WorkshopLine."CXW Status"::"Processed";
        WorkshopLine.Modify();

        // Standardfall: eine Purchase Line = eine Purchase Order, es ist noch nichts gebucht,
        // daher genügt das Löschen der gesamten PO.
        // TODO: Verhalten für gemischte POs (mehrere PLs, teils echt/teils nicht echt) klären
        // — aktuell nur Standardfall eine PL = eine PO implementiert.
        PurchHeader.Get(WorkshopLine."CXW Document Type", WorkshopLine."CXW Document No.");
        if PurchHeader.Status <> PurchHeader.Status::Open then
            ReleasePurchDoc.PerformManualReopen(PurchHeader);
        PurchHeader.Delete(true);
    end;

    local procedure SetItemAttributeValue(ItemNo: Code[20]; AttributeName: Text[250]; Value: Text[250])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        AttributeId: Integer;
        ValueId: Integer;
    begin
        AttributeId := GetOrCreateAttributeId(AttributeName);
        ValueId := GetOrCreateAttributeValueId(AttributeId, Value);

        if ItemAttributeValueMapping.Get(Database::Item, ItemNo, AttributeId) then begin
            ItemAttributeValueMapping."Item Attribute Value ID" := ValueId;
            ItemAttributeValueMapping.Modify();
        end else begin
            ItemAttributeValueMapping.Init();
            ItemAttributeValueMapping."Table ID" := Database::Item;
            ItemAttributeValueMapping."No." := ItemNo;
            ItemAttributeValueMapping."Item Attribute ID" := AttributeId;
            ItemAttributeValueMapping."Item Attribute Value ID" := ValueId;
            ItemAttributeValueMapping.Insert();
        end;
    end;

    local procedure GetOrCreateAttributeId(AttributeName: Text[250]): Integer
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.SetRange(Name, AttributeName);
        if ItemAttribute.FindFirst() then
            exit(ItemAttribute.ID);

        ItemAttribute.Init();
        ItemAttribute.Validate(Name, AttributeName);
        ItemAttribute.Type := ItemAttribute.Type::Text;
        ItemAttribute.Insert(true);
        exit(ItemAttribute.ID);
    end;

    local procedure GetOrCreateAttributeValueId(AttributeId: Integer; Value: Text[250]): Integer
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValue.SetRange("Attribute ID", AttributeId);
        ItemAttributeValue.SetRange(Value, Value);
        if ItemAttributeValue.FindFirst() then
            exit(ItemAttributeValue.ID);

        ItemAttributeValue.Init();
        ItemAttributeValue."Attribute ID" := AttributeId;
        ItemAttributeValue.Validate(Value, Value);
        ItemAttributeValue.Insert(true);
        exit(ItemAttributeValue.ID);
    end;
}
