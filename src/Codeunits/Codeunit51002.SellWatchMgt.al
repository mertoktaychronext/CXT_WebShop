codeunit 51002 "SellWatch Mgt"
{
    trigger OnRun()
    begin
        // Urspruengliche Function-Name-basierte Fallunterscheidung (GMBH/BV) war im Quellsystem bereits deaktiviert (auskommentiert).
        ValidateAndCreateVendor();
    end;

    local procedure ValidateAndCreateVendor()
    begin
        SellWatchVendorInfo.SetRange(Created, false);
        if SellWatchVendorInfo.FindSet() then
            repeat
                VendorRec.Reset();
                VendorRec.SetRange(Name, SellWatchVendorInfo."Vendor Name");
                VendorRec.SetRange(Address, SellWatchVendorInfo.Address);
                VendorRec.SetRange("Phone No.", SellWatchVendorInfo.PhoneNo);
                VendorRec.SetRange("E-Mail", SellWatchVendorInfo.Email);
                if not VendorRec.FindFirst() then begin
                    VendorRec.Init();
                    VendorRec."No." := '';
                    VendorRec.Name := SellWatchVendorInfo."Vendor Name";
                    VendorRec.Address := SellWatchVendorInfo.Address;
                    VendorRec."Address 2" := SellWatchVendorInfo."Address 2";
                    VendorRec.City := SellWatchVendorInfo.City;
                    VendorRec.County := SellWatchVendorInfo.County;
                    VendorRec."Country/Region Code" := CopyStr(SellWatchVendorInfo.CountryCode, 1, 2);
                    VendorRec."Post Code" := SellWatchVendorInfo."Post Code";
                    VendorRec."Phone No." := SellWatchVendorInfo.PhoneNo;
                    VendorRec."E-Mail" := SellWatchVendorInfo.Email;
                    // TODO: Objekt Prozedur "SetPostingGroups" nicht geliefert (keine Standardprozedur auf Vendor, vermutlich eigene Table-Extension/Codeunit). Manuell pruefen und Aufruf ggf. wiederherstellen.
                    // VendorRec.SetPostingGroups();
                    if SellWatchVendorInfo.CurrencyCode <> 'EUR' then
                        VendorRec."Currency Code" := SellWatchVendorInfo.CurrencyCode;
                    if SellWatchVendorInfo."Offer Type" = 'commission' then
                        VendorRec."Payment Method Code" := 'C2C'
                    else
                        VendorRec."Payment Method Code" := 'RG';
                    // TODO: Objekt Prozedur "GetnewNoSeries" nicht geliefert (keine Standardprozedur auf Vendor, vermutlich eigene Table-Extension/Codeunit). Manuell pruefen; andernfalls uebernimmt der Standard-OnInsert-Trigger von Vendor die Nummernvergabe ueber Purchases & Payables Setup.
                    // VendorRec.GetnewNoSeries(true);
                    VendorRec.Insert(true);

                    VendorBank.Init();
                    VendorBank."Vendor No." := VendorRec."No.";
                    VendorBank.Code := CopyStr(SellWatchVendorInfo.IBAN, StrLen(SellWatchVendorInfo.IBAN) - 3, 4) + ' ' + SellWatchVendorInfo.CurrencyCode;
                    VendorBank.IBAN := SellWatchVendorInfo.IBAN;
                    // TODO: Objekt Feld "akq IBAN / SWIFT approved" nicht Teil des Standard-Vendor-Bank-Account. Herkunft der Erweiterung nicht mitgeliefert - manuell pruefen.
                    // VendorBank."akq IBAN / SWIFT approved" := true;
                    VendorBank.Insert(true);
                end;
                CreatePurchaseOrder();
            until SellWatchVendorInfo.Next() = 0;
    end;

    local procedure CreatePurchaseOrder()
    begin
        if (SellWatchVendorInfo."PO Number" = '') or (SellWatchVendorInfo."PO Number" = '0') then begin
            PHRec.Init();
            PHRec."No." := '';
            PHRec."Document Type" := PHRec."Document Type"::Order;
            PHRec.Insert(true);
            PHRec.Validate("Buy-from Vendor No.", VendorRec."No.");
            PHRec."Vendor Order No." := SellWatchVendorInfo.SRid;
            if SellWatchVendorInfo.BillToName <> '' then begin
                PHRec."Pay-to Name" := SellWatchVendorInfo.BillToName;
                PHRec."Pay-to Address" := SellWatchVendorInfo.BillToAddress;
                PHRec."Pay-to City" := SellWatchVendorInfo.BillToCity;
                PHRec."Pay-to Post Code" := SellWatchVendorInfo.BillToPostCode;
                PHRec."Pay-to Country/Region Code" := SellWatchVendorInfo.BillToCountryCode;
                PHRec."Pay-to County" := SellWatchVendorInfo.BillToCounty;
            end;
            if SellWatchVendorInfo."Offer Type" = 'commission' then
                PHRec."Payment Method Code" := 'C2C'
            else
                PHRec."Payment Method Code" := 'RG';
            PHRec.Modify();

            PLRec.Init();
            PLRec."Document No." := PHRec."No.";
            PLRec."Document Type" := PHRec."Document Type";
            PLRec."Line No." := 10000;
            PLRec.Validate(Type, PLRec.Type::Item);
            if SellWatchVendorInfo."Offer Type" = 'commission' then begin
                PLRec.Validate("No.", 'C2C-SW');
                PLRec."Variant Code" := 'C2C-SW';
            end;
            if SellWatchVendorInfo."Offer Type" = 'direct' then begin
                PLRec.Validate("No.", 'CPST-SW');
                PLRec."Variant Code" := 'CPST-SW';
            end;
            if SellWatchVendorInfo."Offer Type" = 'exchange' then begin
                PLRec.Validate("No.", 'TI-SW');
                PLRec."Variant Code" := 'TI-SW';
            end;

            PLRec.Validate(Quantity, 1);
            PLRec."Used good" := true;
            PLRec.Amount := SellWatchVendorInfo."Final Offer Price";
            PLRec.Validate("Direct Unit Cost", SellWatchVendorInfo."Final Offer Price");
            PLRec.Insert();

            ReleasePurchDoc.PerformManualRelease(PHRec);

            SellWatchVendorInfo."PO Number" := PHRec."No.";
            SellWatchVendorInfo.Created := true;
            SellWatchVendorInfo.VendorNo := VendorRec."No.";
            SellWatchVendorInfo.Modify();

            if GuiAllowed() then
                Message(VendorAndPOCreatedMsg);
        end;
    end;

    local procedure CreatePurchaseOrderinBV()
    begin
        SellWatchVendorInfo.Reset();
        SellWatchVendorInfo.SetRange(CreatePOinBV, true);
        SellWatchVendorInfo.SetRange("PO Number", '');
        if SellWatchVendorInfo.FindSet() then
            repeat
                if SellWatchVendorInfo.VendorNo <> '' then
                    VendorRec.Get(SellWatchVendorInfo.VendorNo);
                CreatePurchaseOrder();
            until SellWatchVendorInfo.Next() = 0;
    end;

    local procedure CreatePurchaseOrderinGmBH()
    begin
        if (SellWatchVendorInfo."Offer Type" = 'commission') or (SellWatchVendorInfo."Offer Type" = 'exchange') then
            CreatePurchaseOrder()
        else begin
            SellWatchVendorInfo.CreatePOinBV := true;
            SellWatchVendorInfo.VendorNo := VendorRec."No.";
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
        if PurchaseHeader."Tracking Number" <> '' then
            OrderJObject.Add('tracking_number', PurchaseHeader."Tracking Number");
        OrderJObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure CreateSourceFileOrderStatusSE(SellWatchInfo: Record "SellWatch Vendor Info"; Status: Enum "SW Order Status"): Text
    var
        PurLineArchive: Record "Purchase Line Archive";
        OrderJObject: JsonObject;
        JsonText: Text;
        Position: Integer;
        FirstName: Text;
        LastName: Text;
    begin
        OrderJObject.Add('SRid', SellWatchInfo.SRid);
        OrderJObject.Add('status', Format(Status));
        OrderJObject.Add('email', SellWatchInfo.Email);

        Position := StrPos(SellWatchInfo."Vendor Name", ' ');
        if Position > 0 then begin
            FirstName := DelStr(SellWatchInfo."Vendor Name", Position, StrLen(SellWatchInfo."Vendor Name") - Position);
            LastName := DelStr(SellWatchInfo."Vendor Name", 1, Position - 1);
        end;
        OrderJObject.Add('firstName', FirstName);
        OrderJObject.Add('lastName', LastName);
        OrderJObject.Add('gender', SellWatchInfo.Gender);
        OrderJObject.Add('language', SellWatchInfo.LanguageCode);
        OrderJObject.Add('watchBrand', SellWatchInfo.Brand);
        OrderJObject.Add('watchModel', SellWatchInfo.Model);
        OrderJObject.Add('watchReference', SellWatchInfo.Reference);

        WOA.SetRange("PO number", SellWatchInfo."PO Number");
        if WOA.FindFirst() then;
        OrderJObject.Add('link', WOA.URL);

        PurLineArchive.SetRange("Document Type", PurLineArchive."Document Type"::Order);
        PurLineArchive.SetRange("Document No.", SellWatchInfo."PO Number");
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
        SellWatchVendorInfo: Record "SellWatch Vendor Info";
        PHRec: Record "Purchase Header";
        PLRec: Record "Purchase Line";
        VendorBank: Record "Vendor Bank Account";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        WOA: Record "Watch Online Approval";
        VendorAndPOCreatedMsg: Label 'Vendor and PO created';
}
