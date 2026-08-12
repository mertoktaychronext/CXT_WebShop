codeunit 60305 "CXW SellWatch Mgt"
{
    trigger OnRun()
    begin
        // Urspruengliche Function-Name-basierte Fallunterscheidung (GMBH/BV) war im Quellsystem bereits deaktiviert (auskommentiert).
        ValidateAndCreateVendor();
    end;

    local procedure ValidateAndCreateVendor()
    begin
        SellWatchVendorInfo.SetRange("CXW Created", false);
        if SellWatchVendorInfo.FindSet() then
            repeat
                VendorRec.Reset();
                VendorRec.SetRange(Name, SellWatchVendorInfo."CXW Vendor Name");
                VendorRec.SetRange(Address, SellWatchVendorInfo."CXW Address");
                VendorRec.SetRange("Phone No.", SellWatchVendorInfo."CXW PhoneNo");
                VendorRec.SetRange("E-Mail", SellWatchVendorInfo."CXW Email");
                if not VendorRec.FindFirst() then begin
                    VendorRec.Init();
                    VendorRec."No." := '';
                    VendorRec.Name := SellWatchVendorInfo."CXW Vendor Name";
                    VendorRec.Address := SellWatchVendorInfo."CXW Address";
                    VendorRec."Address 2" := SellWatchVendorInfo."CXW Address 2";
                    VendorRec.City := SellWatchVendorInfo."CXW City";
                    VendorRec.County := SellWatchVendorInfo."CXW County";
                    VendorRec."Country/Region Code" := CopyStr(SellWatchVendorInfo."CXW CountryCode", 1, 2);
                    VendorRec."Post Code" := SellWatchVendorInfo."CXW Post Code";
                    VendorRec."Phone No." := SellWatchVendorInfo."CXW PhoneNo";
                    VendorRec."E-Mail" := SellWatchVendorInfo."CXW Email";
                    VendorRec.SetPostingGroups();
                    if SellWatchVendorInfo."CXW CurrencyCode" <> 'EUR' then
                        VendorRec."Currency Code" := SellWatchVendorInfo."CXW CurrencyCode";
                    if SellWatchVendorInfo."CXW Offer Type" = 'commission' then
                        VendorRec."Payment Method Code" := 'C2C'
                    else
                        VendorRec."Payment Method Code" := 'RG';
                    VendorRec.GetnewNoSeries(true);
                    VendorRec.Validate("Location Code", 'HL'); //TODO: Klären Lagerort für SellWatch Artikel; aktuell hartkodiert auf HL (Hauptlager)
                    VendorRec.Insert(true);

                    VendorBank.Init();
                    VendorBank."Vendor No." := VendorRec."No.";
                    VendorBank.Code := CopyStr(SellWatchVendorInfo."CXW IBAN", StrLen(SellWatchVendorInfo."CXW IBAN") - 3, 4) + ' ' + SellWatchVendorInfo."CXW CurrencyCode";
                    VendorBank.IBAN := SellWatchVendorInfo."CXW IBAN";
                    VendorBank.Insert(true);
                end;
                CreatePurchaseOrder();
            until SellWatchVendorInfo.Next() = 0;
    end;

    local procedure CreatePurchaseOrder()
    begin
        if (SellWatchVendorInfo."CXW PO Number" = '') or (SellWatchVendorInfo."CXW PO Number" = '0') then begin
            PHRec.Init();
            PHRec."No." := '';
            PHRec."Document Type" := PHRec."Document Type"::Order;
            PHRec.Insert(true);
            PHRec.Validate("Buy-from Vendor No.", VendorRec."No.");
            PHRec."Vendor Order No." := SellWatchVendorInfo."CXW SRid";
            if SellWatchVendorInfo."CXW BillToName" <> '' then begin
                PHRec."Pay-to Name" := SellWatchVendorInfo."CXW BillToName";
                PHRec."Pay-to Address" := SellWatchVendorInfo."CXW BillToAddress";
                PHRec."Pay-to City" := SellWatchVendorInfo."CXW BillToCity";
                PHRec."Pay-to Post Code" := SellWatchVendorInfo."CXW BillToPostCode";
                PHRec."Pay-to Country/Region Code" := SellWatchVendorInfo."CXW BillToCountryCode";
                PHRec."Pay-to County" := SellWatchVendorInfo."CXW BillToCounty";
            end;
            if SellWatchVendorInfo."CXW Offer Type" = 'commission' then
                PHRec."Payment Method Code" := 'C2C'
            else
                PHRec."Payment Method Code" := 'RG';
            PHRec.Modify();

            PLRec.Init();
            PLRec."Document No." := PHRec."No.";
            PLRec."Document Type" := PHRec."Document Type";
            PLRec."Line No." := 10000;
            PLRec.Validate(Type, PLRec.Type::Item);
            PLRec.Validate("No.", CreateSellWatchItem());

            PLRec.Validate(Quantity, 1);
            PLRec."CXW Used good" := true;
            PLRec.Amount := SellWatchVendorInfo."CXW Final Offer Price";
            PLRec.Validate("Direct Unit Cost", SellWatchVendorInfo."CXW Final Offer Price");

            PLRec.Insert();

            ReleasePurchDoc.PerformManualRelease(PHRec);

            SellWatchVendorInfo."CXW PO Number" := PHRec."No.";
            SellWatchVendorInfo."CXW Created" := true;
            SellWatchVendorInfo."CXW VendorNo" := VendorRec."No.";
            SellWatchVendorInfo.Modify();

            if GuiAllowed() then
                Message(VendorAndPOCreatedMsg);
        end;
    end;

    local procedure CreateSellWatchItem(): Code[20]
    var
        Item: Record Item;
        ItemTemplate: Record "Item Templ.";
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        Item.Init();
        //TODO: Item Template einrichtenbar, Wo?; Evtl Nummernserie fuer SellWatch Artikel einrichten
        if not ItemTemplate.FindFirst() then
            Error(NoItemTemplateFoundErr);
        Item."No." := '';
        Item.Validate(Description, CopyStr(SellWatchVendorInfo."CXW Brand" + ' ' + SellWatchVendorInfo."CXW Model" + ' ' + SellWatchVendorInfo."CXW Construction Year", 1, MaxStrLen(Item.Description)));
        Item.Validate("Description 2", CopyStr(SellWatchVendorInfo."CXW Reference", 1, MaxStrLen(Item."Description 2")));

        Item.TransferFields(ItemTemplate, true);
        Item.Insert(true);
        ItemUnitofMeasure.Init();
        ItemUnitofMeasure."Item No." := Item."No.";
        ItemUnitofMeasure.Validate("Code", Item."Base Unit of Measure");
        ItemUnitofMeasure.Validate("Qty. per Unit of Measure", 1);
        ItemUnitofMeasure.Validate("Qty. Rounding Precision", 1);
        ItemUnitofMeasure.Insert();
        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrderinBV()
    begin
        SellWatchVendorInfo.Reset();
        SellWatchVendorInfo.SetRange("CXW CreatePOinBV", true);
        SellWatchVendorInfo.SetRange("CXW PO Number", '');
        if SellWatchVendorInfo.FindSet() then
            repeat
                if SellWatchVendorInfo."CXW VendorNo" <> '' then
                    VendorRec.Get(SellWatchVendorInfo."CXW VendorNo");
                CreatePurchaseOrder();
            until SellWatchVendorInfo.Next() = 0;
    end;

    local procedure CreatePurchaseOrderinGmBH()
    begin
        if (SellWatchVendorInfo."CXW Offer Type" = 'commission') or (SellWatchVendorInfo."CXW Offer Type" = 'exchange') then
            CreatePurchaseOrder()
        else begin
            SellWatchVendorInfo."CXW CreatePOinBV" := true;
            SellWatchVendorInfo."CXW VendorNo" := VendorRec."No.";
            SellWatchVendorInfo.Modify();
        end;
    end;

    // Hinweis: CreateExternalInterfaceFileOnPurchaseRequest und CreateExternalInterfaceFileOnOrderStatusSE (alte Ausgabe-Dateien
    // ueber Table 5275373 "Ext Interface Setup" / Table 5275378 "Ext Interface Outbound File") wurden auf Wunsch entfernt,
    // da diese Objekte laut Nutzer nicht mehr benoetigt werden. Die reinen JSON-Builder-Funktionen darunter blieben erhalten.

    procedure CreateSourceFilePurchaseRequest(PurchaseHeader: Record "Purchase Header"): Text
    var
        OrderJObject: JsonObject;
        JsonText: Text;
    begin
        OrderJObject.Add('SRid', PurchaseHeader."Vendor Order No.");
        OrderJObject.Add('purchase_order', PurchaseHeader."No.");
        if PurchaseHeader."CXW Tracking Number" <> '' then
            OrderJObject.Add('tracking_number', PurchaseHeader."CXW Tracking Number");
        OrderJObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure CreateSourceFileOrderStatusSE(SellWatchInfo: Record "CXW SellWatch Vendor Info"; Status: Enum "CXW SW Order Status"): Text
    var
        PurLineArchive: Record "Purchase Line Archive";
        OrderJObject: JsonObject;
        JsonText: Text;
        Position: Integer;
        FirstName: Text;
        LastName: Text;
    begin
        OrderJObject.Add('SRid', SellWatchInfo."CXW SRid");
        OrderJObject.Add('status', Format(Status));
        OrderJObject.Add('email', SellWatchInfo."CXW Email");

        Position := StrPos(SellWatchInfo."CXW Vendor Name", ' ');
        if Position > 0 then begin
            FirstName := DelStr(SellWatchInfo."CXW Vendor Name", Position, StrLen(SellWatchInfo."CXW Vendor Name") - Position);
            LastName := DelStr(SellWatchInfo."CXW Vendor Name", 1, Position - 1);
        end;
        OrderJObject.Add('firstName', FirstName);
        OrderJObject.Add('lastName', LastName);
        OrderJObject.Add('gender', SellWatchInfo."CXW Gender");
        OrderJObject.Add('language', SellWatchInfo."CXW LanguageCode");
        OrderJObject.Add('watchBrand', SellWatchInfo."CXW Brand");
        OrderJObject.Add('watchModel', SellWatchInfo."CXW Model");
        OrderJObject.Add('watchReference', SellWatchInfo."CXW Reference");

        WOA.SetRange("CXW PO number", SellWatchInfo."CXW PO Number");
        if WOA.FindFirst() then;
        OrderJObject.Add('link', WOA."CXW URL");

        PurLineArchive.SetRange("Document Type", PurLineArchive."Document Type"::Order);
        PurLineArchive.SetRange("Document No.", SellWatchInfo."CXW PO Number");
        PurLineArchive.SetRange("Line No.", 10000);
        if PurLineArchive.FindLast() then;

        if PurLineArchive."Currency Code" <> '' then
            OrderJObject.Add('c2cFinalCurrency', PurLineArchive."Currency Code")
        else
            OrderJObject.Add('c2cFinalCurrency', 'EUR');

        OrderJObject.Add('c2cFinalPayout', PurLineArchive."Amount Including VAT");

        OrderJObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    var
        VendorRec: Record Vendor;
        SellWatchVendorInfo: Record "CXW SellWatch Vendor Info";
        PHRec: Record "Purchase Header";
        PLRec: Record "Purchase Line";
        VendorBank: Record "Vendor Bank Account";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        WOA: Record "CXW Watch Online Approval";
        VendorAndPOCreatedMsg: Label 'Vendor and PO created';
        NoItemTemplateFoundErr: Label 'No item template found. Cannot create an item for the SellWatch offer.';
}
