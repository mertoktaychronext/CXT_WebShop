// Migriert aus NAV Page 50038 "Sales Price Checking List" (1:1, Objekt-ID umnummeriert
// wegen app.json idRanges 51000-51049).
//
// OFFENE PUNKTE - fehlende kundenspezifische Objekte (Phase-0-Ergebnis):
//   - Feld "Differential Taxation Purchase" auf Item Ledger Entry (Tabelle 32) - vermutlich aus einer
//     weiteren, nicht gelieferten Table Extension. Betrifft lokale Prozedur fnValidate.
// Xmlport 50007 (CSV-Import) wurde geliefert und ist als Xmlport 51000 "SL Import Sales Price"
// migriert und in Action "Import CSV" verdrahtet (siehe XmlPort51000.SLImportSalesPrice.al).
//
// Scope-Reduktion auf Kundenwunsch (nach vollständiger Migration): Nur noch "Import CSV", "Validate",
// "Approve" und "Add all Currencies" (Pro-Währung-Kopie, siehe unten) werden aktiv gebraucht. Entfernt
// wurden die Debug-Actions "UnValidate"/"TempImport"/"Clear" sowie die Actions "Upload Sales Price (DE)"
// und "Upload Sales Price (Non DE)" (inkl. der zugehörigen Differenzbesteuerungs-/CHF-Sonderregel und
// Table 51003 "SL Item Attribute Collection", die ausschließlich von der DE-Action genutzt wurde).
//
// OpenSpec-Change "add-all-currencies" (openspec/changes/add-all-currencies/): Die ursprüngliche Action
// "Add All Countries" wurde ersatzlos durch "Add all Currencies" ersetzt. Statt einer neuen Zeile pro
// aktiviertem Land entsteht jetzt genau eine Zeile pro distinkter Währung (Länder, die sich eine Währung
// teilen, erzeugen keine doppelten Zeilen mehr). Neue Zeilen haben "Country Code" = '' (gelten für alle
// Länder mit dieser Währung). Das Feld "DE Price Processed" wurde dafür in "Currencies Processed"
// umbenannt (gleiche ID/Semantik). Schleife, Guards und Feldkopie-Logik entsprechen ansonsten 1:1 der
// alten Action; einziger Unterschied ist ein Get()-Dedup-Check pro Währung vor dem Insert.
// Die Action "Upload Sales Price" (ursprünglich Codeunit 82001-Legacy-Action) bleibt bewusst als
// Platzhalter erhalten - die Funktionalität dahinter wird zu einem späteren Zeitpunkt überarbeitet.
// Codeunit 51000 "SL Export Gateway Sales Price" (war Codeunit 82001, native JsonObject statt
// DotNet Newtonsoft.Json) bleibt daher ebenfalls erhalten, ebenso Codeunit 51001
// "SL Import Sales Prices" (war Codeunit 82012, direkter CSV-Batchimport in die echte
// Sales-Price-Tabelle) - beide auf ausdrücklichen Kundenwunsch, obwohl sie nicht in Page 51001
// verankert sind bzw. hier nur noch als Platzhalter dienen.
// Alle noch offenen Stellen sind mit "// TODO:" markiert und die Original-Logik als Kommentar erhalten,
// damit nach Nachlieferung der Objekte nichts rekonstruiert werden muss.
page 51001 "SL Sales Price Checking List"
{
    Caption = 'Sales Price Checking List';
    PageType = Worksheet;
    SourceTable = "SL Sales Price Checking";

    layout
    {
        area(Content)
        {
            field(NonDEPrice; NonDEPrice)
            {
                ApplicationArea = All;
                Caption = 'Non DE Price';
                ToolTip = 'DE Price';

                trigger OnValidate()
                begin
                    g_recSalesPriceCheck.Reset();
                    if g_recSalesPriceCheck.FindFirst() then
                        Error('Clear all lines');
                end;
            }
            repeater(Group)
            {
                field(Validated; Rec.Validated)
                {
                    ApplicationArea = All;
                    Enabled = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                }
                field(FinalPrice; Rec."Stock Price")
                {
                    ApplicationArea = All;
                    Caption = 'FinalPrice';

                    trigger OnValidate()
                    begin
                        if Rec."Stock Price" <> xRec."Stock Price" then
                            Rec.Validated := false;
                    end;
                }
                field("Strike Price"; Rec."Strike Price")
                {
                    ApplicationArea = All;
                }
                field("Recom. Retail Price"; Rec."Recom. Retail Price")
                {
                    ApplicationArea = All;
                }
                field("Country Code"; Rec."Country Code")
                {
                    ApplicationArea = All;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Enabled = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Non Stock Price"; Rec."Non Stock Price")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Exchange Rate Amount"; Rec."Exchange Rate Amount")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Exchange Rate Date"; Rec."Exchange Rate Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Remark; Rec.Remark)
                {
                    ApplicationArea = All;
                    Enabled = false;
                    Editable = true;
                    Style = StandardAccent;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                }
                field(Approved; Rec."Accept New Setup")
                {
                    ApplicationArea = All;
                    Caption = 'Approved';
                }
                field(Approver; Rec."Approved By")
                {
                    ApplicationArea = All;
                    Caption = 'Approver';
                    Enabled = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Import)
            {
                Caption = 'Import';
                Image = Worksheet;

                action("Import CSV")
                {
                    ApplicationArea = All;
                    Caption = 'Import CSV';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = New;
                    PromotedIsBig = true;
                    Visible = true;

                    trigger OnAction()
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("Minimum Margin %");
                        g_recGenSPSetup.TestField("Stock Price Threshold %");

                        if Rec.FindFirst() then
                            Error(TXT009);

                        Xmlport.Run(Xmlport::"SL Import Sales Price", false, true);
                    end;
                }
                action(Validate)
                {
                    ApplicationArea = All;
                    Caption = 'Validate';
                    Image = CheckList;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("Minimum Margin %");
                        g_recGenSPSetup.TestField("Stock Price Threshold %");

                        CheckEntries(2);
                        CheckDEPrice();

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange(Validated, true);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        // Im Original bereits auskommentiert (toter Code), unverändert übernommen:
                        // g_recSalesPriceCheck.Reset();
                        // g_recSalesPriceCheck.SetFilter("Country Code", '<>%1', 'DE');
                        // if g_recSalesPriceCheck.FindFirst() then
                        //     Error('Only "DE" price is allowed');

                        Rec.TestField("Country Code");

                        // Im Original bereits auskommentiert (toter Code - erneute Berechnung Non-Stock-Preis
                        // je Kategorie), unverändert übernommen:
                        // g_recGenSPSetup.Get();
                        // g_recGenSPSetup.TestField("If Stock Price From Cat 1");
                        // g_recGenSPSetup.TestField("If Stock Price To Cat 1");
                        // g_recGenSPSetup.TestField("If Stock Price From Cat 2");
                        // g_recGenSPSetup.TestField("If Stock Price To Cat 2");
                        // g_recGenSPSetup.TestField("If Stock Price From Cat 3");
                        // g_recGenSPSetup.TestField("If Stock Price To Cat 3");
                        // g_recGenSPSetup.TestField("Cat 1 Non Stock %");
                        // g_recGenSPSetup.TestField("Cat 2 Non Stock %");
                        // g_recGenSPSetup.TestField("Cat 3 Non Stock %");
                        // fnCalcNonStockPrice(g_recGenSPSetup."If Stock Price From Cat 1", g_recGenSPSetup."If Stock Price To Cat 1", g_recGenSPSetup."Cat 1 Non Stock %");
                        // fnCalcNonStockPrice(g_recGenSPSetup."If Stock Price From Cat 2", g_recGenSPSetup."If Stock Price To Cat 2", g_recGenSPSetup."Cat 2 Non Stock %");
                        // fnCalcNonStockPrice(g_recGenSPSetup."If Stock Price From Cat 3", g_recGenSPSetup."If Stock Price To Cat 3", g_recGenSPSetup."Cat 3 Non Stock %");

                        // Im Original bereits auskommentiert (toter Code), unverändert übernommen:
                        // g_recSalesPriceCheck.Reset();
                        // g_recSalesPriceCheck.SetFilter("Country Code", '%1', 'DE');
                        // g_recSalesPriceCheck.SetRange("Currencies Processed", false);
                        // if g_recSalesPriceCheck.FindFirst() then
                        //     Error('Please click on Add All countries');

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetFilter("Stock Price", '>%1', 0);
                        if g_recSalesPriceCheck.FindSet() then
                            repeat
                                g_recSalesPriceCheck."Stock Price" := Round(g_recSalesPriceCheck."Stock Price", 10, '>');
                                if g_recSalesPriceCheck."Recom. Retail Price" > 0 then
                                    g_recSalesPriceCheck."Recom. Retail Price" := Round(g_recSalesPriceCheck."Recom. Retail Price", 10, '>');
                                if g_recSalesPriceCheck."Strike Price" > 0 then
                                    g_recSalesPriceCheck."Strike Price" := Round(g_recSalesPriceCheck."Strike Price", 10, '>');
                                if g_recSalesPriceCheck."Country Code" <> 'DE' then begin
                                    g_recCountry.Get(g_recSalesPriceCheck."Country Code");
                                    g_recCountry.TestField("Sales Price Activated", true);
                                    g_recSalesPriceCheck."Currency Code" := g_recCountry."Sales Price Currency Code";
                                end;
                                g_recSalesPriceCheck.Modify();
                            until g_recSalesPriceCheck.Next() = 0;

                        fnValidate();

                        Message('validate data is done');
                    end;
                }
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = AdjustVATExemption;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        l_recSalesPriceCheck: Record "SL Sales Price Checking";
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("Minimum Margin %");
                        g_recGenSPSetup.TestField("Stock Price Threshold %");

                        CheckEntries(3);
                        CheckDEPrice();

                        g_recSalesPriceCheck.Reset();
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange(Validated, false);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        // TODO: Ursprünglich wurde hier auf leeren "Reason Code" geprüft (SetFilter("Reason Code",'%1','')),
                        // was bei Code[10] "nicht gesetzt" bedeutete. "Reason Code" ist jetzt ein Enum ohne
                        // echten Blank-Zustand (Default-Wert = CatMan). Fachlich klären, ob CatMan als Default
                        // ausreicht oder ein zusätzlicher Enum-Wert für "nicht gesetzt" ergänzt werden soll.
                        // g_recSalesPriceCheck.Reset();
                        // g_recSalesPriceCheck.SetFilter("Reason Code", '%1', '');
                        // if g_recSalesPriceCheck.FindFirst() then
                        //     Error('Reason Code is missing');

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange("Accept New Setup", true);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        // Im Original wurde hier über eine Lookup-Page auf Tabelle "System Value Line"
                        // (Table/Page 5105031) ein Reason Code ausgewählt. Dieser gesamte Block war im
                        // NAV-Quellcode bereits vollständig auskommentiert (toter Code) und ist durch die
                        // Umstellung von "Reason Code" auf das Enum "SL Sales Price Reason Code" ohnehin
                        // hinfällig.
                        if Confirm('Are you sure want to Accept New Price Setup?', false) then begin
                            l_recSalesPriceCheck.Reset();
                            if l_recSalesPriceCheck.FindSet() then begin
                                repeat
                                    l_recSalesPriceCheck."Accept New Setup" := true;
                                    l_recSalesPriceCheck."Remark Backup" := Rec.Remark;
                                    l_recSalesPriceCheck.Remark := '';
                                    l_recSalesPriceCheck."Approved By" := UserId;
                                    l_recSalesPriceCheck.Modify();
                                until l_recSalesPriceCheck.Next() = 0;
                                Message('done');
                            end;
                        end;
                    end;
                }
                action("Add all Currencies")
                {
                    ApplicationArea = All;
                    Caption = 'Add all Currencies';
                    Enabled = not NonDEPrice;
                    Image = Add;
                    Promoted = true;
                    PromotedCategory = New;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("Minimum Margin %");
                        g_recGenSPSetup.TestField("Stock Price Threshold %");

                        g_recSalesPriceCheck.Reset();
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetFilter("Country Code", '%1', 'DE');
                        g_recSalesPriceCheck.SetRange("Currencies Processed", false);
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        CheckEntries(1);

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange(Validated, false);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange("Accept New Setup", false);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        // Im Original bereits auskommentiert (toter Code), unverändert übernommen:
                        // g_recSalesPriceCheck.Reset();
                        // g_recSalesPriceCheck.SetFilter("Country Code", '%1', 'DE');
                        // g_recSalesPriceCheck.SetRange("Currencies Processed", false);
                        // if g_recSalesPriceCheck.FindFirst() then
                        //     Error('Please click on Add All countries');

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetFilter("Country Code", '%1', 'DE');
                        g_recSalesPriceCheck.SetRange("Currencies Processed", false);
                        if g_recSalesPriceCheck.FindSet() then
                            repeat
                                g_recCountry.Reset();
                                g_recCountry.SetFilter(Code, '<>%1', 'DE');
                                g_recCountry.SetRange("Sales Price Activated", true);
                                if g_recCountry.FindSet() then
                                    repeat
                                        // Dedup pro Währung (statt pro Land): eine Zeile für diese Währung
                                        // existiert bereits (in dieser Tabelle bzw. bereits in diesem Lauf
                                        // eingefügt), oder das Land nutzt gar keine/die Quellwährung selbst -
                                        // dann überspringen. Country Code bleibt bei neuen Zeilen leer, da
                                        // die Zeile für alle Länder mit dieser Währung gilt, nicht nur für
                                        // g_recCountry.
                                        if (g_recCountry."Sales Price Currency Code" <> '') and
                                           (g_recCountry."Sales Price Currency Code" <> g_recSalesPriceCheck."Currency Code") and
                                           (not g_recSalesPriceCheck2.Get(g_recSalesPriceCheck."Item No.", g_recSalesPriceCheck."Variant Code", g_recCountry."Sales Price Currency Code", ''))
                                        then begin
                                            g_recSalesPriceCheck2.Init();
                                            g_recSalesPriceCheck2."Item No." := g_recSalesPriceCheck."Item No.";
                                            g_recSalesPriceCheck2."Variant Code" := g_recSalesPriceCheck."Variant Code";
                                            g_recSalesPriceCheck2."Country Code" := '';
                                            g_recSalesPriceCheck2."Currency Code" := g_recCountry."Sales Price Currency Code";
                                            g_recCurrExcRate.Reset();
                                            g_recCurrExcRate.SetRange("Currency Code", g_recSalesPriceCheck2."Currency Code");
                                            if g_recCurrExcRate.FindLast() then begin
                                                g_recCurrExcRate.GetLastestExchangeRate(g_recSalesPriceCheck2."Currency Code", g_dateExchangeRateDate, g_decExchangeRateAmt);
                                                g_recSalesPriceCheck2."Stock Price" := g_recSalesPriceCheck."Stock Price" * (1 / g_decExchangeRateAmt);
                                                g_recSalesPriceCheck2."Recom. Retail Price" := g_recSalesPriceCheck."Recom. Retail Price" * (1 / g_decExchangeRateAmt);
                                                g_recSalesPriceCheck2."Strike Price" := g_recSalesPriceCheck."Strike Price" * (1 / g_decExchangeRateAmt);
                                                g_recSalesPriceCheck2."Exchange Rate Amount" := 1 / g_decExchangeRateAmt;
                                                g_recSalesPriceCheck2."Exchange Rate Date" := g_dateExchangeRateDate;
                                            end;
                                            g_recSalesPriceCheck2."Starting Date" := g_recSalesPriceCheck."Starting Date";
                                            g_recSalesPriceCheck2."Starting Time" := g_recSalesPriceCheck."Starting Time";
                                            g_recSalesPriceCheck2."Ending Date" := g_recSalesPriceCheck."Ending Date";
                                            g_recSalesPriceCheck2."Ending Time" := g_recSalesPriceCheck."Ending Time";
                                            g_recSalesPriceCheck2."Reason Code" := g_recSalesPriceCheck."Reason Code";
                                            g_recSalesPriceCheck2.Comment := g_recSalesPriceCheck.Comment;
                                            g_recSalesPriceCheck2.Validated := true;
                                            g_recSalesPriceCheck2."Approved By" := g_recSalesPriceCheck."Approved By";
                                            g_recSalesPriceCheck2."Accept New Setup" := g_recSalesPriceCheck."Accept New Setup";
                                            g_recSalesPriceCheck2.Insert(true);
                                        end;
                                    until g_recCountry.Next() = 0;
                                UpdateSalesPriceCheck.Get(g_recSalesPriceCheck."Item No.", g_recSalesPriceCheck."Variant Code", g_recSalesPriceCheck."Currency Code", g_recSalesPriceCheck."Country Code");
                                UpdateSalesPriceCheck."Currencies Processed" := true;
                                UpdateSalesPriceCheck.Modify();
                            until g_recSalesPriceCheck.Next() = 0;

                        // Im Original bereits auskommentiert (toter Code - erneute Berechnung Non-Stock-Preis),
                        // unverändert übernommen: siehe Action "Validate".

                        Message('done');
                    end;
                }
            }
            group(Validation)
            {
                Caption = 'Validation';
                Image = Confirm;

                // action("Upload Sales Price")
                // {
                //     ApplicationArea = All;
                //     Caption = 'Upload Sales Price';
                //     Image = SendConfirmation;
                //     Promoted = true;
                //     PromotedCategory = Process;
                //     PromotedIsBig = true;
                //     Visible = false;

                //     trigger OnAction()
                //     var
                //         LastVersionNo: Integer;
                //     begin
                //         if UserId <> 'SGALLIPELLI' then
                //             Error('not possible');

                //         g_recGenSPSetup.Get();
                //         g_recGenSPSetup.TestField("Minimum Margin %");
                //         g_recGenSPSetup.TestField("Stock Price Threshold %");

                //         CheckEntries(4);

                //         g_recSalesPriceCheck.Reset();
                //         if not g_recSalesPriceCheck.FindFirst() then
                //             Error('Nothing to process');

                //         g_recSalesPriceCheck.Reset();
                //         g_recSalesPriceCheck.SetRange("Accept New Setup", false);
                //         if g_recSalesPriceCheck.FindFirst() then
                //             Error('Nothing to process');

                //         g_recSalesPriceCheck.Reset();
                //         g_recSalesPriceCheck.SetFilter("Country Code", '%1', 'DE');
                //         g_recSalesPriceCheck.SetRange("Currencies Processed", false);
                //         if g_recSalesPriceCheck.FindFirst() then
                //             Error('Please click on Add All countries');

                //         if not Confirm(TXT000, false) then
                //             exit;

                //         g_recSalesPriceCheck.Reset();
                //         g_recSalesPriceCheck.SetFilter(Remark, '%1', '');
                //         g_recSalesPriceCheck.SetFilter("Stock Price", '>%1', 0);
                //         g_recSalesPriceCheck.SetRange(Validated, true);
                //         g_recSalesPriceCheck.SetRange("Accept New Setup", true);
                //         if g_recSalesPriceCheck.FindSet() then begin
                //             ProgressWindow.Open('Uploading Sales Price @1@@@@@@@@@@@@@@@');
                //             TotalCount := g_recSalesPriceCheck.Count();
                //             repeat
                //                 g_recSP2.Init();
                //                 g_recSP2."Sales Type" := g_recSP2."Sales Type"::"All Customers";
                //                 g_recSP2."Sales Code" := '';
                //                 g_recSP2."Item No." := g_recSalesPriceCheck."Item No.";
                //                 g_recSP2."Variant Code" := g_recSalesPriceCheck."Variant Code";
                //                 g_recSP2."Country/Region Code" := g_recSalesPriceCheck."Country Code";
                //                 // g_recSP2."Promotion Medium No." := '';
                //                 // g_recSP2."Prom.Med.Tar.Grp.No." := '';
                //                 // g_recSP2."Set No." := '';
                //                 g_recSP2."Minimum Quantity" := 0;
                //                 g_recSP2.Validate("Currency Code", g_recSalesPriceCheck."Currency Code");
                //                 g_recSP2.Validate("Unit Price", g_recSalesPriceCheck."Stock Price");
                //                 g_recSP2."Recom. Retail Price incl. VAT" := g_recSalesPriceCheck."Recom. Retail Price";
                //                 g_recSP2."Strike-Price incl. VAT" := g_recSalesPriceCheck."Strike Price";
                //                 g_recSP2.Remark := g_recSalesPriceCheck."Remark Backup";
                //                 g_recSP2.Comment := g_recSalesPriceCheck.Comment;
                //                 g_recSP2."Reason Code" := g_recSalesPriceCheck."Reason Code";

                //                 if not g_recSP2.Insert() then
                //                     g_recSP2.Modify(true);

                //                 g_cuExportGatewaySalesPrice.CreateExternalInterfaceFile(g_recSP2);

                //                 LastVersionNo := 0;
                //                 SalesPriceArchive.Reset();
                //                 SalesPriceArchive.SetRange("Item No.", g_recSalesPriceCheck."Item No.");
                //                 SalesPriceArchive.SetRange("Variant Code", g_recSalesPriceCheck."Variant Code");
                //                 SalesPriceArchive.SetRange("Currency Code", g_recSalesPriceCheck."Currency Code");
                //                 SalesPriceArchive.SetRange("Country Code", g_recSalesPriceCheck."Country Code");
                //                 if SalesPriceArchive.FindLast() then
                //                     LastVersionNo := SalesPriceArchive."Version No." + 1
                //                 else
                //                     LastVersionNo := 1;
                //                 SalesPriceArchive.Init();
                //                 SalesPriceArchive.TransferFields(g_recSalesPriceCheck);
                //                 SalesPriceArchive."Version No." := LastVersionNo;
                //                 SalesPriceArchive.Insert(true);
                //                 g_recSalesPriceCheck.Delete();

                //                 CountToUpload += 1;
                //                 ProgressWindow.Update(1, Round(CountToUpload / TotalCount * 10000, 1));
                //             until g_recSalesPriceCheck.Next() = 0;
                //             ProgressWindow.Close();
                //             Message('done');
                //         end else
                //             Message('Press Validate button');
                //     end;
                // }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Rec."Accept New Setup" then
            Error('not possible');

        if Rec."Country Code" = 'DE' then
            if NonDEPrice then
                Error('DE price not allowed');

        CurrPage.Update();
        exit(true);
    end;

    var
        g_recSP: Record "Sales Price";
        g_recSalesPriceCheck: Record "SL Sales Price Checking";
        g_recSalesPriceCheck2: Record "SL Sales Price Checking";
        TXT000: Label 'Are you sure want to upload sales price?';
        TXT001: Label 'New Final Price %1% less than existing Final Price %2', Comment = '%1 = percent, %2 = old price';
        g_recILE: Record "Item Ledger Entry";
        g_decSPExclVAT: Decimal;
        g_decProfit: Decimal;
        g_decProfitPercent: Decimal;
        TXT003: Label 'New Final Price has %1% profit, less than %2% setup margin';
        g_recSP2: Record "Sales Price";
        SalesPriceArchive: Record "SL Sales Price Archive";
        g_recCountry: Record "Country/Region";
        TXT005: Label 'Currency Code %1 is not set for Country %2';

        TXT006: Label 'Starting Date %1 cannot be greater than Ending Date %2';
        g_recCurrExcRate: Record "Currency Exchange Rate";
        g_dateExchangeRateDate: Date;
        g_decExchangeRateAmt: Decimal;
        ProgressWindow: Dialog;
        TotalCount: Integer;
        CountToValidate: Integer;
        CountToUpload: Integer;
        TXT007: Label 'New Final Price %1% greater than existing Final Price %2';
        g_decStockPricePercentFromPrev: Decimal;
        g_decNonStockPricePercentFromPrev: Decimal;
        g_recGenSPSetup: Record "SL General Sales Price Setup";
        TXT009: Label 'Please delete existing entries to import new price';
        UpdateSalesPriceCheck: Record "SL Sales Price Checking";
        NonDEPrice: Boolean;

    local procedure fnValidate()
    begin
        g_recSalesPriceCheck.Reset();
        g_recSalesPriceCheck.SetRange(Validated, false);
        if g_recSalesPriceCheck.FindSet() then begin
            ProgressWindow.Open('Validating Sales Price @1@@@@@@@@@@@@@@@');
            TotalCount := g_recSalesPriceCheck.Count();
            repeat
                Clear(g_recSalesPriceCheck.Remark);
                Clear(g_decStockPricePercentFromPrev);
                Clear(g_decNonStockPricePercentFromPrev);

                g_recSP.Reset();
                g_recSP.SetRange("Item No.", g_recSalesPriceCheck."Item No.");
                g_recSP.SetRange("Variant Code", g_recSalesPriceCheck."Variant Code");
                g_recSP.SetRange("Currency Code", g_recSalesPriceCheck."Currency Code");
                g_recSP.SetRange("Country/Region Code", g_recSalesPriceCheck."Country Code");
                g_recSP.SetRange("Starting Date", g_recSalesPriceCheck."Starting Date");
                if g_recSP.FindFirst() then begin
                    g_recSalesPriceCheck."Old Stock Price" := g_recSP."Unit Price (LCY)";
                    if g_recSalesPriceCheck."Stock Price" < g_recSP."Unit Price (LCY)" then
                        g_recSalesPriceCheck.Remark :=
                            StrSubstNo(
                                TXT001,
                                Round(((g_recSP."Unit Price (LCY)" - g_recSalesPriceCheck."Stock Price") / g_recSP."Unit Price (LCY)") * 100, 0.01, '='),
                                g_recSP."Unit Price (LCY)");

                    g_decStockPricePercentFromPrev :=
                        Round(((g_recSalesPriceCheck."Stock Price" - g_recSP."Unit Price (LCY)") / g_recSP."Unit Price (LCY)") * 100, 0.01, '=');
                    if (g_recSalesPriceCheck."Stock Price" > g_recSP."Unit Price (LCY)") and
                       (g_decStockPricePercentFromPrev > g_recGenSPSetup."Stock Price Threshold %")
                    then
                        g_recSalesPriceCheck.Remark := StrSubstNo(TXT007, g_decStockPricePercentFromPrev, g_recSP."Unit Price (LCY)");
                end;

                g_decSPExclVAT := 0;
                g_decProfit := 0;
                g_decProfitPercent := 0;

                g_recILE.Reset();
                g_recILE.SetRange("Item No.", g_recSalesPriceCheck."Item No.");
                g_recILE.SetRange("Variant Code", g_recSalesPriceCheck."Variant Code");
                g_recILE.SetRange("Invoiced Quantity", 1);
                g_recILE.SetRange("Location Code", 'HL');
                if g_recILE.FindLast() then begin
                    g_recILE.CalcFields("Cost Amount (Actual)");
                    // TODO: Feld "Differential Taxation Purchase" auf Item Ledger Entry (Tabelle 32) ist im
                    // gelieferten Export nicht enthalten - vermutlich aus einer weiteren, nicht gelieferten
                    // Table Extension. Bitte diese Table Extension nachliefern. Bis dahin wird immer der
                    // "nicht differenzbesteuert"-Zweig verwendet (siehe Original-Logik in Kommentaren unten).
                    // if not g_recILE."Differential Taxation Purchase" then begin
                    g_decSPExclVAT := (g_recSalesPriceCheck."Stock Price" * 100) / 119;
                    g_decProfit := g_decSPExclVAT - g_recILE."Cost Amount (Actual)";
                    g_decProfitPercent := Round((g_decProfit / g_decSPExclVAT) * 100, 0.01, '=');
                    // end else begin
                    //     g_decProfit := ((g_recSalesPriceCheck."Stock Price" - g_recILE."Cost Amount (Actual)") * 100) / 119;
                    //     g_decProfitPercent := Round((g_decProfit / (g_recILE."Cost Amount (Actual)" + g_decProfit) * 100), 0.01, '=');
                    // end;
                    if g_decProfitPercent < g_recGenSPSetup."Minimum Margin %" then
                        g_recSalesPriceCheck.Remark := StrSubstNo(TXT003, g_decProfitPercent, g_recGenSPSetup."Minimum Margin %");
                end;

                g_recCountry.Reset();
                g_recCountry.SetRange(Code, g_recSalesPriceCheck."Country Code");
                g_recCountry.SetRange("Sales Price Activated", true);
                if g_recCountry.FindFirst() then
                    if g_recSalesPriceCheck."Currency Code" <> g_recCountry."Sales Price Currency Code" then
                        g_recSalesPriceCheck.Remark := StrSubstNo(TXT005, g_recSalesPriceCheck."Currency Code", g_recSalesPriceCheck."Country Code");

                if (g_recSalesPriceCheck."Starting Date" > g_recSalesPriceCheck."Ending Date") and (g_recSalesPriceCheck."Ending Date" <> 0D) then
                    g_recSalesPriceCheck.Remark := StrSubstNo(TXT006, g_recSalesPriceCheck."Starting Date", g_recSalesPriceCheck."Ending Date");

                if g_recSalesPriceCheck."Accept New Setup" then
                    g_recSalesPriceCheck.Remark := '';

                g_recSalesPriceCheck.Validated := true;

                g_recSalesPriceCheck.Modify();
                CountToValidate += 1;
                ProgressWindow.Update(1, Round(CountToValidate / TotalCount * 10000, 1));
            until g_recSalesPriceCheck.Next() = 0;
            ProgressWindow.Close();
        end;
    end;

    procedure fnCalcNonStockPrice(p_decStockPriceFrom: Decimal; p_decStockPriceTo: Decimal; p_decNonStockPercent: Decimal)
    begin
        g_recSalesPriceCheck2.Reset();
        g_recSalesPriceCheck2.SetRange("Non Stock Price", 0);
        g_recSalesPriceCheck2.SetFilter("Stock Price", '%1..%2', p_decStockPriceFrom, p_decStockPriceTo);
        if g_recSalesPriceCheck2.FindSet() then
            repeat
                if g_recSalesPriceCheck2."Currency Code" <> '' then begin
                    g_recCurrExcRate.Reset();
                    g_recCurrExcRate.SetRange("Currency Code", g_recSalesPriceCheck2."Currency Code");
                    if g_recCurrExcRate.FindLast() then begin
                        g_recCurrExcRate.GetLastestExchangeRate(g_recSalesPriceCheck2."Currency Code", g_dateExchangeRateDate, g_decExchangeRateAmt);
                        g_recSalesPriceCheck2."Non Stock Price" :=
                            ((g_recSalesPriceCheck2."Stock Price" / (1 / g_decExchangeRateAmt)) +
                             ((g_recSalesPriceCheck2."Stock Price" / (1 / g_decExchangeRateAmt)) * p_decNonStockPercent / 100)) * (1 / g_decExchangeRateAmt);
                    end;
                end else
                    g_recSalesPriceCheck2."Non Stock Price" :=
                        g_recSalesPriceCheck2."Stock Price" + (g_recSalesPriceCheck2."Stock Price" * p_decNonStockPercent / 100);
                g_recSalesPriceCheck2.Modify();
            until g_recSalesPriceCheck2.Next() = 0;
    end;

    local procedure CheckEntries(Funtion: Integer)
    begin
        // Im Original wird die gesamte Prüfung durch "IF (TRUE) THEN EXIT;" deaktiviert (Debug-Schalter).
        // Unverändert als No-Op übernommen; nachfolgender Code bleibt zur Referenz auskommentiert.
        exit;

        // if Funtion = 1 then begin
        //     g_recSalesPriceCheck.Reset();
        //     g_recSalesPriceCheck.SetRange("Accept New Setup", false);
        //     if g_recSalesPriceCheck.FindFirst() then
        //         Error('Nothing to process');
        // end;
        // if Funtion = 2 then begin
        //     g_recSalesPriceCheck.Reset();
        //     g_recSalesPriceCheck.SetRange("Accept New Setup", false);
        //     if g_recSalesPriceCheck.FindFirst() then
        //         exit;
        // end;
        // if Funtion = 3 then begin
        //     g_recSalesPriceCheck.Reset();
        //     g_recSalesPriceCheck.SetRange("Accept New Setup", false);
        //     if g_recSalesPriceCheck.FindFirst() then
        //         Error('Nothing to process');
        // end;
        // if (Funtion = 3) or (Funtion = 4) then begin
        //     g_recSalesPriceCheck.Reset();
        //     g_recSalesPriceCheck.SetFilter("Country Code", '%1', 'DE');
        //     g_recSalesPriceCheck.SetRange(Validated, false);
        //     if g_recSalesPriceCheck.FindFirst() then
        //         Error('Nothing to process');
        // end;
    end;

    local procedure CheckDEPrice()
    begin
        if NonDEPrice then begin
            g_recSalesPriceCheck.Reset();
            g_recSalesPriceCheck.SetFilter("Country Code", '%1', 'DE');
            if g_recSalesPriceCheck.FindFirst() then
                Error('DE price not allowed');
        end else begin
            g_recSalesPriceCheck.Reset();
            g_recSalesPriceCheck.SetFilter("Country Code", '<>%1', 'DE');
            if g_recSalesPriceCheck.FindFirst() then
                Error('Non DE price not allowed');
        end;
    end;
}
