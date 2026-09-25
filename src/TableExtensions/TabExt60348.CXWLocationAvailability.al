namespace SLChronextWebshop.SLChronextWebshop;

using Microsoft.Inventory.Location;

tableextension 60348 "CXW Location Availability" extends Location
{
    fields
    {
        field(60347; "CXW Main Location"; Boolean)
        {
            Caption = 'Main Location';
            ToolTip = 'Specifies whether this location is included in the webshop availability calculation.';
            DataClassification = CustomerContent;
        }
    }
}
