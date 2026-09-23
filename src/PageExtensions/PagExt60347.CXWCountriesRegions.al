pageextension 60347 "CXW Countries Regions" extends "Countries/Regions"
{
    layout
    {
        addlast(Control1)
        {
            field("CXW Webshop Delivery Time Active"; Rec."CXW Webshop Delivery Time Active")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether delivery times for this country/region are calculated and exported to the webshop.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(CXWRefreshWebshopDeliveryTimes)
            {
                ApplicationArea = All;
                Caption = 'Refresh Webshop Delivery Times';
                Image = Calculate;
                ToolTip = 'Calculates the current delivery times for all items and variants for this active country/region.';

                trigger OnAction()
                var
                    AvailabilityChangeMgt: Codeunit "CXW Availability Change Mgt";
                begin
                    Rec.TestField("CXW Webshop Delivery Time Active", true);
                    AvailabilityChangeMgt.RefreshDeliveryTimesForCountry(Rec.Code);
                    Message(DeliveryTimesRefreshedMsg, Rec.Code);
                end;
            }
        }
    }

    var
        DeliveryTimesRefreshedMsg: Label 'Webshop delivery times for country/region %1 have been refreshed.', Comment = '%1 = country/region code';
}
