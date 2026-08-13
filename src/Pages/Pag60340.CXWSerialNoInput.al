page 60340 "CXW Serial No. Input"
{
    PageType = StandardDialog;
    Caption = 'Manufacturer Serial No.';

    layout
    {
        area(Content)
        {
            field(SerialNo; SerialNo)
            {
                ApplicationArea = All;
                Caption = 'Manufacturer Serial No.';
                ToolTip = 'Specifies the manufacturer serial number of the arrived item.';
                NotBlank = true;
            }
        }
    }

    actions
    {
    }

    var
        SerialNo: Text[50];

    procedure GetSerialNo(): Text[50]
    begin
        exit(SerialNo);
    end;
}
