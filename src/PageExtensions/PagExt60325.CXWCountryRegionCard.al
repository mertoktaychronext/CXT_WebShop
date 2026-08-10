pageextension 60325 "CXW Country Region Card" extends "Countries/Regions"
{
    layout
    {
        addlast(Content)
        {
            group("SL Sales Price Setup")
            {
                Caption = 'Webshop Sales Price';

                field("CXW Sales Price Currency Code"; Rec."CXW Sales Price Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency that webshop sales prices for this country/region are maintained in.';
                }
                field("CXW Taxation Type"; Rec."CXW Taxation Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this country/region uses full taxation, differential taxation, or both.';
                }
                field("CXW Delivery Time"; Rec."CXW Delivery Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the standard delivery time in days for this country/region.';
                }
            }
        }
    }
}
