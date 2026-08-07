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
