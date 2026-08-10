page 60308 "CXW SellWatch info"
{
    Caption = 'SellWatch info';
    PageType = CardPart;
    SourceTable = "CXW SellWatch Vendor Info";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("CXW Brand"; Rec."CXW Brand")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the brand of the offered watch.';
                }
                field("CXW Model"; Rec."CXW Model")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the model of the offered watch.';
                }
                field("CXW Reference"; Rec."CXW Reference")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reference number of the offered watch.';
                }
                field("CXW SKU"; Rec."CXW SKU")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SKU of the offered watch.';
                }
                field("CXW Construction Year"; Rec."CXW Construction Year")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the construction year of the offered watch.';
                }
                field("CXW Watch Condition"; Rec."CXW Watch Condition")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the condition of the offered watch.';
                }
                field("CXW Paper Available"; Rec."CXW Paper Available")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the papers for the watch are available.';
                }
                field("CXW Box Available"; Rec."CXW Box Available")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the original box for the watch is available.';
                }
                field("CXW Offer Type"; Rec."CXW Offer Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of offer (for example commission, direct, or exchange).';
                }
                field("CXW PickupDate"; Rec."CXW PickupDate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date the watch is scheduled to be picked up from the vendor.';
                }
            }
        }
    }
}
