// Migriert aus NAV Xmlport 50007 "Import Sales Price" (1:1, Objekt-ID umnummeriert
// wegen app.json idRanges 51000-51049). SourceTable zeigt jetzt auf "SL Sales Price Checking" (51001,
// war Table 50007), Feldnamen/-nummern unverändert.
xmlport 51000 "SL Import Sales Price"
{
    Caption = 'Import Sales Price';
    Direction = Import;
    Format = VariableText;
    TextEncoding = UTF8;

    schema
    {
        textelement(ImportSalesPrice)
        {
            tableelement(SalesPriceChecking; "SL Sales Price Checking")
            {
                XmlName = 'SalesPrice';
                SourceTableView = sorting("Item No.", "Variant Code", "Currency Code", "Country Code");

                fieldelement(ItemNo; SalesPriceChecking."Item No.")
                {
                    MinOccurs = Zero;
                }
                fieldelement(VarCode; SalesPriceChecking."Variant Code")
                {
                    MinOccurs = Zero;
                }
                fieldelement(StockPrice; SalesPriceChecking."Stock Price")
                {
                    MinOccurs = Zero;
                }
                fieldelement(StrikePrice; SalesPriceChecking."Strike Price")
                {
                }
                fieldelement(RecomRetailPrice; SalesPriceChecking."Recom. Retail Price")
                {
                }
                fieldelement(CountryCode; SalesPriceChecking."Country Code")
                {
                    MinOccurs = Zero;
                }
                fieldelement(ReasonCode; SalesPriceChecking."Reason Code")
                {
                }
                fieldelement("Comment"; SalesPriceChecking.Comment)
                {
                }

                trigger OnAfterInitRecord()
                begin
                    if g_booCaptionRow then begin
                        g_booCaptionRow := false;
                        CurrXmlPort.Skip();
                    end;
                end;

                trigger OnAfterInsertRecord()
                begin
                    // Im Original bereits vollständig auskommentiert (toter Code):
                    // 1) "Set Price for All Countries": legte für jedes Land mit "Sales Price Activated" = true
                    //    zusätzliche "SL Sales Price Checking"-Zeilen mit umgerechnetem Preis an.
                    //    Eine aktive, gleichwertige Implementierung existiert bereits in
                    //    Page 51001 "SL Sales Price Checking List", Action "Add All Countries".
                    // 2) Non-Stock-Preis-Berechnung je Kategorie (Cat 1-3) aus
                    //    "SL General Sales Price Setup". Eine aktive, gleichwertige Implementierung
                    //    existiert bereits in Page 51001, Prozedur fnCalcNonStockPrice.
                    // Beide Blöcke wurden hier bewusst NICHT reaktiviert, um doppelte bzw. voneinander
                    // abweichende Implementierungen derselben Logik zu vermeiden.
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Option';
                    Visible = false;

                    field(SetPriceForAllCountries; g_booAllCountries)
                    {
                        ApplicationArea = All;
                        Caption = 'Set Price for All Countries';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            g_booAllCountries := false;
        end;
    }

    trigger OnPreXmlPort()
    begin
        g_booCaptionRow := true;
    end;

    trigger OnPostXmlPort()
    begin
        Message('done');
    end;

    var
        g_booCaptionRow: Boolean;
        g_booAllCountries: Boolean;
}
