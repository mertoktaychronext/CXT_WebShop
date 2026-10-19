namespace CHX.Webshop.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using System.TestLibraries.Utilities;

/// <summary>
/// Data that "Send to Workshop" copies onto the workshop line (Codeunit "CXW Workshop Line Mgt."):
/// prefill of the check attributes from the item attributes and the snapshot of purchase and watch data.
/// Sources: openspec/specs/workshop-line-attribute-prefill, workshop-line-api-purchase-data.
/// The workshop line is only built in memory - the procedures under test do not read or write it.
/// </summary>
codeunit 50401 "CXW Test Workshop Line Data"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        TestLibrary: Codeunit "CXW Test Library";
        WorkshopLineMgt: Codeunit "CXW Workshop Line Mgt.";

    #region Prefill of the check attributes

    [Test]
    procedure MaintainedAttributesArePrefilled()
    var
        Item: Record Item;
        WorkshopLine: Record "CXW Workshop Line";
        ExpectedValues: array[7] of Text[250];
        AttributeIndex: Integer;
    begin
        Initialize();
        // Spec workshop-line-attribute-prefill: Scenarios "Attribute values maintained" and "Gender comes from Geschlecht"
        // [GIVEN] An item with a value for each of the 7 mapped attributes (22, 18, 23, 16, 15, 24, 20)
        TestLibrary.CreateItem(Item);
        for AttributeIndex := 1 to 7 do begin
            ExpectedValues[AttributeIndex] := TestLibrary.NewText();
            TestLibrary.SetItemAttributeValue(Item."No.", WorkshopLineMgt.GetWorkshopAttributeId(AttributeIndex), ExpectedValues[AttributeIndex]);
        end;
        WorkshopLine."CXW Item No." := Item."No.";

        // [WHEN] Prefilling the workshop line
        WorkshopLineMgt.PrefillEmptyWorkshopAttributes(WorkshopLine);

        // [THEN] Every mapped field holds the item's value, gender comes from attribute 24 (Geschlecht)
        LibraryAssert.AreEqual(ExpectedValues[1], WorkshopLine."CXW Dial Color", 'Dial color (attribute 22)');
        LibraryAssert.AreEqual(ExpectedValues[2], WorkshopLine."CXW Case Diameter", 'Case diameter (attribute 18)');
        LibraryAssert.AreEqual(ExpectedValues[3], WorkshopLine."CXW Bracelet Material", 'Bracelet material (attribute 23)');
        LibraryAssert.AreEqual(ExpectedValues[4], WorkshopLine."CXW Case Material", 'Case material (attribute 16)');
        LibraryAssert.AreEqual(ExpectedValues[5], WorkshopLine."CXW Movement", 'Movement (attribute 15)');
        LibraryAssert.AreEqual(ExpectedValues[6], WorkshopLine."CXW Gender", 'Gender (attribute 24)');
        LibraryAssert.AreEqual(ExpectedValues[7], WorkshopLine."CXW Crystal", 'Crystal (attribute 20)');
    end;

    [Test]
    procedure AttributeNotMaintainedLeavesFieldEmpty()
    var
        Item: Record Item;
        WorkshopLine: Record "CXW Workshop Line";
    begin
        Initialize();
        // Spec workshop-line-attribute-prefill: Scenario "Attribute not maintained"
        // [GIVEN] An item with a dial color, but without case diameter
        TestLibrary.CreateItem(Item);
        TestLibrary.SetItemAttributeValue(Item."No.", 22, TestLibrary.NewText());
        WorkshopLine."CXW Item No." := Item."No.";

        // [WHEN] Prefilling the workshop line
        WorkshopLineMgt.PrefillEmptyWorkshopAttributes(WorkshopLine);

        // [THEN] The case diameter stays empty
        LibraryAssert.AreNotEqual('', WorkshopLine."CXW Dial Color", 'Dial color must be prefilled.');
        LibraryAssert.AreEqual('', WorkshopLine."CXW Case Diameter", 'Case diameter must stay empty.');
    end;

    [Test]
    procedure PlaceholderFieldsStayEmpty()
    var
        Item: Record Item;
        WorkshopLine: Record "CXW Workshop Line";
        AttributeIndex: Integer;
    begin
        Initialize();
        // Spec workshop-line-attribute-prefill: Scenario "Placeholders stay empty"
        // [GIVEN] An item with all mapped attributes maintained
        TestLibrary.CreateItem(Item);
        for AttributeIndex := 1 to 7 do
            TestLibrary.SetItemAttributeValue(Item."No.", WorkshopLineMgt.GetWorkshopAttributeId(AttributeIndex), TestLibrary.NewText());
        WorkshopLine."CXW Item No." := Item."No.";

        // [WHEN] Prefilling the workshop line
        WorkshopLineMgt.PrefillEmptyWorkshopAttributes(WorkshopLine);

        // [THEN] Features, attribute 9 and attribute 10 have no attribute ID and stay empty
        for AttributeIndex := 8 to 10 do
            LibraryAssert.AreEqual(0, WorkshopLineMgt.GetWorkshopAttributeId(AttributeIndex), StrSubstNo('Attribute ID of placeholder %1', AttributeIndex));
        LibraryAssert.AreEqual('', WorkshopLine."CXW Features", 'Features');
        LibraryAssert.AreEqual('', WorkshopLine."CXW Attribute 9", 'Attribute 9');
        LibraryAssert.AreEqual('', WorkshopLine."CXW Attribute 10", 'Attribute 10');
    end;

    [Test]
    procedure ReportedValueIsNotOverwrittenByPrefill()
    var
        Item: Record Item;
        WorkshopLine: Record "CXW Workshop Line";
        ReportedValue: Text[250];
    begin
        Initialize();
        // Spec workshop-line-attribute-prefill: Scenario "Existing values and checked lines stay unchanged"
        // [GIVEN] A workshop line with a dial color already reported, and an item with a different dial color
        TestLibrary.CreateItem(Item);
        TestLibrary.SetItemAttributeValue(Item."No.", 22, TestLibrary.NewText());
        ReportedValue := TestLibrary.NewText();
        WorkshopLine."CXW Item No." := Item."No.";
        WorkshopLine."CXW Dial Color" := ReportedValue;

        // [WHEN] Prefilling the workshop line
        WorkshopLineMgt.PrefillEmptyWorkshopAttributes(WorkshopLine);

        // [THEN] The reported value is kept
        LibraryAssert.AreEqual(ReportedValue, WorkshopLine."CXW Dial Color", 'Reported dial color must not be overwritten.');
    end;

    #endregion

    #region Purchase and watch data for the workshop API

    [Test]
    procedure PurchaseAndWatchDataAreCopiedToWorkshopLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
        Brand: Text[250];
        Model: Text[250];
        SubModel: Text[250];
        Reference: Text[250];
        Condition: Text[250];
        Box: Text[250];
        Certificate: Text[250];
    begin
        Initialize();
        // Spec workshop-line-api-purchase-data: Scenarios "Purchase data in the API response" and "Watch data available"
        // [GIVEN] A purchase order in a foreign currency for a used watch with all watch attributes maintained
        TestLibrary.CreateItem(Item);
        Brand := SetAttribute(Item."No.", 1);
        Model := SetAttribute(Item."No.", 2);
        SubModel := SetAttribute(Item."No.", 3);
        Reference := SetAttribute(Item."No.", 5);
        TestLibrary.SetItemAttributeValue(Item."No.", 8, '2015');
        Condition := SetAttribute(Item."No.", 10);
        Box := SetAttribute(Item."No.", 11);
        Certificate := SetAttribute(Item."No.", 13);

        TestLibrary.CreatePurchaseOrder(PurchaseHeader, TestLibrary.CreateCurrency());
        TestLibrary.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.");
        PurchaseLine."Variant Code" := TestLibrary.NewCode10();
        PurchaseLine."Direct Unit Cost" := 4711.5;
        PurchaseLine."Used Good" := true;

        // [WHEN] Copying the purchase data onto the workshop line
        WorkshopLineMgt.FillPurchaseData(WorkshopLine, PurchaseLine);

        // [THEN] Order, vendor, line and watch data are on the workshop line
        LibraryAssert.AreEqual(PurchaseHeader."Vendor Order No.", WorkshopLine."CXW Vendor Order No.", 'Vendor order no.');
        LibraryAssert.AreEqual(PurchaseHeader."Buy-from Vendor No.", WorkshopLine."CXW Vendor No.", 'Vendor no.');
        LibraryAssert.AreEqual(PurchaseHeader."Buy-from Vendor Name", WorkshopLine."CXW Vendor Name", 'Vendor name');
        LibraryAssert.AreEqual(PurchaseHeader."Currency Code", WorkshopLine."CXW Currency Code", 'Currency code');
        LibraryAssert.AreEqual(PurchaseLine."Variant Code", WorkshopLine."CXW Variant Code", 'Variant code');
        LibraryAssert.AreEqual(PurchaseLine.Description, WorkshopLine."CXW Description", 'Description');
        LibraryAssert.AreEqual(1, WorkshopLine."CXW Quantity", 'Quantity');
        LibraryAssert.AreEqual(4711.5, WorkshopLine."CXW Unit Price", 'Unit price');
        LibraryAssert.IsTrue(WorkshopLine."CXW Used Goods", 'Used goods');
        LibraryAssert.AreEqual(Brand, WorkshopLine."CXW Brand", 'Brand (attribute 1)');
        LibraryAssert.AreEqual(Model, WorkshopLine."CXW Model", 'Model (attribute 2)');
        LibraryAssert.AreEqual(SubModel, WorkshopLine."CXW Sub Model", 'Sub model (attribute 3)');
        LibraryAssert.AreEqual(Reference, WorkshopLine."CXW Reference", 'Reference (attribute 5)');
        LibraryAssert.AreEqual(2015, WorkshopLine."CXW Year", 'Year (attribute 8)');
        LibraryAssert.AreEqual(Condition, WorkshopLine."CXW Condition", 'Condition (attribute 10)');
        LibraryAssert.AreEqual(Box, WorkshopLine."CXW Box", 'Box (attribute 11)');
        LibraryAssert.AreEqual(Certificate, WorkshopLine."CXW Certificate", 'Certificate (attribute 13)');
    end;

    [Test]
    procedure LocalCurrencyOrderSendsLocalCurrencyCode()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Initialize();
        // Spec workshop-line-api-purchase-data: Scenario "Purchase order in local currency"
        // [GIVEN] A purchase order without currency code
        TestLibrary.CreateItem(Item);
        TestLibrary.CreatePurchaseOrder(PurchaseHeader, '');
        TestLibrary.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.");

        // [WHEN] Copying the purchase data onto the workshop line
        WorkshopLineMgt.FillPurchaseData(WorkshopLine, PurchaseLine);

        // [THEN] The workshop gets the local currency code
        GeneralLedgerSetup.Get();
        LibraryAssert.AreEqual(GeneralLedgerSetup."LCY Code", WorkshopLine."CXW Currency Code", 'Currency code of a local currency order');
    end;

    [Test]
    procedure NonNumericYearIsSentAsZero()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
    begin
        Initialize();
        // Spec workshop-line-api-purchase-data: Scenario "Year is not a number"
        // [GIVEN] A watch whose year attribute holds a range
        TestLibrary.CreateItem(Item);
        TestLibrary.SetItemAttributeValue(Item."No.", 8, '1990-1995');
        TestLibrary.CreatePurchaseOrder(PurchaseHeader, '');
        TestLibrary.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.");

        // [WHEN] Copying the purchase data onto the workshop line
        WorkshopLineMgt.FillPurchaseData(WorkshopLine, PurchaseLine);

        // [THEN] The year is 0 and no error occurs
        LibraryAssert.AreEqual(0, WorkshopLine."CXW Year", 'Year of a non-numeric attribute value');
    end;

    [Test]
    procedure MissingWatchDataLeavesFieldsEmpty()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
    begin
        Initialize();
        // Spec workshop-line-api-purchase-data: Scenario "No watch data maintained"
        // [GIVEN] A watch without any attributes
        TestLibrary.CreateItem(Item);
        TestLibrary.CreatePurchaseOrder(PurchaseHeader, '');
        TestLibrary.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.");

        // [WHEN] Copying the purchase data onto the workshop line
        WorkshopLineMgt.FillPurchaseData(WorkshopLine, PurchaseLine);

        // [THEN] The watch fields are empty, the year is 0
        LibraryAssert.AreEqual('', WorkshopLine."CXW Brand", 'Brand');
        LibraryAssert.AreEqual('', WorkshopLine."CXW Model", 'Model');
        LibraryAssert.AreEqual('', WorkshopLine."CXW Reference", 'Reference');
        LibraryAssert.AreEqual('', WorkshopLine."CXW Certificate", 'Certificate');
        LibraryAssert.AreEqual(0, WorkshopLine."CXW Year", 'Year');
    end;

    #endregion

    local procedure SetAttribute(ItemNo: Code[20]; AttributeId: Integer) Value: Text[250]
    begin
        Value := TestLibrary.NewText();
        TestLibrary.SetItemAttributeValue(ItemNo, AttributeId, Value);
    end;

    local procedure Initialize()
    begin
        // Compare texts in English, independent of the session language.
        GlobalLanguage(1033);
    end;
}
