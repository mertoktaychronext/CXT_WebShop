namespace CHX.Webshop.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Pricing;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>
/// Test data for the CHX.Webshop tests.
/// Every record is created by the tests themselves, never taken from the sandbox (CRONUS or customer data).
/// Records are inserted with Insert(false): no number series, templates or subscribers of other apps run.
/// Test isolation rolls everything back after each test.
/// </summary>
codeunit 50499 "CXW Test Library"
{
    var
        Any: Codeunit Any;
        SalesPriceEndpointTok: Label 'https://salesprice.test.invalid/prices', Locked = true;
        WebshopAppIdTok: Label '5df32934-5708-418c-ba16-44b30feb51f4', Locked = true;

    #region Codes

    procedure NewCode10(): Code[10]
    begin
        exit(CopyStr(UpperCase('T' + Any.AlphanumericText(9)), 1, 10));
    end;

    procedure NewCode20(): Code[20]
    begin
        exit(CopyStr(UpperCase('T' + Any.AlphanumericText(19)), 1, 20));
    end;

    procedure NewText(): Text[250]
    begin
        exit(CopyStr('T' + Any.AlphanumericText(30), 1, 250));
    end;

    #endregion

    #region Master data

    procedure CreateItem(var Item: Record Item)
    begin
        Item.Init();
        Item."No." := NewCode20();
        Item.Description := Item."No.";
        Item.Insert(false);
    end;

    procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init();
        CountryRegion.Code := NewCode10();
        CountryRegion.Name := CountryRegion.Code;
        CountryRegion.Insert(false);
        exit(CountryRegion.Code);
    end;

    procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Init();
        Currency.Code := NewCode10();
        Currency.Description := Currency.Code;
        Currency.Insert(false);
        exit(Currency.Code);
    end;

    /// <summary>
    /// ExchangeRateAmount units of the currency are worth RelationalExchRateAmount units of the local currency.
    /// </summary>
    procedure CreateExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmount: Decimal; RelationalExchRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.Init();
        CurrencyExchangeRate."Currency Code" := CurrencyCode;
        CurrencyExchangeRate."Starting Date" := StartingDate;
        CurrencyExchangeRate."Exchange Rate Amount" := ExchangeRateAmount;
        CurrencyExchangeRate."Adjustment Exch. Rate Amount" := ExchangeRateAmount;
        CurrencyExchangeRate."Relational Exch. Rate Amount" := RelationalExchRateAmount;
        CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" := RelationalExchRateAmount;
        CurrencyExchangeRate.Insert(false);
    end;

    /// <summary>
    /// VAT posting setup for the blank VAT business posting group (the sales price write-back leaves
    /// "VAT Bus. Posting Gr. (Price)" blank) and a new VAT product posting group, which is returned.
    /// </summary>
    procedure CreateVATPostingSetupForBlankBusGroup(VATPct: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := '';
        VATPostingSetup."VAT Prod. Posting Group" := NewCode20();
        VATPostingSetup."VAT %" := VATPct;
        VATPostingSetup.Insert(false);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    #endregion

    #region Item attributes

    /// <summary>
    /// The app uses fixed attribute IDs (e.g. 22 = dial color). An attribute that already exists in the sandbox
    /// is used as it is; otherwise it is created with exactly this ID.
    /// </summary>
    procedure EnsureItemAttribute(AttributeId: Integer)
    var
        ItemAttribute: Record "Item Attribute";
    begin
        if ItemAttribute.Get(AttributeId) then
            exit;
        ItemAttribute.Init();
        ItemAttribute.ID := AttributeId;
        ItemAttribute.Name := CopyStr(NewText(), 1, MaxStrLen(ItemAttribute.Name));
        ItemAttribute.Type := ItemAttribute.Type::Text;
        ItemAttribute.Insert(false);
    end;

    /// <summary>
    /// Assigns a new attribute value to the item. The value is inserted directly, so also values that the
    /// attribute type would reject on validation (e.g. a year range for an integer attribute) can be set up.
    /// </summary>
    procedure SetItemAttributeValue(ItemNo: Code[20]; AttributeId: Integer; Value: Text[250])
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        EnsureItemAttribute(AttributeId);

        ItemAttributeValue.Init();
        ItemAttributeValue."Attribute ID" := AttributeId;
        ItemAttributeValue.Value := Value;
        ItemAttributeValue.Insert(false);

        ItemAttributeValueMapping.Init();
        ItemAttributeValueMapping."Table ID" := Database::Item;
        ItemAttributeValueMapping."No." := ItemNo;
        ItemAttributeValueMapping."Item Attribute ID" := AttributeId;
        ItemAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValue.ID;
        ItemAttributeValueMapping.Insert(false);
    end;

    #endregion

    #region Purchase orders

    procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10])
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := NewCode20();
        PurchaseHeader."Buy-from Vendor No." := NewCode20();
        PurchaseHeader."Buy-from Vendor Name" := CopyStr(NewText(), 1, MaxStrLen(PurchaseHeader."Buy-from Vendor Name"));
        PurchaseHeader."Vendor Order No." := NewCode20();
        PurchaseHeader."Currency Code" := CurrencyCode;
        PurchaseHeader.Insert(false);
    end;

    procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := ItemNo;
        PurchaseLine.Description := ItemNo;
        PurchaseLine.Quantity := 1;
        PurchaseLine."Quantity (Base)" := 1;
        PurchaseLine."Qty. per Unit of Measure" := 1;
        PurchaseLine.Insert(false);
    end;

    #endregion

    #region API interfaces

    procedure CreateApiInterface(var ApiInterfaceSetup: Record "CXW API Interface Setup"; AuthType: Enum "CXW API Auth Type"; SourceTableNo: Integer)
    begin
        ApiInterfaceSetup.Init();
        ApiInterfaceSetup."CXW Code" := NewCode20();
        ApiInterfaceSetup."CXW Description" := ApiInterfaceSetup."CXW Code";
        ApiInterfaceSetup."CXW Auth Type" := AuthType;
        ApiInterfaceSetup."CXW Source Table No." := SourceTableNo;
        ApiInterfaceSetup.Insert(false);
    end;

    #endregion

    #region Sales prices

    procedure GetSalesPriceSetup(var GenSPSetup: Record "CXW General Sales Price Setup")
    begin
        if GenSPSetup.Get() then
            exit;
        GenSPSetup.Init();
        GenSPSetup.Insert(false);
    end;

    /// <summary>
    /// Sales price export switched on with an active API key interface for "Sales Price", 3 attempts and the
    /// given archive country. The HTTP call itself is intercepted by the HttpClientHandler of the test.
    /// </summary>
    procedure SetupSalesPriceExport(ArchiveCountryCode: Code[10]; ApiKey: Text)
    var
        GenSPSetup: Record "CXW General Sales Price Setup";
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        CreateApiInterface(ApiInterfaceSetup, Enum::"CXW API Auth Type"::ApiKeyHeader, Database::"Sales Price");
        ApiInterfaceSetup."CXW Endpoint URL" := SalesPriceEndpointTok;
        ApiInterfaceSetup."CXW Http Method" := ApiInterfaceSetup."CXW Http Method"::POST;
        ApiInterfaceSetup.SetApiKey(ApiKey);
        ApiInterfaceSetup.Validate("CXW Active", true);
        ApiInterfaceSetup.Modify(false);

        GetSalesPriceSetup(GenSPSetup);
        GenSPSetup."CXW Price Export Active" := true;
        GenSPSetup.Validate("CXW API Interface Code", ApiInterfaceSetup."CXW Code");
        GenSPSetup."CXW Max. Export Attempts" := 3;
        GenSPSetup."CXW Archive Country Code" := ArchiveCountryCode;
        GenSPSetup.Modify(false);

        AllowHttpClientRequests();
    end;

    /// <summary>
    /// Sandboxes ask "Allow Always/Allow Once/Block Always/Block Once" on the first outbound request of an
    /// extension - unhandled UI in a test run. Allowing it up front is harmless: the endpoint is a ".invalid"
    /// domain that never resolves, so Send returns false without any server receiving the request.
    /// </summary>
    local procedure AllowHttpClientRequests()
    var
        NAVAppSetting: Record "NAV App Setting";
        WebshopAppId: Guid;
    begin
        Evaluate(WebshopAppId, WebshopAppIdTok);
        if not NAVAppSetting.Get(WebshopAppId) then begin
            NAVAppSetting.Init();
            NAVAppSetting."App ID" := WebshopAppId;
            NAVAppSetting.Insert(false);
        end;
        NAVAppSetting."Allow HttpClient Requests" := true;
        NAVAppSetting.Modify(false);
    end;

    procedure SetArchiveCountry(ArchiveCountryCode: Code[10])
    var
        GenSPSetup: Record "CXW General Sales Price Setup";
    begin
        GetSalesPriceSetup(GenSPSetup);
        GenSPSetup."CXW Archive Country Code" := ArchiveCountryCode;
        GenSPSetup.Modify(false);
    end;

    procedure SetPriceExportActive(NewActive: Boolean)
    var
        GenSPSetup: Record "CXW General Sales Price Setup";
    begin
        GetSalesPriceSetup(GenSPSetup);
        GenSPSetup."CXW Price Export Active" := NewActive;
        GenSPSetup.Modify(false);
    end;

    /// <summary>
    /// Approved checking line for an item, starting today. A line with a blank country is a source line.
    /// </summary>
    procedure CreateSalesPriceChecking(var SalesPriceChecking: Record "CXW Sales Price Checking"; ItemNo: Code[20]; CurrencyCode: Code[10]; CountryCode: Code[10]; StockPrice: Decimal)
    begin
        SalesPriceChecking.Init();
        SalesPriceChecking."CXW Item No." := ItemNo;
        SalesPriceChecking."CXW Currency Code" := CurrencyCode;
        SalesPriceChecking."CXW Country Code" := CountryCode;
        SalesPriceChecking."CXW Starting Date" := Today();
        SalesPriceChecking."CXW Stock Price" := StockPrice;
        SalesPriceChecking."CXW Validated" := true;
        SalesPriceChecking."CXW Accept New Setup" := true;
        SalesPriceChecking.Insert(false);
    end;

    /// <summary>
    /// Releases the checking line like the "Release Sales Prices" action does for each line
    /// (write-back, archive, export record, export entry) and returns the created export entry.
    /// </summary>
    procedure ReleaseSalesPriceChecking(var SalesPriceChecking: Record "CXW Sales Price Checking"; var DataExportEntry: Record "Data Export Entry")
    var
        SalesPriceExport: Record "CXW Sales Price Export";
    begin
        Codeunit.Run(Codeunit::"CXW Release Sales Price Line", SalesPriceChecking);
        SalesPriceChecking.Get(SalesPriceChecking."CXW Item No.", SalesPriceChecking."CXW Currency Code", SalesPriceChecking."CXW Country Code");

        FindSalesPriceExport(SalesPriceExport, SalesPriceChecking."CXW Item No.", SalesPriceChecking."CXW Country Code");
        DataExportEntry.Get(SalesPriceExport."CXW Data Export Entry No.");
    end;

    procedure CreateAndReleaseSalesPrice(var Item: Record Item; StockPrice: Decimal; var DataExportEntry: Record "Data Export Entry")
    var
        SalesPriceChecking: Record "CXW Sales Price Checking";
    begin
        CreateItem(Item);
        CreateSalesPriceChecking(SalesPriceChecking, Item."No.", '', CreateCountryRegion(), StockPrice);
        ReleaseSalesPriceChecking(SalesPriceChecking, DataExportEntry);
    end;

    procedure FindSalesPriceExport(var SalesPriceExport: Record "CXW Sales Price Export"; ItemNo: Code[20]; CountryCode: Code[10])
    begin
        SalesPriceExport.SetRange("CXW Item No.", ItemNo);
        SalesPriceExport.SetRange("CXW Country Code", CountryCode);
        SalesPriceExport.FindLast();
    end;

    procedure FindSalesPrice(var SalesPrice: Record "Sales Price"; ItemNo: Code[20]; CurrencyCode: Code[10]): Boolean
    begin
        exit(SalesPrice.Get(ItemNo, SalesPrice."Sales Type"::"All Customers", '', Today(), CurrencyCode, '', '', 0));
    end;

    procedure RunSalesPriceExportJob()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Codeunit.Run(Codeunit::"CXW Export Sales Price Job", JobQueueEntry);
    end;

    procedure GetPayloadText(DataExportEntryNo: BigInteger) PayloadText: Text
    var
        DataExportEntry: Record "Data Export Entry";
        PayloadInStream: InStream;
    begin
        DataExportEntry.Get(DataExportEntryNo);
        DataExportEntry.CreatePayloadInStream(PayloadInStream);
        PayloadInStream.Read(PayloadText);
    end;

    procedure GetPayload(DataExportEntryNo: BigInteger) Payload: JsonObject
    begin
        Payload.ReadFrom(GetPayloadText(DataExportEntryNo));
    end;

    procedure GetPayloadValue(Payload: JsonObject; KeyName: Text): JsonValue
    var
        Token: JsonToken;
    begin
        Payload.Get(KeyName, Token);
        exit(Token.AsValue());
    end;

    procedure FindLastHttpCallLog(var HttpCallLog: Record "CXW Http Call Log"; DataExportEntryNo: BigInteger): Boolean
    begin
        HttpCallLog.SetRange("CXW Source Table No.", Database::"Data Export Entry");
        HttpCallLog.SetRange("CXW Source Entry No", DataExportEntryNo);
        exit(HttpCallLog.FindLast());
    end;

    procedure GetLoggedRequest(var HttpCallLog: Record "CXW Http Call Log") RequestText: Text
    var
        RequestInStream: InStream;
    begin
        HttpCallLog.CalcFields("CXW Request");
        HttpCallLog."CXW Request".CreateInStream(RequestInStream, TextEncoding::UTF8);
        RequestInStream.Read(RequestText);
    end;

    #endregion
}
