enum 60337 "CXW Workshop Line Status"
{
    Extensible = true;

    // Wertnamen entsprechen bewusst wörtlich dem API-Vertrag mit dem Workshop
    // (z.B. Filter "status eq 'Neu'"), nicht nur der UI-Anzeige.
    value(0; "Neu")
    {
        Caption = 'Neu';
    }
    value(1; "WS geprüft")
    {
        Caption = 'WS geprüft';
    }
    value(2; "Verarbeitet")
    {
        Caption = 'Verarbeitet';
    }
}
