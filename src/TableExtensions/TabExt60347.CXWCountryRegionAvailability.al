tableextension 60347 "CXW Country Delivery Active" extends "Country/Region"
{
    fields
    {
        field(60346; "CXW Webshop Delivery Time Active"; Boolean)
        {
            Caption = 'Webshop Delivery Time Active';
            ToolTip = 'Specifies whether delivery times for this country/region are calculated and exported to the webshop.';
            DataClassification = CustomerContent;
        }
    }
}
