namespace SLChronextWebshop.SLChronextWebshop;

using Microsoft.Foundation.Address;

pageextension 60347 "CXW Countries/Regions" extends "Countries/Regions"
{
    layout
    {
        addafter(Name)
        {
            field("CXW Sales Price Activated"; Rec."CXW Sales Price Activated")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether webshop sales prices are generated for this country/region by the action Add all Countries.';
            }
            field("CXW Sales Price Currency Code"; Rec."CXW Sales Price Currency Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the currency in which webshop sales prices are generated for this country/region. Leave blank to use the local currency (LCY).';
            }
        }
    }
}
