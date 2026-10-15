namespace SLChronextWebshop.SLChronextWebshop;

using Microsoft.Inventory.Location;

pageextension 60348 "CXW Location Card" extends "Location Card"
{
    layout
    {
        addlast(General)
        {
            field("CXW Main Location"; Rec."CXW Main Location")
            {
                ApplicationArea = Location;
                ToolTip = 'Specifies whether this location is included in the webshop availability calculation.';
            }
        }
    }
}
