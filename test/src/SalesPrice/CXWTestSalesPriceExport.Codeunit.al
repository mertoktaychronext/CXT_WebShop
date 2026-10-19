namespace CHX.Webshop.Test;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Pricing;
using System.TestLibraries.Utilities;

/// <summary>
/// Release of a sales price into the export queue, the payload, the logged request and the export job.
/// Sources: openspec/specs/sales-price-api-export, sales-price-export-job, sales-price-http-call-logging.
///
/// HTTP: [HttpClientHandler] is OnPrem only and cannot be used in online sandboxes. The export therefore
/// targets a ".invalid" domain (RFC 2606) that never resolves, so no server can receive a request. The test
/// library allows HttpClient requests for CHX.Webshop, otherwise the sandbox asks "Allow Always/Allow Once/..."
/// on the first request - unhandled UI in a test run. Every attempt fails - the tests only check what
/// the app stores before and after sending (payload, attempt, log). A successful transmission is not tested here.
/// </summary>
codeunit 50403 "CXW Test Sales Price Export"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        TestLibrary: Codeunit "CXW Test Library";
        ExportGatewaySalesPrice: Codeunit "CXW Export Gateway Sales Price";
        ApiKeyTok: Label 'test-api-key-0815', Locked = true;
        RedactedTok: Label '***redacted***', Locked = true;
        PayloadKeysTok: Label 'itemNo,variantCode,salesType,salesCode,startingDate,currencyCode,countryRegionCode,unitOfMeasureCode,minimumQuantity,unitPrice,priceIncludesVat,allowInvoiceDisc,vatBusPostingGrPrice,endingDate,allowLineDisc,id,remark,nonStockPrice,lastModifiedUserID,lastModifiedDate,reasonCode,comment,strikePriceInclVat,recomRetailPriceInclVat,unitPriceLcy,startingTime,endingTime,profit,unitCost,vatProdPostingGroup', Locked = true;
        NumberKeysTok: Label 'minimumQuantity,unitPrice,nonStockPrice,strikePriceInclVat,recomRetailPriceInclVat,unitPriceLcy,profit,unitCost', Locked = true;
        BooleanKeysTok: Label 'priceIncludesVat,allowInvoiceDisc,allowLineDisc', Locked = true;
        CountryCodeMissingErr: Label 'Country Code must have a value', Locked = true;
        ExportRecordMissingErr: Label 'The sales price export record of data export entry', Locked = true;
        NoLongerExistsErr: Label 'no longer exists', Locked = true;

    #region Release

    [Test]
    procedure ReleaseCreatesExportRecordAndPendingEntry()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPriceExport: Record "CXW Sales Price Export";
        DataExportEntry: Record "Data Export Entry";
    begin
        Initialize();
        // Spec sales-price-api-export: Scenarios "Release creates a pending entry", "Successful release"
        // and "Entry is never committed as Waiting to Process"
        // [GIVEN] An approved checking line for a country
        TestLibrary.CreateItem(Item);
        TestLibrary.CreateSalesPriceChecking(SalesPriceChecking, Item."No.", '', TestLibrary.CreateCountryRegion(), 1000);

        // [WHEN] Releasing it
        TestLibrary.ReleaseSalesPriceChecking(SalesPriceChecking, DataExportEntry);

        // [THEN] The line is queued, an export record with the price exists and the export entry waits as "Pending (Sales Price)"
        LibraryAssert.AreEqual(SalesPriceChecking."CXW Export Status"::Queued, SalesPriceChecking."CXW Export Status", 'Export status of the checking line');
        TestLibrary.FindSalesPriceExport(SalesPriceExport, Item."No.", SalesPriceChecking."CXW Country Code");
        LibraryAssert.AreEqual(1000, SalesPriceExport."CXW Unit Price", 'Unit price of the export record');
        LibraryAssert.AreEqual(DataExportEntry.Status::"CXW Pending", DataExportEntry.Status, 'Status of the export entry');
        LibraryAssert.AreEqual(ExportGatewaySalesPrice.GetDestinationCode(), DataExportEntry."Destination Code", 'Destination code');
        LibraryAssert.AreEqual(0, DataExportEntry."Attempt Count", 'Attempt count');
    end;

    [Test]
    procedure SourceLineWithoutCountryIsNotReleased()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPriceExport: Record "CXW Sales Price Export";
    begin
        Initialize();
        // Spec sales-price-api-export: Scenario "Source line without country is not exported"
        // [GIVEN] A source line (no country)
        TestLibrary.CreateItem(Item);
        TestLibrary.CreateSalesPriceChecking(SalesPriceChecking, Item."No.", '', '', 1000);

        // [WHEN] Releasing it
        asserterror Codeunit.Run(Codeunit::"CXW Release Sales Price Line", SalesPriceChecking);

        // [THEN] It is rejected and nothing is queued
        LibraryAssert.ExpectedError(CountryCodeMissingErr);
        SalesPriceExport.SetRange("CXW Item No.", Item."No.");
        LibraryAssert.RecordIsEmpty(SalesPriceExport);
    end;

    #endregion

    #region Transmission and logging

    [Test]
    procedure FailedAttemptIsRecordedOnEntryAndLogged()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
        HttpCallLog: Record "CXW Http Call Log";
    begin
        Initialize();
        // Spec sales-price-api-export: Scenarios "Failed transmission" and "Transmission failure is visible on the export entry"
        // Spec sales-price-export-job: Scenario "HTTP failure"
        // Spec sales-price-http-call-logging: Scenarios "Network failure is logged" / "Non-success HTTP status is logged"
        // [GIVEN] A released sales price for an endpoint that cannot be reached
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] The entry is in error after one attempt with a message, and the call is logged as failed
        DataExportEntry.Get(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual(DataExportEntry.Status::Error, DataExportEntry.Status, 'Status');
        LibraryAssert.AreEqual(1, DataExportEntry."Attempt Count", 'Attempt count');
        LibraryAssert.AreNotEqual('', DataExportEntry."Error Message", 'Error message');
        LibraryAssert.AreNotEqual(0DT, DataExportEntry."Last Attempt At", 'Last attempt at');
        LibraryAssert.IsTrue(TestLibrary.FindLastHttpCallLog(HttpCallLog, DataExportEntry."Entry No."), 'HTTP call must be logged.');
        LibraryAssert.IsFalse(HttpCallLog."CXW Success", 'Logged success');
    end;

    [Test]
    procedure ApiKeyIsRedactedInLoggedRequest()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
        HttpCallLog: Record "CXW Http Call Log";
        RequestText: Text;
    begin
        Initialize();
        // Spec sales-price-http-call-logging: Scenario "API key auth is redacted in the log"
        // [GIVEN] A released sales price for an interface with API key authentication
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] The logged request shows the Authorization header redacted and never the API key
        TestLibrary.FindLastHttpCallLog(HttpCallLog, DataExportEntry."Entry No.");
        RequestText := TestLibrary.GetLoggedRequest(HttpCallLog);
        LibraryAssert.AreNotEqual(0, StrPos(RequestText, 'Authorization: ' + RedactedTok), 'Authorization header must be redacted.');
        LibraryAssert.AreEqual(0, StrPos(RequestText, ApiKeyTok), 'API key must not be logged.');
    end;

    #endregion

    #region Payload

    [Test]
    procedure PayloadContainsAgreedKeysInOrder()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
        Payload: JsonObject;
        PayloadKey: Text;
        ActualKeys: Text;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Complete key set"
        // [GIVEN] A released sales price
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] The payload has exactly the 30 agreed keys in the agreed order
        Payload := TestLibrary.GetPayload(DataExportEntry."Entry No.");
        foreach PayloadKey in Payload.Keys() do begin
            if ActualKeys <> '' then
                ActualKeys += ',';
            ActualKeys += PayloadKey;
        end;
        LibraryAssert.AreEqual(PayloadKeysTok, ActualKeys, 'Payload keys');
    end;

    [Test]
    procedure PayloadValuesHaveAgreedTypes()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
        PayloadText: Text;
        PayloadKey: Text;
        FirstChar: Text;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Value types"
        // [GIVEN] A released sales price
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] Amounts are JSON numbers, flags are JSON booleans, everything else is a JSON string
        PayloadText := TestLibrary.GetPayloadText(DataExportEntry."Entry No.");
        foreach PayloadKey in PayloadKeysTok.Split(',') do begin
            FirstChar := GetRawValueStart(PayloadText, PayloadKey);
            case true of
                NumberKeysTok.Split(',').Contains(PayloadKey):
                    LibraryAssert.IsTrue(FirstChar in ['-', '0' .. '9'], StrSubstNo('%1 must be a JSON number.', PayloadKey));
                BooleanKeysTok.Split(',').Contains(PayloadKey):
                    LibraryAssert.IsTrue(FirstChar in ['t', 'f'], StrSubstNo('%1 must be a JSON boolean.', PayloadKey));
                else
                    LibraryAssert.AreEqual('"', FirstChar, StrSubstNo('%1 must be a JSON string.', PayloadKey));
            end;
        end;
    end;

    [Test]
    procedure EmptyDatesAndTimesAreExportedAsEmptyStrings()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        DataExportEntry: Record "Data Export Entry";
        Payload: JsonObject;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Empty date and time values"
        // [GIVEN] A released checking line without starting date, ending date, times and last modified date
        TestLibrary.CreateItem(Item);
        TestLibrary.CreateSalesPriceChecking(SalesPriceChecking, Item."No.", '', TestLibrary.CreateCountryRegion(), 1000);
        SalesPriceChecking."CXW Starting Date" := 0D;
        SalesPriceChecking.Modify(false);
        TestLibrary.ReleaseSalesPriceChecking(SalesPriceChecking, DataExportEntry);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] The date and time keys hold empty strings
        Payload := TestLibrary.GetPayload(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual('', TestLibrary.GetPayloadValue(Payload, 'startingDate').AsText(), 'startingDate');
        LibraryAssert.AreEqual('', TestLibrary.GetPayloadValue(Payload, 'endingDate').AsText(), 'endingDate');
        LibraryAssert.AreEqual('', TestLibrary.GetPayloadValue(Payload, 'startingTime').AsText(), 'startingTime');
        LibraryAssert.AreEqual('', TestLibrary.GetPayloadValue(Payload, 'endingTime').AsText(), 'endingTime');
        LibraryAssert.AreEqual('', TestLibrary.GetPayloadValue(Payload, 'lastModifiedDate').AsText(), 'lastModifiedDate');
    end;

    [Test]
    procedure SalesTypeAndIdAreFormatted()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        DataExportEntry: Record "Data Export Entry";
        Payload: JsonObject;
        Id: Text;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Sales type and id formatting"
        // [GIVEN] A released sales price (sales type All Customers)
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);
        TestLibrary.FindSalesPrice(SalesPrice, Item."No.", '');

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] salesType is "2" and id is the sales price SystemId in upper case with braces
        Payload := TestLibrary.GetPayload(DataExportEntry."Entry No.");
        Id := TestLibrary.GetPayloadValue(Payload, 'id').AsText();
        LibraryAssert.AreEqual('2', TestLibrary.GetPayloadValue(Payload, 'salesType').AsText(), 'salesType');
        LibraryAssert.AreEqual(Format(SalesPrice.SystemId), Id, 'id');
        LibraryAssert.AreEqual(UpperCase(Id), Id, 'id must be upper case.');
        LibraryAssert.IsTrue(Id.StartsWith('{') and Id.EndsWith('}'), 'id must be enclosed in braces.');
    end;

    [Test]
    procedure CountriesSharingCurrencyKeepTheirOwnPrice()
    var
        Item: Record Item;
        FirstChecking: Record "CXW Sales Price Checking";
        SecondChecking: Record "CXW Sales Price Checking";
        FirstEntry: Record "Data Export Entry";
        SecondEntry: Record "Data Export Entry";
        FirstPayload: JsonObject;
        SecondPayload: JsonObject;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenarios "Two countries sharing a currency" and "Countries sharing a currency keep their own price"
        // [GIVEN] The same item released for two countries in local currency, first with 1000, then with 1100
        TestLibrary.CreateItem(Item);
        TestLibrary.CreateSalesPriceChecking(FirstChecking, Item."No.", '', TestLibrary.CreateCountryRegion(), 1000);
        TestLibrary.ReleaseSalesPriceChecking(FirstChecking, FirstEntry);
        TestLibrary.CreateSalesPriceChecking(SecondChecking, Item."No.", '', TestLibrary.CreateCountryRegion(), 1100);
        TestLibrary.ReleaseSalesPriceChecking(SecondChecking, SecondEntry);

        // [WHEN] Exporting both entries
        ExportGatewaySalesPrice.ExportEntry(FirstEntry);
        ExportGatewaySalesPrice.ExportEntry(SecondEntry);

        // [THEN] Each payload carries its own country and price
        FirstPayload := TestLibrary.GetPayload(FirstEntry."Entry No.");
        SecondPayload := TestLibrary.GetPayload(SecondEntry."Entry No.");
        LibraryAssert.AreEqual(FirstChecking."CXW Country Code", TestLibrary.GetPayloadValue(FirstPayload, 'countryRegionCode').AsText(), 'Country of the first payload');
        LibraryAssert.AreEqual(1000, TestLibrary.GetPayloadValue(FirstPayload, 'unitPrice').AsDecimal(), 'Price of the first payload');
        LibraryAssert.AreEqual(SecondChecking."CXW Country Code", TestLibrary.GetPayloadValue(SecondPayload, 'countryRegionCode').AsText(), 'Country of the second payload');
        LibraryAssert.AreEqual(1100, TestLibrary.GetPayloadValue(SecondPayload, 'unitPrice').AsDecimal(), 'Price of the second payload');
    end;

    [Test]
    procedure OldNavNumbersAreExported()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
        Payload: JsonObject;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Old numbers maintained"
        // [GIVEN] A released sales price for an item with old item no. and old variant code
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);
        Item."Old Item No." := 'A61087';
        Item."Old Variant Code" := 'A61087-01';
        Item.Modify(false);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] The old numbers are exported
        Payload := TestLibrary.GetPayload(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual('A61087', TestLibrary.GetPayloadValue(Payload, 'itemNo').AsText(), 'itemNo');
        LibraryAssert.AreEqual('A61087-01', TestLibrary.GetPayloadValue(Payload, 'variantCode').AsText(), 'variantCode');
    end;

    [Test]
    procedure ItemNoIsExportedWithoutOldNumbers()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
        Payload: JsonObject;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "No old numbers maintained"
        // [GIVEN] A released sales price for an item without old numbers
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] The item no. is exported as item no. and as variant code
        Payload := TestLibrary.GetPayload(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual(Item."No.", TestLibrary.GetPayloadValue(Payload, 'itemNo').AsText(), 'itemNo');
        LibraryAssert.AreEqual(Item."No.", TestLibrary.GetPayloadValue(Payload, 'variantCode').AsText(), 'variantCode');
    end;

    [Test]
    procedure OnlyOldItemNoKeepsItemNoAsVariantCode()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
        Payload: JsonObject;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Only the old item number maintained"
        // [GIVEN] A released sales price for an item with old item no., but without old variant code
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);
        Item."Old Item No." := 'A61087';
        Item.Modify(false);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] itemNo is the old item no., variantCode the current item no.
        Payload := TestLibrary.GetPayload(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual('A61087', TestLibrary.GetPayloadValue(Payload, 'itemNo').AsText(), 'itemNo');
        LibraryAssert.AreEqual(Item."No.", TestLibrary.GetPayloadValue(Payload, 'variantCode').AsText(), 'variantCode');
    end;

    [Test]
    procedure DefaultReasonCodeIsCatMan()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
        Payload: JsonObject;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Default reason code"
        // [GIVEN] A released sales price with the default reason code
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] reasonCode is "CatMan"
        Payload := TestLibrary.GetPayload(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual('CatMan', TestLibrary.GetPayloadValue(Payload, 'reasonCode').AsText(), 'reasonCode');
    end;

    [Test]
    procedure ReasonCodeIsIndependentOfSessionLanguage()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        DataExportEntry: Record "Data Export Entry";
        Payload: JsonObject;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Independent of the session language"
        // [GIVEN] A released sales price with reason code Marketing
        TestLibrary.CreateItem(Item);
        TestLibrary.CreateSalesPriceChecking(SalesPriceChecking, Item."No.", '', TestLibrary.CreateCountryRegion(), 1000);
        SalesPriceChecking."CXW Reason Code" := SalesPriceChecking."CXW Reason Code"::Marketing;
        SalesPriceChecking.Modify(false);
        TestLibrary.ReleaseSalesPriceChecking(SalesPriceChecking, DataExportEntry);

        // [WHEN] Exporting the entry in a German session
        GlobalLanguage(1031);
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);
        GlobalLanguage(1033);

        // [THEN] reasonCode is the untranslated name "Marketing"
        Payload := TestLibrary.GetPayload(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual('Marketing', TestLibrary.GetPayloadValue(Payload, 'reasonCode').AsText(), 'reasonCode');
    end;

    [Test]
    procedure ProfitIsCalculatedFromNetPrice()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
        Payload: JsonObject;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Profit with VAT"
        // [GIVEN] A released price of 1190 for an item with 19 % VAT and unit cost 800
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1190, DataExportEntry);
        Item."VAT Prod. Posting Group" := TestLibrary.CreateVATPostingSetupForBlankBusGroup(19);
        Item."Unit Cost" := 800;
        Item.Modify(false);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] unitCost is 800 and profit is (1000 - 800) / 1000 = 20 %
        Payload := TestLibrary.GetPayload(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual(800, TestLibrary.GetPayloadValue(Payload, 'unitCost').AsDecimal(), 'unitCost');
        LibraryAssert.AreEqual(20, TestLibrary.GetPayloadValue(Payload, 'profit').AsDecimal(), 'profit');
    end;

    [Test]
    procedure ProfitWithoutVatSetupUsesZeroVat()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
        Payload: JsonObject;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Profit without VAT setup"
        // [GIVEN] A released price of 1000 for an item with unit cost 750 and a VAT group without VAT posting setup
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);
        Item."VAT Prod. Posting Group" := TestLibrary.NewCode20();
        Item."Unit Cost" := 750;
        Item.Modify(false);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] profit is (1000 - 750) / 1000 = 25 %
        Payload := TestLibrary.GetPayload(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual(25, TestLibrary.GetPayloadValue(Payload, 'profit').AsDecimal(), 'profit');
    end;

    [Test]
    procedure ZeroPriceGivesZeroProfit()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
        Payload: JsonObject;
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Zero price"
        // [GIVEN] A released price of 0 for an item with unit cost
        TestLibrary.CreateAndReleaseSalesPrice(Item, 0, DataExportEntry);
        Item."Unit Cost" := 750;
        Item.Modify(false);

        // [WHEN] Exporting the entry
        ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] profit is 0, no division error
        Payload := TestLibrary.GetPayload(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual(0, TestLibrary.GetPayloadValue(Payload, 'profit').AsDecimal(), 'profit');
    end;

    [Test]
    procedure MissingExportRecordRaisesError()
    var
        Item: Record Item;
        SalesPriceExport: Record "CXW Sales Price Export";
        DataExportEntry: Record "Data Export Entry";
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Export record no longer exists"
        // [GIVEN] A released sales price whose export record was deleted
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);
        TestLibrary.FindSalesPriceExport(SalesPriceExport, Item."No.", GetCountryOfEntry(DataExportEntry));
        SalesPriceExport.Delete(false);

        // [WHEN] Exporting the entry
        asserterror ExportGatewaySalesPrice.ExportEntry(DataExportEntry);

        // [THEN] The export fails with a clear message before a request is built
        LibraryAssert.ExpectedError(ExportRecordMissingErr);
    end;

    #endregion

    #region Export job

    [Test]
    procedure JobSendsPendingEntry()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
    begin
        Initialize();
        // Spec sales-price-export-job: Scenarios "Pending entries are exported" and "Mixed results in one run"
        // [GIVEN] A released sales price
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);

        // [WHEN] The export job runs
        TestLibrary.RunSalesPriceExportJob();

        // [THEN] The entry was attempted once and has its payload; the job itself did not fail
        DataExportEntry.Get(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual(1, DataExportEntry."Attempt Count", 'Attempt count');
        LibraryAssert.AreNotEqual('', TestLibrary.GetPayloadText(DataExportEntry."Entry No."), 'Payload');
    end;

    [Test]
    procedure JobRetriesFailedEntryBelowMaximum()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Retry below the maximum"
        // [GIVEN] An entry that failed twice, maximum 3 attempts
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);
        SetEntryFailed(DataExportEntry, 2);

        // [WHEN] The export job runs
        TestLibrary.RunSalesPriceExportJob();

        // [THEN] The entry is sent again (third attempt)
        DataExportEntry.Get(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual(3, DataExportEntry."Attempt Count", 'Attempt count');
    end;

    [Test]
    procedure JobSkipsEntryAtMaximum()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Maximum reached"
        // [GIVEN] An entry that failed 3 times, maximum 3 attempts
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);
        SetEntryFailed(DataExportEntry, 3);

        // [WHEN] The export job runs
        TestLibrary.RunSalesPriceExportJob();

        // [THEN] The entry is not sent again
        DataExportEntry.Get(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual(DataExportEntry.Status::Error, DataExportEntry.Status, 'Status');
        LibraryAssert.AreEqual(3, DataExportEntry."Attempt Count", 'Attempt count');
    end;

    [Test]
    procedure JobIgnoresEntriesOfOtherDestinations()
    var
        DataExportEntry: Record "Data Export Entry";
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Entries of other destinations are ignored"
        // [GIVEN] A failed export entry of another destination
        DataExportEntry.Init();
        DataExportEntry."Destination Code" := TestLibrary.NewCode20();
        DataExportEntry.Status := DataExportEntry.Status::Error;
        DataExportEntry.Insert(false);

        // [WHEN] The export job runs
        TestLibrary.RunSalesPriceExportJob();

        // [THEN] The entry is untouched
        DataExportEntry.Get(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual(DataExportEntry.Status::Error, DataExportEntry.Status, 'Status');
        LibraryAssert.AreEqual(0, DataExportEntry."Attempt Count", 'Attempt count');
    end;

    [Test]
    procedure JobDoesNothingWhenExportDeactivated()
    var
        Item: Record Item;
        DataExportEntry: Record "Data Export Entry";
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Export deactivated"
        // [GIVEN] A released sales price and the export switched off afterwards
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);
        TestLibrary.SetPriceExportActive(false);

        // [WHEN] The export job runs
        TestLibrary.RunSalesPriceExportJob();

        // [THEN] The entry keeps waiting
        DataExportEntry.Get(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual(DataExportEntry.Status::"CXW Pending", DataExportEntry.Status, 'Status');
        LibraryAssert.AreEqual(0, DataExportEntry."Attempt Count", 'Attempt count');
    end;

    [Test]
    procedure JobSetsEntryToErrorWhenSalesPriceIsMissing()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        DataExportEntry: Record "Data Export Entry";
        HttpCallLog: Record "CXW Http Call Log";
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Sales Price record missing"
        // [GIVEN] A released sales price whose "Sales Price" record was deleted
        TestLibrary.CreateAndReleaseSalesPrice(Item, 1000, DataExportEntry);
        TestLibrary.FindSalesPrice(SalesPrice, Item."No.", '');
        SalesPrice.Delete(false);

        // [WHEN] The export job runs
        TestLibrary.RunSalesPriceExportJob();

        // [THEN] The entry is in error because of the missing sales price, and no request was sent (nothing logged)
        DataExportEntry.Get(DataExportEntry."Entry No.");
        LibraryAssert.AreEqual(DataExportEntry.Status::Error, DataExportEntry.Status, 'Status');
        LibraryAssert.AreNotEqual(0, StrPos(DataExportEntry."Error Message", NoLongerExistsErr), 'Error message must name the missing sales price.');
        LibraryAssert.IsFalse(TestLibrary.FindLastHttpCallLog(HttpCallLog, DataExportEntry."Entry No."), 'No HTTP call may be logged.');
    end;

    #endregion

    #region Export settings

    [Test]
    procedure NewSetupHasDefaultExportSettings()
    var
        GenSPSetup: Record "CXW General Sales Price Setup";
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "New setup record"
        // [GIVEN] A new general sales price setup record
        // [WHEN] It is initialized
        GenSPSetup.Init();
        // [THEN] 3 attempts and archive country DE are preset
        LibraryAssert.AreEqual(3, GenSPSetup."CXW Max. Export Attempts", 'Max. export attempts');
        LibraryAssert.AreEqual('DE', GenSPSetup."CXW Archive Country Code", 'Archive country code');
    end;

    [Test]
    procedure ZeroExportAttemptsAreRejected()
    var
        GenSPSetup: Record "CXW General Sales Price Setup";
    begin
        Initialize();
        // Spec sales-price-export-job: Scenario "Invalid attempts value"
        // [GIVEN] The general sales price setup
        TestLibrary.GetSalesPriceSetup(GenSPSetup);
        // [WHEN] Entering 0 attempts
        asserterror GenSPSetup.Validate("CXW Max. Export Attempts", 0);
        // [THEN] The value is rejected
        LibraryAssert.AreNotEqual('', GetLastErrorText(), 'Entering 0 attempts must raise an error.');
    end;

    [Test]
    procedure InterfaceForOtherTableIsRejected()
    var
        GenSPSetup: Record "CXW General Sales Price Setup";
        ApiInterfaceSetup: Record "CXW API Interface Setup";
    begin
        Initialize();
        // Spec sales-price-api-export: Scenario "Configured interface targets the wrong table"
        // Spec api-interface-setup: Scenario "Source table mismatch is rejected"
        // [GIVEN] An interface for the item table
        TestLibrary.CreateApiInterface(ApiInterfaceSetup, Enum::"CXW API Auth Type"::None, Database::Item);
        TestLibrary.GetSalesPriceSetup(GenSPSetup);
        // [WHEN] Selecting it for the sales price export
        asserterror GenSPSetup.Validate("CXW API Interface Code", ApiInterfaceSetup."CXW Code");
        // [THEN] It is rejected
        LibraryAssert.ExpectedError('Source Table No.');
    end;

    #endregion

    local procedure SetEntryFailed(var DataExportEntry: Record "Data Export Entry"; AttemptCount: Integer)
    begin
        DataExportEntry.Status := DataExportEntry.Status::Error;
        DataExportEntry."Attempt Count" := AttemptCount;
        DataExportEntry.Modify(false);
    end;

    local procedure GetCountryOfEntry(DataExportEntry: Record "Data Export Entry"): Code[10]
    var
        SalesPriceExport: Record "CXW Sales Price Export";
    begin
        SalesPriceExport.Get(DataExportEntry."Source Record ID");
        exit(SalesPriceExport."CXW Country Code");
    end;

    /// <summary>
    /// First character of the raw JSON value of a key: " for strings, t/f for booleans, a digit or - for numbers.
    /// </summary>
    local procedure GetRawValueStart(PayloadText: Text; KeyName: Text): Text
    var
        KeyPos: Integer;
        KeyText: Text;
    begin
        KeyText := '"' + KeyName + '":';
        KeyPos := StrPos(PayloadText, KeyText);
        LibraryAssert.AreNotEqual(0, KeyPos, StrSubstNo('Key %1 must be in the payload.', KeyName));
        exit(CopyStr(DelChr(CopyStr(PayloadText, KeyPos + StrLen(KeyText)), '<', ' '), 1, 1));
    end;

    local procedure Initialize()
    begin
        // Compare texts in English, independent of the session language.
        GlobalLanguage(1033);
        TestLibrary.SetupSalesPriceExport(TestLibrary.CreateCountryRegion(), ApiKeyTok);
    end;
}
