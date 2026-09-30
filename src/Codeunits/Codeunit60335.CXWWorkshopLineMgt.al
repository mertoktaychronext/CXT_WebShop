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

    // Prefills the attribute fields the workshop reports back with the item's current values;
    // the workshop may correct them before they are written back on processing.
    procedure PrefillEmptyWorkshopAttributes(var WorkshopLine: Record "CXW Workshop Line")
    begin
        FillEmptyWorkshopAttributes(WorkshopLine, WorkshopLine."CXW Item No.");
    end;

    procedure WorkshopAttributeCount(): Integer
    begin
        exit(10);
    end;

    // Single mapping workshop line field -> item attribute name, used for prefilling and for writing back.
    // TODO: Attributnamen für Attribut 9/10 final klären (Platzhalter!)
    procedure GetWorkshopAttributeName(AttributeIndex: Integer): Text[250]
    begin
        case AttributeIndex of
            1:
                exit('Dial Color');
            2:
                exit('Case Diameter');
            3:
                exit('Bracelet Material');
            4:
                exit('Case Material');
            5:
                exit('Movement');
            6:
                exit('Gender');
            7:
                exit('Crystal');
            8:
                exit('Features');
            9:
                exit('Attribut 9');
            10:
                exit('Attribut 10');
        end;
    end;

    // Fallback for the prefill only: ChronextBC attribute (ID = field no. in "Item Attribute Collection")
    // used when the item has no value for the attribute above; 0 = no fallback.
    local procedure GetWorkshopAttributeFallbackId(AttributeIndex: Integer): Integer
    begin
        case AttributeIndex of
            1:
                exit(22); // Zifferblatt Farbe 1
            2:
                exit(18); // Gehäuse Größe
            3:
                exit(23); // Armband Material
            4:
                exit(16); // Gehäuse Material
            5:
                exit(15); // Werk
            6:
                exit(24); // Geschlecht
            7:
                exit(20); // Glas
        end;
        exit(0);
    end;

    procedure GetWorkshopAttributeValue(WorkshopLine: Record "CXW Workshop Line"; AttributeIndex: Integer): Text[250]
    begin
        case AttributeIndex of
            1:
                exit(WorkshopLine."CXW Dial Color");
            2:
                exit(WorkshopLine."CXW Case Diameter");
            3:
                exit(WorkshopLine."CXW Bracelet Material");
            4:
                exit(WorkshopLine."CXW Case Material");
            5:
                exit(WorkshopLine."CXW Movement");
            6:
                exit(WorkshopLine."CXW Gender");
            7:
                exit(WorkshopLine."CXW Crystal");
            8:
                exit(WorkshopLine."CXW Features");
            9:
                exit(WorkshopLine."CXW Attribute 9");
            10:
                exit(WorkshopLine."CXW Attribute 10");
        end;
    end;

    procedure SetWorkshopAttributeValue(var WorkshopLine: Record "CXW Workshop Line"; AttributeIndex: Integer; Value: Text[250])
    begin
        case AttributeIndex of
            1:
                WorkshopLine."CXW Dial Color" := Value;
            2:
                WorkshopLine."CXW Case Diameter" := Value;
            3:
                WorkshopLine."CXW Bracelet Material" := Value;
            4:
                WorkshopLine."CXW Case Material" := Value;
            5:
                WorkshopLine."CXW Movement" := Value;
            6:
                WorkshopLine."CXW Gender" := Value;
            7:
                WorkshopLine."CXW Crystal" := Value;
            8:
                WorkshopLine."CXW Features" := Value;
            9:
                WorkshopLine."CXW Attribute 9" := Value;
            10:
                WorkshopLine."CXW Attribute 10" := Value;
        end;
    end;

    // True if the value was prefilled from the ChronextBC fallback and the workshop left it unchanged:
    // the named attribute has no value on the item and the value equals the fallback attribute value.
    // Such values are not written back, so the named attribute is not filled with the fallback text.
    procedure IsUnchangedFallbackValue(pItemNo: Code[20]; AttributeIndex: Integer; Value: Text[250]): Boolean
    var
        AttributeId: Integer;
    begin
        if GetWorkshopAttributeFallbackId(AttributeIndex) = 0 then
            exit(false);
        AttributeId := FindItemAttributeId(GetWorkshopAttributeName(AttributeIndex));
        if AttributeId <> 0 then
            if GetItemAttributeValue(pItemNo, AttributeId) <> '' then
                exit(false);
        exit(Value = GetItemAttributeValue(pItemNo, GetWorkshopAttributeFallbackId(AttributeIndex)));
    end;

    // Fills only empty fields, so values the workshop already reported are never overwritten.
    local procedure FillEmptyWorkshopAttributes(var WorkshopLine: Record "CXW Workshop Line"; pItemNo: Code[20])
    var
        AttributeIndex: Integer;
        AttributeId: Integer;
        AttributeValue: Text[250];
    begin
        for AttributeIndex := 1 to WorkshopAttributeCount() do
            if GetWorkshopAttributeValue(WorkshopLine, AttributeIndex) = '' then begin
                // A missing attribute leaves the field empty; attributes are only created when writing back.
                AttributeValue := '';
                AttributeId := FindItemAttributeId(GetWorkshopAttributeName(AttributeIndex));
                if AttributeId <> 0 then
                    AttributeValue := GetItemAttributeValue(pItemNo, AttributeId);
                if (AttributeValue = '') and (GetWorkshopAttributeFallbackId(AttributeIndex) <> 0) then
                    AttributeValue := GetItemAttributeValue(pItemNo, GetWorkshopAttributeFallbackId(AttributeIndex));
                SetWorkshopAttributeValue(WorkshopLine, AttributeIndex, AttributeValue);
            end;
    end;

    local procedure FindItemAttributeId(pAttributeName: Text[250]): Integer
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.SetLoadFields(ID, Name);
        ItemAttribute.SetRange(Name, pAttributeName);
        if ItemAttribute.FindFirst() then
            exit(ItemAttribute.ID);
        exit(0);
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
