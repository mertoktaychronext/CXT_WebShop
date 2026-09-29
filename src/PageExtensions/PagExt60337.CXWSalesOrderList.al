pageextension 60337 "CXW Sales Order List" extends "Sales Order List"
{
    layout
    {
        addlast(Control1)
        {
            field("CXW Hold Order"; Rec."CXW Hold Order")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies that the order is on hold. This is for information only and does not block releasing, posting or shipping. You can only change it while the order is open.';
            }
        }
    }
}
