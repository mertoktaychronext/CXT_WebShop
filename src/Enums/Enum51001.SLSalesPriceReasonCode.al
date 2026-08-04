// Ersetzt in NAV Table 50007 "Sales Price Checking" Feld 15 "Reason Code" und
// Table 50011 "Sales Price Archive" Feld 15 "Reason Code".
// Ursprünglich: Code[10] mit TableRelation="System Value Line"."System Code" WHERE (System Value No.=CONST(55001)/CONST(82010)).
// Table/Page "System Value Line" (vermutet ID 5105031) wurde laut Kundenvorgabe NICHT migriert;
// stattdessen wird hier direkt der bekannte, feste Wertebereich als Enum abgebildet.
enum 51001 "SL Sales Price Reason Code"
{
    Extensible = true;

    value(0; CatMan)
    {
        Caption = 'CatMan';
    }
    value(1; Purchasing)
    {
        Caption = 'Purchasing';
    }
    value(2; Marketing)
    {
        Caption = 'Marketing';
    }
}
