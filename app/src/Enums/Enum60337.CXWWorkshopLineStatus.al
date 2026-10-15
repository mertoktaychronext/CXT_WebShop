enum 60337 "CXW Workshop Line Status"
{
    Extensible = true;

    // Wertnamen entsprechen bewusst wörtlich dem API-Vertrag mit dem Workshop
    // (z.B. Filter "status eq 'New'"), nicht nur der UI-Anzeige.
    value(0; "New")
    {
        Caption = 'New';
    }
    value(1; "WS checked")
    {
        Caption = 'WS checked';
    }
    value(2; "Processed")
    {
        Caption = 'Processed';
    }
    value(3; "Error")
    {
        Caption = 'Error';
    }
}
