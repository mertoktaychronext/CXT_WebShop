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

    // Takes the serial no. from the item tracking of the purchase line, used by the upgrade of existing lines;
    // "Send to Workshop" passes the serial no. it determined directly. Returns false if the line has none.
    procedure FillSerialNoFromPurchLine(var WorkshopLine: Record "CXW Workshop Line"; PurchLine: Record "Purchase Line"): Boolean
    var
        SerialNo: Code[50];
    begin
        SerialNo := FindPurchLineSerialNo(PurchLine);
        if SerialNo = '' then
            exit(false);
        WorkshopLine."CXW Serial No." := SerialNo;
        exit(true);
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

    // Single mapping workshop line field -> item attribute ID (= field no. in ChronextBC "Item Attribute Collection"),
    // used for prefilling and for writing back. 0 = placeholder without an attribute: neither prefilled nor written back;
    // assigning an ID here enables both.
    procedure GetWorkshopAttributeId(AttributeIndex: Integer): Integer
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
        // 8 Features, 9 Attribut 9, 10 Attribut 10: placeholders
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

    // Fills only empty fields, so values the workshop already reported are never overwritten.
    local procedure FillEmptyWorkshopAttributes(var WorkshopLine: Record "CXW Workshop Line"; pItemNo: Code[20])
    var
        AttributeIndex: Integer;
    begin
        for AttributeIndex := 1 to WorkshopAttributeCount() do
            if (GetWorkshopAttributeId(AttributeIndex) <> 0) and (GetWorkshopAttributeValue(WorkshopLine, AttributeIndex) = '') then
                SetWorkshopAttributeValue(WorkshopLine, AttributeIndex, GetItemAttributeValue(pItemNo, GetWorkshopAttributeId(AttributeIndex)));
    end;

    // Assigns a value to an existing item attribute of the item, used by the SellWatch item creation and the
    // workshop write-back. A value not yet in the attribute's value list is created; the attribute itself is never
    // created. Validating the value lets the standard reject non-numeric values for integer/decimal attributes.
    internal procedure SetItemAttributeValue(pItemNo: Code[20]; pAttributeId: Integer; pValue: Text[250])
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ValueId: Integer;
    begin
        ItemAttribute.Get(pAttributeId);
        ValueId := GetOrCreateAttributeValueId(pAttributeId, pValue);

        if ItemAttributeValueMapping.Get(Database::Item, pItemNo, pAttributeId) then begin
            if ItemAttributeValueMapping."Item Attribute Value ID" = ValueId then
                exit;
            ItemAttributeValueMapping."Item Attribute Value ID" := ValueId;
            ItemAttributeValueMapping.Modify();
        end else begin
            ItemAttributeValueMapping.Init();
            ItemAttributeValueMapping."Table ID" := Database::Item;
            ItemAttributeValueMapping."No." := pItemNo;
            ItemAttributeValueMapping."Item Attribute ID" := pAttributeId;
            ItemAttributeValueMapping."Item Attribute Value ID" := ValueId;
            ItemAttributeValueMapping.Insert();
        end;
    end;

    local procedure GetOrCreateAttributeValueId(pAttributeId: Integer; pValue: Text[250]): Integer
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValue.SetRange("Attribute ID", pAttributeId);
        ItemAttributeValue.SetRange(Value, pValue);
        if ItemAttributeValue.FindFirst() then
            exit(ItemAttributeValue.ID);

        ItemAttributeValue.Init();
        ItemAttributeValue."Attribute ID" := pAttributeId;
        ItemAttributeValue.Validate(Value, pValue);
        ItemAttributeValue.Insert(true);
        exit(ItemAttributeValue.ID);
    end;

    // Serial number handling for "Send to Workshop": the watch is identified by its BC serial number,
    // the manufacturer serial number is maintained on the Serial No. Information card (CHX.Base).
    internal procedure IsSerialNoTracked(pItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.SetLoadFields("Item Tracking Code");
        if not Item.Get(pItemNo) then
            exit(false);
        if Item."Item Tracking Code" = '' then
            exit(false);
        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            exit(false);
        exit(ItemTrackingCode."SN Purchase Inbound Tracking");
    end;

    internal procedure FindPurchLineSerialNo(PurchLine: Record "Purchase Line"): Code[50]
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", Database::"Purchase Line");
        ReservationEntry.SetRange("Source Subtype", PurchLine."Document Type".AsInteger());
        ReservationEntry.SetRange("Source ID", PurchLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", PurchLine."Line No.");
        ReservationEntry.SetFilter("Serial No.", '<>%1', '');
        ReservationEntry.SetLoadFields("Serial No.");
        if ReservationEntry.FindFirst() then
            exit(ReservationEntry."Serial No.");
        exit('');
    end;

    // Draws the next number from the item's serial no. series and assigns it as item tracking
    // (quantity 1) to the purchase line, so the later receipt (Codeunit 60331) can be posted.
    // Returns '' if the item has no serial no. series.
    internal procedure AssignNextSerialNo(PurchLine: Record "Purchase Line"): Code[50]
    var
        Item: Record Item;
        ForReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[50];
    begin
        Item.SetLoadFields("Serial Nos.");
        Item.Get(PurchLine."No.");
        if Item."Serial Nos." = '' then
            exit('');

        SerialNo := NoSeries.GetNextNo(Item."Serial Nos.");
        ForReservEntry."Serial No." := SerialNo;
        CreateReservEntry.CreateReservEntryFor(
            Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", '', 0, PurchLine."Line No.",
            PurchLine."Qty. per Unit of Measure", PurchLine.Quantity, PurchLine."Quantity (Base)", ForReservEntry);
        CreateReservEntry.CreateEntry(
            PurchLine."No.", PurchLine."Variant Code", PurchLine."Location Code", PurchLine.Description,
            PurchLine."Expected Receipt Date", 0D, 0, "Reservation Status"::Surplus);
        exit(SerialNo);
    end;

    internal procedure GetOrCreateSerialNoInformation(pItemNo: Code[20]; pVariantCode: Code[10]; pSerialNo: Code[50]; var SerialNoInformation: Record "Serial No. Information")
    begin
        if SerialNoInformation.Get(pItemNo, pVariantCode, pSerialNo) then
            exit;
        SerialNoInformation.Init();
        SerialNoInformation."Item No." := pItemNo;
        SerialNoInformation."Variant Code" := pVariantCode;
        SerialNoInformation."Serial No." := pSerialNo;
        SerialNoInformation.Insert(true);
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
