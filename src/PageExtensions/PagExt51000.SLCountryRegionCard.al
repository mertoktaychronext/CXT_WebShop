pageextension 51000 "SL Country Region Card" extends "Countries/Regions"
{
    layout
    {
        addlast(Content)
        {
            group("SL Sales Price Setup")
            {
                Caption = 'Webshop Sales Price';

                field("Sales Price Currency Code"; Rec."Sales Price Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency that webshop sales prices for this country/region are maintained in.';
                }
                field("Taxation Type"; Rec."Taxation Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this country/region uses full taxation, differential taxation, or both.';
                }
                field("Delivery Time"; Rec."Delivery Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the standard delivery time in days for this country/region.';
                }
            }
        }
    }
}
