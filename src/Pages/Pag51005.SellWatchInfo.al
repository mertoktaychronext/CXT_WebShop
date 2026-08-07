page 51005 "SellWatch info"
{
    Caption = 'SellWatch info';
    PageType = CardPart;
    SourceTable = "SellWatch Vendor Info";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Brand; Rec.Brand)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the brand of the offered watch.';
                }
                field(Model; Rec.Model)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the model of the offered watch.';
                }
                field(Reference; Rec.Reference)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reference number of the offered watch.';
                }
                field(SKU; Rec.SKU)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SKU of the offered watch.';
                }
                field("Construction Year"; Rec."Construction Year")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the construction year of the offered watch.';
                }
                field("Watch Condition"; Rec."Watch Condition")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the condition of the offered watch.';
                }
                field("Paper Available"; Rec."Paper Available")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the papers for the watch are available.';
                }
                field("Box Available"; Rec."Box Available")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the original box for the watch is available.';
                }
                field("Offer Type"; Rec."Offer Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of offer (for example commission, direct, or exchange).';
                }
                field(PickupDate; Rec.PickupDate)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date the watch is scheduled to be picked up from the vendor.';
                }
            }
        }
    }
}
