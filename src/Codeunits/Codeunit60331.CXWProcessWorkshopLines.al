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
        if WorkshopLine."CXW Genuine" then
            ProcessGenuineLine(WorkshopLine)
        else
            ProcessNonGenuineLine(WorkshopLine);
    end;

    local procedure ProcessGenuineLine(var WorkshopLine: Record "CXW Workshop Line")
    var
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
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

        for AttributeIndex := 1 to 10 do begin
            AttributeValue := GetWorkshopLineAttributeValue(WorkshopLine, AttributeIndex);
            if AttributeValue <> '' then
                SetItemAttributeValue(WorkshopLine."CXW Item No.", GetAttributeMapping(AttributeIndex), AttributeValue);
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

    local procedure GetWorkshopLineAttributeValue(WorkshopLine: Record "CXW Workshop Line"; AttributeIndex: Integer): Text[250]
    begin
        case AttributeIndex of
            1:
                exit(WorkshopLine."CXW Attribute 1");
            2:
                exit(WorkshopLine."CXW Attribute 2");
            3:
                exit(WorkshopLine."CXW Attribute 3");
            4:
                exit(WorkshopLine."CXW Attribute 4");
            5:
                exit(WorkshopLine."CXW Attribute 5");
            6:
                exit(WorkshopLine."CXW Attribute 6");
            7:
                exit(WorkshopLine."CXW Attribute 7");
            8:
                exit(WorkshopLine."CXW Attribute 8");
            9:
                exit(WorkshopLine."CXW Attribute 9");
            10:
                exit(WorkshopLine."CXW Attribute 10");
        end;
    end;

    // TODO: Finale Attributnamen einsetzen (Platzhalter!) - zentrale Zuordnung WL-Feld -> Item-Attribute-Name.
    local procedure GetAttributeMapping(AttributeIndex: Integer): Text[250]
    begin
        case AttributeIndex of
            1:
                exit('Attribut 1');
            2:
                exit('Attribut 2');
            3:
                exit('Attribut 3');
            4:
                exit('Attribut 4');
            5:
                exit('Attribut 5');
            6:
                exit('Attribut 6');
            7:
                exit('Attribut 7');
            8:
                exit('Attribut 8');
            9:
                exit('Attribut 9');
            10:
                exit('Attribut 10');
        end;
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
