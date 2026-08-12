page 60337 "CXW SellWatch API"
{
    PageType = API;
    SourceTable = "CXW SellWatch Vendor Info";
    APIPublisher = 'saliniLife';
    APIGroup = 'sellWatch';
    APIVersion = 'v2.0';
    EntityName = 'sellWatchVendorInfo';
    EntitySetName = 'sellWatchVendorInfos';
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(entryNo; Rec."CXW Entry No")
                {
                    Editable = false;
                }
                field(srid; Rec."CXW SRid") { }
                field(vendorName; Rec."CXW Vendor Name") { }
                field(name2; Rec."CXW Name 2") { }
                field(address; Rec."CXW Address") { }
                field(address2; Rec."CXW Address 2") { }
                field(city; Rec."CXW City") { }
                field(contact; Rec."CXW Contact") { }
                field(phoneNo; Rec."CXW PhoneNo") { }
                field(iban; Rec."CXW IBAN") { }
                field(email; Rec."CXW Email") { }
                field(countryCode; Rec."CXW CountryCode") { }
                field(postCode; Rec."CXW Post Code") { }
                field(county; Rec."CXW County") { }
                field(brand; Rec."CXW Brand") { }
                field(model; Rec."CXW Model") { }
                field(reference; Rec."CXW Reference") { }
                field(sku; Rec."CXW SKU") { }
                field(constructionYear; Rec."CXW Construction Year") { }
                field(watchCondition; Rec."CXW Watch Condition") { }
                field(paperAvailable; Rec."CXW Paper Available") { }
                field(boxAvailable; Rec."CXW Box Available") { }
                field(offerType; Rec."CXW Offer Type") { }
                field(taxation; Rec."CXW Taxation") { }
                field(finalOfferPrice; Rec."CXW Final Offer Price") { }
                field(bankName; Rec."CXW Bank Name") { }
                field(bic; Rec."CXW BIC") { }
                field(currencyCode; Rec."CXW CurrencyCode") { }
                field(createPOinBV; Rec."CXW CreatePOinBV") { }
                field(billToAddress; Rec."CXW BillToAddress") { }
                field(billToName; Rec."CXW BillToName") { }
                field(billToCity; Rec."CXW BillToCity") { }
                field(billToPostCode; Rec."CXW BillToPostCode") { }
                field(billToCountryCode; Rec."CXW BillToCountryCode") { }
                field(billToCounty; Rec."CXW BillToCounty") { }
                field(pickupDate; Rec."CXW PickupDate") { }
                field(cxtSalesPrice; Rec."CXW CXTSalesPrice") { }
                field(gender; Rec."CXW Gender") { }
                field(languageCode; Rec."CXW LanguageCode") { }
                field(nuveiAccountCode; Rec."CXW NuveiAccountCode") { }
                field(trackingNumber; Rec."CXW Tracking Number") { }
                field(created; Rec."CXW Created")
                {
                    Editable = false;
                }
                field(poNumber; Rec."CXW PO Number")
                {
                    Editable = false;
                }
                field(vendorNo; Rec."CXW VendorNo")
                {
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."CXW Created" := false;
        Rec."CXW PO Number" := '';
        Rec."CXW VendorNo" := '';
        ValidateRequiredFields();
        CheckDuplicateSRid();
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec."CXW Created" := xRec."CXW Created";
        Rec."CXW PO Number" := xRec."CXW PO Number";
        Rec."CXW VendorNo" := xRec."CXW VendorNo";
        ValidateRequiredFields();
        if Rec."CXW SRid" <> xRec."CXW SRid" then
            CheckDuplicateSRid();
        exit(true);
    end;

    local procedure ValidateRequiredFields()
    begin
        if Rec."CXW SRid" = '' then
            Error(FieldRequiredErr, Rec.FieldCaption("CXW SRid"));
        if Rec."CXW Brand" = '' then
            Error(FieldRequiredErr, Rec.FieldCaption("CXW Brand"));
        if Rec."CXW Model" = '' then
            Error(FieldRequiredErr, Rec.FieldCaption("CXW Model"));
        if Rec."CXW Final Offer Price" = 0 then
            Error(FieldRequiredErr, Rec.FieldCaption("CXW Final Offer Price"));
    end;

    local procedure CheckDuplicateSRid()
    var
        SellWatchVendorInfo: Record "CXW SellWatch Vendor Info";
    begin
        SellWatchVendorInfo.SetRange("CXW SRid", Rec."CXW SRid");
        SellWatchVendorInfo.SetFilter("CXW Entry No", '<>%1', Rec."CXW Entry No");
        if not SellWatchVendorInfo.IsEmpty() then
            Error(DuplicateSRidErr, Rec."CXW SRid");
    end;

    var
        FieldRequiredErr: Label '%1 must not be empty.', Comment = '%1 = field caption';
        DuplicateSRidErr: Label 'A SellWatch Vendor Info entry with SRid ''%1'' already exists.', Comment = '%1 = SRid value';
}
