// Migriert aus NAV Table 9 "Country/Region", Feld 80000 "Taxation Type" (Option).
// Ursprung: OptionString=[ ,Full,Diff,Both]; OptionCaptionML=[DEU=" ,Vollbesteuert,Differenzbesteuert,Beides"; ENU=" ,Full Taxation,Diffential Taxation,Both"]
// Werte 1:1 in Reihenfolge übernommen, siehe projektweite Regel "Option -> Enum".
enum 51000 "SL Taxation Type"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Full)
    {
        Caption = 'Full Taxation';
    }
    value(2; Diff)
    {
        Caption = 'Differential Taxation';
    }
    value(3; Both)
    {
        Caption = 'Both';
    }
}
