// Table Extension für die Standardtabelle "Sales Price" (7002). Diese Felder waren im NAV-Altsystem
// kundenspezifische Ergänzungen der Standardtabelle und werden von Codeunit 51000
// "SL Export Gateway Sales Price", Codeunit 51001 "SL Import Sales Prices" sowie Page 51001
// "SL Sales Price Checking List" (Prozedur fnValidate) bereits verwendet, waren bisher aber noch
// nicht als Table Extension angelegt.
// "Reason Code" ist als Enum "SL Sales Price Reason Code" angelegt (nicht Code[10]), damit die direkte
// Zuweisung aus "SL Sales Price Checking"."Reason Code" (ebenfalls dieses Enum) typkompatibel bleibt.
// "Unit Price (LCY)" wird in Page 51001 nur lesend zum Vergleich mit "Stock Price" verwendet;
// eine ursprüngliche Berechnungsvorschrift (z.B. CalcFormula/OnValidate) wurde nicht mitgeliefert.
// Als einfaches, manuell zu pflegendes Decimal-Feld angelegt - bei Bedarf in ein FlowField ändern,
// sobald die Berechnungslogik bekannt ist.
tableextension 51001 "SL Sales Price" extends "Sales Price"
{
    fields
    {
        field(51000; "Reason Code"; Enum "SL Sales Price Reason Code")
        {
            Caption = 'Reason Code';
            DataClassification = ToBeClassified;
        }
        field(51001; Comment; Text[250])
        {
            Caption = 'Comment';
            DataClassification = ToBeClassified;
        }
        field(51002; Remark; Text[150])
        {
            Caption = 'Remark';
            DataClassification = ToBeClassified;
        }
        field(51003; "Recom. Retail Price incl. VAT"; Decimal)
        {
            Caption = 'Recom. Retail Price incl. VAT';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
        field(51004; "Strike-Price incl. VAT"; Decimal)
        {
            Caption = 'Strike-Price incl. VAT';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
        field(51005; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = ToBeClassified;
            TableRelation = "Country/Region";
        }
        field(51006; "Unit Price (LCY)"; Decimal)
        {
            Caption = 'Unit Price (LCY)';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
        field(51007; "Unit Price (LCY) incl. VAT"; Decimal)
        {
            Caption = 'Unit Price (LCY) incl. VAT';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
    }
}
