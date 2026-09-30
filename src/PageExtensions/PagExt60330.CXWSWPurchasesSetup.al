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
                    ToolTip = 'Specifies the item template used to automatically create items for incoming SellWatch offers of all offer types except commission.';
                }
                field("CXW SW Consign. Item Templ."; Rec."CXW SW Consign. Item Templ.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item template used to automatically create items for incoming SellWatch offers with offer type commission.';
                }
                field("CXW SW Consignment Invoice Delay (Days)"; Rec."CXW SW Consign.Inv.Delay(Days)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of days between posting the sales invoice for a consignment item and automatically posting the related purchase invoice.';
                }
            }
            group("CXW Workshop Setup")
            {
                Caption = 'Workshop';

                field("CXW Workshop Tenant"; Rec."CXW Workshop Tenant")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value the workshop API returns as tenant, so that the workshop can identify this company (e.g. GmbH).';
                }
            }
        }
    }
}
