pageextension 51001 "SL Sales Prices" extends "Sales Prices"
{
    layout
    {
        addlast(Content)
        {
            group("SL Sales Price Details")
            {
                Caption = 'Webshop Details';

                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country/region this sales price applies to.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason for this price or price change.';
                }
                field("Recom. Retail Price incl. VAT"; Rec."Recom. Retail Price incl. VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the recommended retail price including VAT for the webshop.';
                }
                field("Strike-Price incl. VAT"; Rec."Strike-Price incl. VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the strike-through reference price (including VAT) shown in the webshop.';
                }
                field("Unit Price (LCY)"; Rec."Unit Price (LCY)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit price in local currency, used to compare against newly imported webshop prices.';
                }
                field("Unit Price (LCY) incl. VAT"; Rec."Unit Price (LCY) incl. VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit price in local currency including VAT.';
                }
                field(Remark; Rec.Remark)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an internal remark for this sales price.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a comment for this sales price.';
                }
            }
        }
    }
}
