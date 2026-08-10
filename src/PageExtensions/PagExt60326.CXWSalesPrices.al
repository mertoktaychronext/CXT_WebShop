pageextension 60326 "CXW Sales Prices" extends "Sales Prices"
{
    layout
    {
        addlast(Content)
        {
            group("CXW Sales Price Details")
            {
                Caption = 'Webshop Details';

                field("CXW Reason Code"; Rec."CXW Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason for this price or price change.';
                }
                field("CXW Rec. Retail Price incl VAT"; Rec."CXW Rec. Retail Price incl VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the recommended retail price including VAT for the webshop.';
                }
                field("CXW Strike-Price incl. VAT"; Rec."CXW Strike-Price incl. VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the strike-through reference price (including VAT) shown in the webshop.';
                }
                field("CXW Unit Price (LCY)"; Rec."CXW Unit Price (LCY)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit price in local currency, used to compare against newly imported webshop prices.';
                }
                field("CXW Unit Price (LCY) incl. VAT"; Rec."CXW Unit Price (LCY) incl. VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit price in local currency including VAT.';
                }
                field("CXW Remark"; Rec."CXW Remark")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an internal remark for this sales price.';
                }
                field("CXW Comment"; Rec."CXW Comment")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a comment for this sales price.';
                }
            }
        }
    }
}
