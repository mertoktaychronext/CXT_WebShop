namespace CHX.Webshop.Test;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Pricing;
using System.TestLibraries.Utilities;

/// <summary>
/// Write-back of a released checking line into the standard "Sales Price" table and the archive snapshot
/// (Codeunit "CXW Export Gateway Sales Price".WriteBackAndArchive).
/// Source: openspec/specs/sales-price-checking-writeback.
/// </summary>
codeunit 50402 "CXW Test Sales Price WriteBack"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        TestLibrary: Codeunit "CXW Test Library";
        ExportGatewaySalesPrice: Codeunit "CXW Export Gateway Sales Price";
        ArchiveCountryMissingErr: Label 'Archive Country Code must have a value', Locked = true;

    #region Write-back into "Sales Price"

    [Test]
    procedure NewSalesPriceIsCreatedForAllCustomers()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();
        // Spec sales-price-checking-writeback: Scenarios "No matching Sales Price record exists yet",
        // "Sales Type is always All Customers" and "Stock Price maps to the standard Unit Price field"
        // [GIVEN] An approved checking line for an item without sales price
        CreateCheckingLine(SalesPriceChecking, Item, '', TestLibrary.CreateCountryRegion(), 1250);

        // [WHEN] Writing it back
        ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);

        // [THEN] A sales price for all customers exists with the stock price as unit price
        LibraryAssert.IsTrue(TestLibrary.FindSalesPrice(SalesPrice, Item."No.", ''), 'Sales price must be created.');
        LibraryAssert.AreEqual(SalesPrice."Sales Type"::"All Customers", SalesPrice."Sales Type", 'Sales type');
        LibraryAssert.AreEqual('', SalesPrice."Sales Code", 'Sales code');
        LibraryAssert.AreEqual(1250, SalesPrice."Unit Price", 'Unit price');
    end;

    [Test]
    procedure ExistingSalesPriceIsUpdated()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();
        // Spec sales-price-checking-writeback: Scenario "A matching Sales Price record already exists"
        // [GIVEN] An item with a sales price of 1000 and a checking line with a stock price of 1100
        CreateCheckingLine(SalesPriceChecking, Item, '', TestLibrary.CreateCountryRegion(), 1000);
        ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);
        SalesPriceChecking."CXW Stock Price" := 1100;
        SalesPriceChecking.Modify(false);
        Clear(SalesPrice);

        // [WHEN] Writing it back again
        ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);

        // [THEN] The existing sales price is updated, no second one is created
        SalesPrice.SetRange("Item No.", Item."No.");
        LibraryAssert.RecordCount(SalesPrice, 1);
        SalesPrice.FindFirst();
        LibraryAssert.AreEqual(1100, SalesPrice."Unit Price", 'Updated unit price');
    end;

    [Test]
    procedure UnitPriceLcyEqualsUnitPriceForLocalCurrency()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();
        // Spec sales-price-checking-writeback: Scenario "Blank Currency Code - direct copy"
        // [GIVEN] A checking line in local currency
        CreateCheckingLine(SalesPriceChecking, Item, '', TestLibrary.CreateCountryRegion(), 990);

        // [WHEN] Writing it back
        ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);

        // [THEN] Unit price (LCY) equals the unit price
        TestLibrary.FindSalesPrice(SalesPrice, Item."No.", '');
        LibraryAssert.AreEqual(990, SalesPrice."CXW Unit Price (LCY)", 'Unit price (LCY)');
    end;

    [Test]
    procedure UnitPriceLcyUsesCapturedExchangeRate()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPrice: Record "Sales Price";
        CurrencyCode: Code[10];
    begin
        Initialize();
        // Spec sales-price-checking-writeback: Scenario "Foreign currency line with a captured exchange rate"
        // [GIVEN] A currency with a current exchange rate of 1 : 1 (must not be used)
        CurrencyCode := TestLibrary.CreateCurrency();
        TestLibrary.CreateExchangeRate(CurrencyCode, Today(), 1, 1);
        // [GIVEN] A checking line of 1100 in that currency with a captured rate of 1.1 currency units per local currency unit
        CreateCheckingLine(SalesPriceChecking, Item, CurrencyCode, TestLibrary.CreateCountryRegion(), 1100);
        SalesPriceChecking."CXW Exchange Rate Amount" := 1.1;
        SalesPriceChecking.Modify(false);

        // [WHEN] Writing it back
        ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);

        // [THEN] Unit price (LCY) is converted with the captured rate
        TestLibrary.FindSalesPrice(SalesPrice, Item."No.", CurrencyCode);
        LibraryAssert.AreEqual(1000, SalesPrice."CXW Unit Price (LCY)", 'Unit price (LCY) with captured rate');
    end;

    [Test]
    procedure UnitPriceLcyFallsBackToLatestExchangeRate()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPrice: Record "Sales Price";
        CurrencyCode: Code[10];
    begin
        Initialize();
        // Spec sales-price-checking-writeback: Scenario "Foreign currency line without a captured exchange rate"
        // [GIVEN] A currency with an old rate of 1 : 1 and a latest rate of 100 currency units = 50 local currency units
        CurrencyCode := TestLibrary.CreateCurrency();
        TestLibrary.CreateExchangeRate(CurrencyCode, CalcDate('<-1Y>', Today()), 1, 1);
        TestLibrary.CreateExchangeRate(CurrencyCode, Today(), 100, 50);
        // [GIVEN] A checking line of 2000 in that currency without captured rate (imported via CSV)
        CreateCheckingLine(SalesPriceChecking, Item, CurrencyCode, TestLibrary.CreateCountryRegion(), 2000);

        // [WHEN] Writing it back
        ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);

        // [THEN] Unit price (LCY) is converted with the latest rate: 2000 * 50 / 100 = 1000
        TestLibrary.FindSalesPrice(SalesPrice, Item."No.", CurrencyCode);
        LibraryAssert.AreEqual(1000, SalesPrice."CXW Unit Price (LCY)", 'Unit price (LCY) with latest exchange rate');
    end;

    [Test]
    procedure UnitPriceLcyIsZeroWithoutExchangeRate()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPrice: Record "Sales Price";
        CurrencyCode: Code[10];
    begin
        Initialize();
        // Spec sales-price-checking-writeback: Scenario "No exchange rate can be found"
        // [GIVEN] A currency without exchange rates and a checking line in that currency
        CurrencyCode := TestLibrary.CreateCurrency();
        CreateCheckingLine(SalesPriceChecking, Item, CurrencyCode, TestLibrary.CreateCountryRegion(), 2000);

        // [WHEN] Writing it back
        ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);

        // [THEN] The sales price is written with unit price (LCY) 0, no error
        LibraryAssert.IsTrue(TestLibrary.FindSalesPrice(SalesPrice, Item."No.", CurrencyCode), 'Sales price must be written.');
        LibraryAssert.AreEqual(0, SalesPrice."CXW Unit Price (LCY)", 'Unit price (LCY) without exchange rate');
    end;

    #endregion

    #region Archive

    [Test]
    procedure ArchiveCountryLineIsArchivedAsFirstVersion()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPriceArchive: Record "CXW Sales Price Archive";
        SalesPrice: Record "Sales Price";
        ArchiveCountryCode: Code[10];
    begin
        Initialize();
        // Spec sales-price-checking-writeback: Scenarios "Archive country line is archived", "First archive entry for a combination"
        // and "Archive row reflects checking line data"
        // [GIVEN] A checking line for the archive country with reason code and comment
        ArchiveCountryCode := TestLibrary.CreateCountryRegion();
        TestLibrary.SetArchiveCountry(ArchiveCountryCode);
        CreateCheckingLine(SalesPriceChecking, Item, '', ArchiveCountryCode, 1500);
        SalesPriceChecking."CXW Reason Code" := SalesPriceChecking."CXW Reason Code"::Marketing;
        SalesPriceChecking."CXW Comment" := TestLibrary.NewText();
        SalesPriceChecking.Modify(false);

        // [WHEN] Writing it back
        ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);

        // [THEN] Exactly one archive row with version 1 and the data of the checking line exists
        FilterArchive(SalesPriceArchive, SalesPriceChecking);
        LibraryAssert.RecordCount(SalesPriceArchive, 1);
        SalesPriceArchive.FindFirst();
        LibraryAssert.AreEqual(1, SalesPriceArchive."CXW Version No.", 'Version no.');
        LibraryAssert.AreEqual(1500, SalesPriceArchive."CXW Stock Price", 'Archived stock price');
        LibraryAssert.AreEqual(SalesPriceChecking."CXW Reason Code", SalesPriceArchive."CXW Reason Code", 'Archived reason code');
        LibraryAssert.AreEqual(SalesPriceChecking."CXW Comment", SalesPriceArchive."CXW Comment", 'Archived comment');
    end;

    [Test]
    procedure NextArchiveEntryGetsNextVersionNo()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPriceArchive: Record "CXW Sales Price Archive";
        SalesPrice: Record "Sales Price";
        ArchiveCountryCode: Code[10];
    begin
        Initialize();
        // Spec sales-price-checking-writeback: Scenarios "Subsequent archive entry for a combination"
        // and "Releasing an already-queued line again"
        // [GIVEN] A checking line for the archive country that was already written back once
        ArchiveCountryCode := TestLibrary.CreateCountryRegion();
        TestLibrary.SetArchiveCountry(ArchiveCountryCode);
        CreateCheckingLine(SalesPriceChecking, Item, '', ArchiveCountryCode, 1500);
        ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);

        // [WHEN] Writing it back again
        ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);

        // [THEN] A second archive row with version 2 exists
        FilterArchive(SalesPriceArchive, SalesPriceChecking);
        LibraryAssert.RecordCount(SalesPriceArchive, 2);
        SalesPriceArchive.FindLast();
        LibraryAssert.AreEqual(2, SalesPriceArchive."CXW Version No.", 'Version no. of the second archive row');
    end;

    [Test]
    procedure OtherCountryLineIsNotArchived()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPriceArchive: Record "CXW Sales Price Archive";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();
        // Spec sales-price-checking-writeback: Scenario "Other country line is not archived"
        // [GIVEN] An archive country and a checking line for another country
        TestLibrary.SetArchiveCountry(TestLibrary.CreateCountryRegion());
        CreateCheckingLine(SalesPriceChecking, Item, '', TestLibrary.CreateCountryRegion(), 1500);

        // [WHEN] Writing it back
        ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);

        // [THEN] No archive row is created
        SalesPriceArchive.SetRange("CXW Item No.", Item."No.");
        LibraryAssert.RecordIsEmpty(SalesPriceArchive);
    end;

    [Test]
    procedure WriteBackFailsWithoutArchiveCountry()
    var
        Item: Record Item;
        SalesPriceChecking: Record "CXW Sales Price Checking";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();
        // Spec sales-price-checking-writeback: Scenario "Archive country not configured"
        // (the action checks this before the first line; the write-back itself must not archive silently either)
        // [GIVEN] A checking line and no archive country in the setup
        CreateCheckingLine(SalesPriceChecking, Item, '', TestLibrary.CreateCountryRegion(), 1500);
        TestLibrary.SetArchiveCountry('');

        // [WHEN] Writing back a checking line
        asserterror ExportGatewaySalesPrice.WriteBackAndArchive(SalesPriceChecking, SalesPrice);

        // [THEN] It stops with an error
        LibraryAssert.ExpectedError(ArchiveCountryMissingErr);
    end;

    #endregion

    local procedure CreateCheckingLine(var SalesPriceChecking: Record "CXW Sales Price Checking"; var Item: Record Item; CurrencyCode: Code[10]; CountryCode: Code[10]; StockPrice: Decimal)
    var
        GenSPSetup: Record "CXW General Sales Price Setup";
    begin
        // The write-back needs an archive country; tests that check the archive set their own.
        TestLibrary.GetSalesPriceSetup(GenSPSetup);
        if GenSPSetup."CXW Archive Country Code" = '' then
            TestLibrary.SetArchiveCountry(TestLibrary.CreateCountryRegion());
        TestLibrary.CreateItem(Item);
        TestLibrary.CreateSalesPriceChecking(SalesPriceChecking, Item."No.", CurrencyCode, CountryCode, StockPrice);
    end;

    local procedure FilterArchive(var SalesPriceArchive: Record "CXW Sales Price Archive"; SalesPriceChecking: Record "CXW Sales Price Checking")
    begin
        SalesPriceArchive.SetRange("CXW Item No.", SalesPriceChecking."CXW Item No.");
        SalesPriceArchive.SetRange("CXW Currency Code", SalesPriceChecking."CXW Currency Code");
        SalesPriceArchive.SetRange("CXW Country Code", SalesPriceChecking."CXW Country Code");
    end;

    local procedure Initialize()
    begin
        // Compare texts in English, independent of the session language.
        GlobalLanguage(1033);
    end;
}
