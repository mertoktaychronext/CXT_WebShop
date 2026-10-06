codeunit 60305 "CXW SellWatch Mgt"
{
    trigger OnRun()
    begin
        // Urspruengliche Function-Name-basierte Fallunterscheidung (GMBH/BV) war im Quellsystem bereits deaktiviert (auskommentiert).
        ValidateAndCreateVendor();
    end;

    local procedure ValidateAndCreateVendor()
    var
        SellWatchOffer: Record "CXW SellWatch Vendor Info";
        OpenEntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        // Collect first: each offer is committed separately, which changes the "CXW Created" filter field.
        SellWatchOffer.SetRange("CXW Created", false);
        SellWatchOffer.SetLoadFields("CXW Entry No");
        if SellWatchOffer.FindSet() then
            repeat
                OpenEntryNos.Add(SellWatchOffer."CXW Entry No");
            until SellWatchOffer.Next() = 0;

        foreach EntryNo in OpenEntryNos do
            ProcessOfferWithErrorHandling(EntryNo);
    end;

    local procedure ProcessOfferWithErrorHandling(EntryNo: Integer)
    var
        SellWatchOffer: Record "CXW SellWatch Vendor Info";
    begin
        if not SellWatchOffer.Get(EntryNo) then
            exit;
        // Codeunit.Run rolls back everything done for this offer on failure (vendor, PO, item);
        // a TryFunction would not roll back database writes.
        Commit();
        ClearLastError();
        if not Codeunit.Run(Codeunit::"CXW SellWatch Process Offer", SellWatchOffer) then begin
            SellWatchOffer.Get(EntryNo);
            SellWatchOffer."CXW Last Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(SellWatchOffer."CXW Last Error"));
            SellWatchOffer."CXW Last Error DateTime" := CurrentDateTime();
            SellWatchOffer.Modify();
        end;
        Commit();
    end;

    internal procedure ProcessOffer(var SellWatchOffer: Record "CXW SellWatch Vendor Info")
    begin
        SellWatchVendorInfo := SellWatchOffer;
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
            VendorRec."Post Code" := SellWatchVendorInfo."CXW Post Code";
            SetCountryRegionCode(CopyStr(SellWatchVendorInfo."CXW CountryCode", 1, 2));
            VendorRec."Phone No." := SellWatchVendorInfo."CXW PhoneNo";
            VendorRec."E-Mail" := SellWatchVendorInfo."CXW Email";
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
        SellWatchOffer := SellWatchVendorInfo;
    end;

    // Validate lets the Salini Base App default the posting groups from the country template
    // (replaces CHX.Base Vendor.SetPostingGroups since CHX.Base 28.0). Unknown country codes are
    // still accepted as before, just without posting-group defaulting.
    local procedure SetCountryRegionCode(CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(CountryRegionCode) then
            VendorRec.Validate("Country/Region Code", CountryRegionCode)
        else
            VendorRec."Country/Region Code" := CountryRegionCode;
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
            SellWatchVendorInfo."CXW Last Error" := '';
            SellWatchVendorInfo."CXW Last Error DateTime" := 0DT;
            SellWatchVendorInfo.Modify();

            if GuiAllowed() then
                Message(VendorAndPOCreatedMsg);
        end;
    end;

    local procedure CreateSellWatchItem(): Code[20]
    var
        Item: Record Item;
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        ItemTemplCode: Code[20];
        IsHandled: Boolean;
    begin
        ItemTemplCode := GetSellWatchItemTemplateCode();
        // Standard creates the item incl. number (No. Series of the template, else Inventory Setup),
        // validated template fields, base unit of measure and default dimensions.
        if not ItemTemplMgt.CreateItemFromTemplate(Item, IsHandled, ItemTemplCode) then
            Error(ItemNotCreatedFromTemplateErr, ItemTemplCode);

        // Set SellWatch values after the template so template values cannot overwrite them.
        Item.Validate(Description, CopyStr(SellWatchVendorInfo."CXW Brand" + ' ' + SellWatchVendorInfo."CXW Model" + ' ' + SellWatchVendorInfo."CXW Construction Year", 1, MaxStrLen(Item.Description)));
        Item.Validate("Description 2", CopyStr(SellWatchVendorInfo."CXW Reference", 1, MaxStrLen(Item."Description 2")));
        if SellWatchVendorInfo."CXW Offer Type" = 'commission' then
            Item.Validate("CXB Consignment Sales", true);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure GetSellWatchItemTemplateCode(): Code[20]
    var
        ItemTempl: Record "Item Templ.";
        PurchSetup: Record "Purchases & Payables Setup";
        ItemTemplCode: Code[20];
    begin
        PurchSetup.Get();
        if SellWatchVendorInfo."CXW Offer Type" = 'commission' then begin
            ItemTemplCode := PurchSetup."CXW SW Consign. Item Templ.";
            if ItemTemplCode = '' then
                Error(NoConsignItemTemplateSetUpErr);
        end else begin
            ItemTemplCode := PurchSetup."CXW SW Item Template Code";
            if ItemTemplCode = '' then
                Error(NoStdItemTemplateSetUpErr);
        end;
        if not ItemTempl.Get(ItemTemplCode) then
            Error(ItemTemplateNotFoundErr, ItemTemplCode);
        exit(ItemTemplCode);
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
        NoStdItemTemplateSetUpErr: Label 'No standard item template is set up for SellWatch item creation. Please set the SellWatch Item Template (Standard) field on the Purchases & Payables Setup page.';
        NoConsignItemTemplateSetUpErr: Label 'No commission item template is set up for SellWatch item creation. Please set the SellWatch Item Template (Commission) field on the Purchases & Payables Setup page.';
        ItemNotCreatedFromTemplateErr: Label 'The item for the SellWatch offer could not be created from item template %1.', Comment = '%1 = item template code';
        ItemTemplateNotFoundErr: Label 'The item template %1 set up on the Purchases & Payables Setup page no longer exists. Cannot create an item for the SellWatch offer.', Comment = '%1 = item template code';
}
