page 51004 "SellWatch-Overview"
{
    Caption = 'SellWatch-Overview';
    PageType = List;
    SourceTable = "SellWatch Vendor Info";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No"; Rec."Entry No")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the unique entry number of this SellWatch vendor info record.';
                }
                field(SRid; Rec.SRid)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SellWatch request ID this entry originated from.';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the vendor selling the watch.';
                }
                field(Email; Rec.Email)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s email address.';
                }
                field(PhoneNo; Rec.PhoneNo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s phone number.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s address.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the second line of the vendor''s address.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s city.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s postal code.';
                }
                field(CountryCode; Rec.CountryCode)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s country/region code.';
                }
                field(Brand; Rec.Brand)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the brand of the offered watch.';
                }
                field(PickupDate; Rec.PickupDate)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date the watch is scheduled to be picked up from the vendor.';
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
                field(Taxation; Rec.Taxation)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the taxation scheme applied to this offer.';
                }
                field("PO Number"; Rec."PO Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the purchase order created for this offer.';
                }
                field(VendorNo; Rec.VendorNo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the vendor created for this offer.';
                }
                field("Tracking Number"; Rec."Tracking Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the shipment tracking number of the related purchase order.';
                }
                field("Final Offer Price"; Rec."Final Offer Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the final price agreed with the vendor.';
                }
                field(CurrencyCode; Rec.CurrencyCode)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the final offer price.';
                }
                field(CXTSalesPrice; Rec.CXTSalesPrice)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sales price the watch is planned to be sold for.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowDocument)
            {
                Caption = 'Show Document';
                ApplicationArea = All;
                Image = BinContent;
                Promoted = true;
                PromotedIsBig = false;
                PromotedCategory = Process;
                ToolTip = 'Open the purchase order created for this offer.';

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                begin
                    if Rec."PO Number" <> '' then begin
                        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."PO Number");
                        Page.RunModal(Page::"Purchase Order", PurchaseHeader);
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetFilter(SRid, '<>%1', '');
    end;
}
