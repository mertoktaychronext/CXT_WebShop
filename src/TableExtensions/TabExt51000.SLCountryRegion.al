// Migriert aus NAV Table 9 "Country/Region".
// Nur Felder im Kundenfeldbereich wurden berücksichtigt: 80000, 80010, 80020, 80021 (-> 51000-51003).
// Alle übrigen Custom-Felder der Quelltabelle (z.B. 5104550ff, 5105xxx) liegen außerhalb des relevanten
// Feldbereichs und wurden bewusst NICHT migriert (siehe Teilaufgabe-1-Regel "Nur Felder im Bereich
// 50000-89999 berücksichtigen"). Zugehörige Funktionen (CreateDimAndDefaultDim, CheckPostCodePostingGroups
// etc.) hängen ausschließlich an diesen nicht migrierten Feldern und wurden daher ebenfalls nicht übernommen.
tableextension 51000 "SL Country Region" extends "Country/Region"
{
    fields
    {
        // war Feld 80000 Taxation Type (Option) -> Enum, siehe projektweite Option->Enum-Regel
        field(51000; "Taxation Type"; Enum "SL Taxation Type")
        {
            Caption = 'Taxation Type';
            DataClassification = ToBeClassified;
        }
        // war Feld 80010 Delivery Time
        field(51001; "Delivery Time"; DateFormula)
        {
            Caption = 'Delivery Time (Days)';
            DataClassification = ToBeClassified;
        }
        // war Feld 80020 Sales Price Currency Code
        field(51002; "Sales Price Currency Code"; Code[10])
        {
            Caption = 'Sales Price Currency Code';
            DataClassification = ToBeClassified;
            TableRelation = Currency;
        }
        // war Feld 80021 Sales Price Activated
        field(51003; "Sales Price Activated"; Boolean)
        {
            Caption = 'Sales Price Activated';
            DataClassification = ToBeClassified;
        }
    }
}
