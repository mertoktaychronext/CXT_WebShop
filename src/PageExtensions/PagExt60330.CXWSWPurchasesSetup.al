pageextension 60330 "CXW SW Purchases Setup" extends "Purchases & Payables Setup"
{
    layout
    {
        addlast(Content)
        {
            group("CXW SellWatch Setup")
            {
                Caption = 'SellWatch';

                field("CXW SW Item Template Code"; Rec."CXW SW Item Template Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item template used to automatically create items for incoming SellWatch offers.';
                }
                field("CXW SW Consignment Invoice Delay (Days)"; Rec."CXW SW Consignment Invoice Delay (Days)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of days between posting the sales invoice for a consignment item and automatically posting the related purchase invoice.';
                }
            }
        }
    }
}
