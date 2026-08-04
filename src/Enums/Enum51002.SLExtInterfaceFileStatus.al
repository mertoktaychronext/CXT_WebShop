// Neuer, schlanker Ersatz für das Status-Options-Feld auf den ISV-Tabellen
// Table 5275378 "Ext. Interface Outbound File" und Table 5275377 "Ext. Interface Inbound File"
// (EXIN-Modul, nicht 1:1 migriert - siehe Table 51004/51005).
// Werte sinngemäß aus dem Original übernommen (New,"To Process","In Process",Processed,Error,
// Notification,Canceled) - der ungenutzte Leerwert an Position 7 des Originals wurde weggelassen,
// da diese Tabellen komplette Neukonstruktionen sind.
enum 51002 "SL Ext Interface File Status"
{
    Extensible = true;

    value(0; New)
    {
        Caption = 'New';
    }
    value(1; "To Process")
    {
        Caption = 'To Process';
    }
    value(2; "In Process")
    {
        Caption = 'In Process';
    }
    value(3; Processed)
    {
        Caption = 'Processed';
    }
    value(4; Error)
    {
        Caption = 'Error';
    }
    value(5; Notification)
    {
        Caption = 'Notification';
    }
    value(6; Canceled)
    {
        Caption = 'Canceled';
    }
}
