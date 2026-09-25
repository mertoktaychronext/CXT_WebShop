namespace SLChronextWebshop.SLChronextWebshop;

using Microsoft.Foundation.Address;

pageextension 60347 "CXW Countries/Regions" extends "Countries/Regions"

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