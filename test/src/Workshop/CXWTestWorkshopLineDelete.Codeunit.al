namespace CHX.Webshop.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using System.TestLibraries.Utilities;

/// <summary>
/// Deleting workshop lines: only status New and Error, the purchase line can be sent again afterwards,
/// item tracking and serial no. information are kept. Deleting the purchase line still removes open workshop lines.
/// Source: openspec/changes/workshop-line-delete (spec workshop-line-delete).
/// The permission sets are checked in "CXW Test Permissions".
/// </summary>
codeunit 50405 "CXW Test Workshop Line Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        TestLibrary: Codeunit "CXW Test Library";
        DeleteNotAllowedTxt: Label 'cannot be deleted', Locked = true;

    [Test]
    procedure DeletingNewLineResetsPurchLine()
    var
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
    begin
        Initialize();
        // Spec workshop-line-delete: Scenarios "Neue Werkstattzeile löschen" and "Einkaufszeile ist danach wieder offen"
        // [GIVEN] A purchase line sent to the workshop and its workshop line with status New
        CreateSentPurchLine(PurchaseLine);
        CreateWorkshopLine(WorkshopLine, PurchaseLine, WorkshopLine."CXW Status"::"new");

        // [WHEN] Deleting the workshop line
        WorkshopLine.Delete(true);

        // [THEN] The workshop line is gone and the purchase line can be sent to the workshop again
        LibraryAssert.IsFalse(WorkshopLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No."), 'Workshop line must be deleted.');
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryAssert.IsFalse(PurchaseLine."CXW Sent to Workshop", 'Sent to Workshop');
        LibraryAssert.AreEqual('', PurchaseLine."CXW Manufacturer Serial No.", 'Manufacturer serial no.');
    end;

    [Test]
    procedure DeletingErrorLineIsAllowed()
    var
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
    begin
        Initialize();
        // Spec workshop-line-delete: Scenario "Werkstattzeile mit Fehler löschen"
        // [GIVEN] A workshop line with status Error
        CreateSentPurchLine(PurchaseLine);
        CreateWorkshopLine(WorkshopLine, PurchaseLine, WorkshopLine."CXW Status"::Error);

        // [WHEN] Deleting the workshop line
        WorkshopLine.Delete(true);

        // [THEN] The workshop line is gone and the purchase line is reset
        LibraryAssert.IsFalse(WorkshopLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No."), 'Workshop line must be deleted.');
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryAssert.IsFalse(PurchaseLine."CXW Sent to Workshop", 'Sent to Workshop');
    end;

    [Test]
    procedure DeletingCheckedLineFails()
    var
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
    begin
        Initialize();
        // Spec workshop-line-delete: Scenario "Löschen einer geprüften Zeile wird abgelehnt"
        // [GIVEN] A workshop line with status WS checked
        CreateSentPurchLine(PurchaseLine);
        CreateWorkshopLine(WorkshopLine, PurchaseLine, WorkshopLine."CXW Status"::"WS checked");
        // asserterror rolls back the whole transaction; without Commit the test data would be gone as well.
        Commit();

        // [WHEN] Deleting the workshop line
        asserterror WorkshopLine.Delete(true);

        // [THEN] An error occurs, workshop line and purchase line stay unchanged
        LibraryAssert.ExpectedError(DeleteNotAllowedTxt);
        CheckWorkshopLineAndPurchLineUnchanged(PurchaseLine);
    end;

    [Test]
    procedure DeletingProcessedLineFails()
    var
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
    begin
        Initialize();
        // Spec workshop-line-delete: Scenario "Löschen einer verarbeiteten Zeile wird abgelehnt"
        // [GIVEN] A workshop line with status Processed
        CreateSentPurchLine(PurchaseLine);
        CreateWorkshopLine(WorkshopLine, PurchaseLine, WorkshopLine."CXW Status"::"Processed");
        // asserterror rolls back the whole transaction; without Commit the test data would be gone as well.
        Commit();

        // [WHEN] Deleting the workshop line
        asserterror WorkshopLine.Delete(true);

        // [THEN] An error occurs, workshop line and purchase line stay unchanged
        LibraryAssert.ExpectedError(DeleteNotAllowedTxt);
        CheckWorkshopLineAndPurchLineUnchanged(PurchaseLine);
    end;

    [Test]
    procedure DeletingLineWithoutPurchLineSucceeds()
    var
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
    begin
        Initialize();
        // Spec workshop-line-delete: Scenario "Einkaufszeile existiert nicht mehr"
        // [GIVEN] A workshop line with status New whose purchase line no longer exists
        CreateSentPurchLine(PurchaseLine);
        CreateWorkshopLine(WorkshopLine, PurchaseLine, WorkshopLine."CXW Status"::"new");
        PurchaseLine.Delete(false);

        // [WHEN] Deleting the workshop line
        WorkshopLine.Delete(true);

        // [THEN] The workshop line is deleted without error
        LibraryAssert.IsFalse(WorkshopLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No."), 'Workshop line must be deleted.');
    end;

    [Test]
    procedure ItemTrackingAndSerialNoInformationAreKept()
    var
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
        ReservationEntry: Record "Reservation Entry";
        SerialNoInformation: Record "Serial No. Information";
        SerialNo: Code[50];
    begin
        Initialize();
        // Spec workshop-line-delete: Requirement "Artikelverfolgung und Seriennr.-Information bleiben erhalten"
        // [GIVEN] A workshop line whose purchase line has a serial no. in its item tracking and a serial no. information card
        CreateSentPurchLine(PurchaseLine);
        SerialNo := TestLibrary.NewCode20();
        CreateSerialNoTracking(PurchaseLine, SerialNo);
        CreateSerialNoInformation(SerialNoInformation, PurchaseLine, SerialNo);
        CreateWorkshopLine(WorkshopLine, PurchaseLine, WorkshopLine."CXW Status"::"new");

        // [WHEN] Deleting the workshop line
        WorkshopLine.Delete(true);

        // [THEN] The serial no. in the item tracking and the serial no. information are kept
        FilterSerialNoTracking(ReservationEntry, PurchaseLine);
        LibraryAssert.IsTrue(ReservationEntry.FindFirst(), 'Item tracking of the purchase line must be kept.');
        LibraryAssert.AreEqual(SerialNo, ReservationEntry."Serial No.", 'Serial no. in the item tracking');
        // The manufacturer serial no. on the card is a CHX.Base field the test app cannot reference; the record itself is checked.
        LibraryAssert.IsTrue(SerialNoInformation.Get(PurchaseLine."No.", PurchaseLine."Variant Code", SerialNo), 'Serial no. information must be kept.');
    end;

    [Test]
    procedure DeletingPurchLineDeletesOpenWorkshopLine()
    var
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
    begin
        Initialize();
        // Spec workshop-line-delete: cascade from the purchase line is not blocked by the status check
        // [GIVEN] A purchase line with a workshop line in status WS checked (which may not be deleted directly)
        CreateSentPurchLine(PurchaseLine);
        CreateWorkshopLine(WorkshopLine, PurchaseLine, WorkshopLine."CXW Status"::"WS checked");

        // [WHEN] Deleting the purchase line
        PurchaseLine.Delete(true);

        // [THEN] The open workshop line is deleted with it
        LibraryAssert.IsFalse(WorkshopLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No."), 'Open workshop line must be deleted with the purchase line.');
    end;

    [Test]
    procedure DeletingPurchLineKeepsProcessedWorkshopLine()
    var
        PurchaseLine: Record "Purchase Line";
        WorkshopLine: Record "CXW Workshop Line";
    begin
        Initialize();
        // Spec workshop-line-delete: processed workshop lines stay as proof when the purchase line is deleted
        // [GIVEN] A purchase line with a processed workshop line
        CreateSentPurchLine(PurchaseLine);
        CreateWorkshopLine(WorkshopLine, PurchaseLine, WorkshopLine."CXW Status"::"Processed");

        // [WHEN] Deleting the purchase line
        PurchaseLine.Delete(true);

        // [THEN] The processed workshop line is kept
        LibraryAssert.IsTrue(WorkshopLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No."), 'Processed workshop line must be kept.');
    end;

    // Purchase line as "Send to Workshop" leaves it: sent, with the manufacturer serial no.
    local procedure CreateSentPurchLine(var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        TestLibrary.CreateItem(Item);
        TestLibrary.CreatePurchaseOrder(PurchaseHeader, '');
        TestLibrary.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.");
        PurchaseLine."CXW Sent to Workshop" := true;
        PurchaseLine."CXW Manufacturer Serial No." := CopyStr(TestLibrary.NewText(), 1, MaxStrLen(PurchaseLine."CXW Manufacturer Serial No."));
        PurchaseLine.Modify(false);
    end;

    local procedure CreateWorkshopLine(var WorkshopLine: Record "CXW Workshop Line"; PurchaseLine: Record "Purchase Line"; Status: Enum "CXW Workshop Line Status")
    begin
        WorkshopLine.Init();
        WorkshopLine."CXW Document Type" := PurchaseLine."Document Type";
        WorkshopLine."CXW Document No." := PurchaseLine."Document No.";
        WorkshopLine."CXW Line No." := PurchaseLine."Line No.";
        WorkshopLine."CXW Item No." := PurchaseLine."No.";
        WorkshopLine."CXW Manufacturer Serial No." := PurchaseLine."CXW Manufacturer Serial No.";
        WorkshopLine."CXW Status" := Status;
        WorkshopLine.Insert(false);
    end;

    local procedure CheckWorkshopLineAndPurchLineUnchanged(PurchaseLine: Record "Purchase Line")
    var
        WorkshopLine: Record "CXW Workshop Line";
        CurrentPurchaseLine: Record "Purchase Line";
    begin
        LibraryAssert.IsTrue(WorkshopLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No."), 'Workshop line must be kept.');
        CurrentPurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryAssert.IsTrue(CurrentPurchaseLine."CXW Sent to Workshop", 'Sent to Workshop must stay set.');
        LibraryAssert.AreEqual(PurchaseLine."CXW Manufacturer Serial No.", CurrentPurchaseLine."CXW Manufacturer Serial No.", 'Manufacturer serial no.');
    end;

    // Minimal surplus entry as "Send to Workshop" creates it via "Create Reserv. Entry".
    local procedure CreateSerialNoTracking(PurchaseLine: Record "Purchase Line"; SerialNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
        EntryNo: Integer;
    begin
        if ReservationEntry.FindLast() then
            EntryNo := ReservationEntry."Entry No.";
        ReservationEntry.Init();
        ReservationEntry."Entry No." := EntryNo + 1;
        ReservationEntry.Positive := true;
        ReservationEntry."Item No." := PurchaseLine."No.";
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
        ReservationEntry."Source Type" := Database::"Purchase Line";
        ReservationEntry."Source Subtype" := PurchaseLine."Document Type".AsInteger();
        ReservationEntry."Source ID" := PurchaseLine."Document No.";
        ReservationEntry."Source Ref. No." := PurchaseLine."Line No.";
        ReservationEntry."Serial No." := SerialNo;
        ReservationEntry."Quantity (Base)" := 1;
        ReservationEntry.Insert();
    end;

    local procedure FilterSerialNoTracking(var ReservationEntry: Record "Reservation Entry"; PurchaseLine: Record "Purchase Line")
    begin
        ReservationEntry.SetRange("Source Type", Database::"Purchase Line");
        ReservationEntry.SetRange("Source Subtype", PurchaseLine."Document Type".AsInteger());
        ReservationEntry.SetRange("Source ID", PurchaseLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", PurchaseLine."Line No.");
    end;

    local procedure CreateSerialNoInformation(var SerialNoInformation: Record "Serial No. Information"; PurchaseLine: Record "Purchase Line"; SerialNo: Code[50])
    begin
        SerialNoInformation.Init();
        SerialNoInformation."Item No." := PurchaseLine."No.";
        SerialNoInformation."Variant Code" := PurchaseLine."Variant Code";
        SerialNoInformation."Serial No." := SerialNo;
        SerialNoInformation.Insert(false);
    end;

    local procedure Initialize()
    begin
        // Compare texts in English, independent of the session language.
        GlobalLanguage(1033);
    end;
}
