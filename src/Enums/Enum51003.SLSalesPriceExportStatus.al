enum 51003 "SL Sales Price Export Status"
{
    Extensible = true;

    value(0; "Not Sent")
    {
        Caption = 'Not Sent';
    }
    value(1; Sent)
    {
        Caption = 'Sent';
    }
    value(2; Error)
    {
        Caption = 'Error';
    }
}
