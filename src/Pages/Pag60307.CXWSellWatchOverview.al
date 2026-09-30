page 60307 "CXW SellWatch-Overview"
{
    Caption = 'SellWatch-Overview';
    PageType = List;
    SourceTable = "CXW SellWatch Vendor Info";
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
                field("CXW Entry No"; Rec."CXW Entry No")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the unique entry number of this SellWatch vendor info record.';
                }
                field("CXW SRid"; Rec."CXW SRid")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SellWatch request ID this entry originated from.';
                    StyleExpr = ErrorStyleTxt;
                }
                field("CXW Vendor Name"; Rec."CXW Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the vendor selling the watch.';
                }
                field("CXW Email"; Rec."CXW Email")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s email address.';
                }
                field("CXW PhoneNo"; Rec."CXW PhoneNo")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s phone number.';
                }
                field("CXW Address"; Rec."CXW Address")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s address.';
                }
                field("CXW Address 2"; Rec."CXW Address 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the second line of the vendor''s address.';
                }
                field("CXW City"; Rec."CXW City")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s city.';
                }
                field("CXW Post Code"; Rec."CXW Post Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s postal code.';
                }
                field("CXW CountryCode"; Rec."CXW CountryCode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s country/region code.';
                }
                field("CXW Brand"; Rec."CXW Brand")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the brand of the offered watch.';
                }
                field("CXW PickupDate"; Rec."CXW PickupDate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date the watch is scheduled to be picked up from the vendor.';
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
                field("CXW Taxation"; Rec."CXW Taxation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the taxation scheme applied to this offer.';
                }
                field("CXW PO Number"; Rec."CXW PO Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the purchase order created for this offer.';
                }
                field("CXW VendorNo"; Rec."CXW VendorNo")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the vendor created for this offer.';
                }
                field("CXW Last Error"; Rec."CXW Last Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies why the last automatic processing of this offer failed. The offer is retried on the next run; the field is cleared once the offer has been processed successfully.';
                    StyleExpr = ErrorStyleTxt;
                }
                field("CXW Last Error DateTime"; Rec."CXW Last Error DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the last automatic processing of this offer failed.';
                }
                field("CXW Tracking Number"; Rec."CXW Tracking Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the shipment tracking number of the related purchase order.';
                }
                field("CXW Final Offer Price"; Rec."CXW Final Offer Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the final price agreed with the vendor.';
                }
                field("CXW CurrencyCode"; Rec."CXW CurrencyCode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the final offer price.';
                }
                field("CXW CXTSalesPrice"; Rec."CXW CXTSalesPrice")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sales price the watch is planned to be sold for.';
                }
                field("CXW Gender"; Rec."CXW Gender")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the gender of the vendor, as sent by SellWatch.';
                }
                field("CXW LanguageCode"; Rec."CXW LanguageCode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the language of the vendor, as sent by SellWatch.';
                }
                field("CXW NuveiAccountCode"; Rec."CXW NuveiAccountCode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Nuvei account code of the vendor, as sent by SellWatch.';
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
                    if Rec."CXW PO Number" <> '' then begin
                        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."CXW PO Number");
                        Page.RunModal(Page::"Purchase Order", PurchaseHeader);
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetFilter("CXW SRid", '<>%1', '');
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."CXW Last Error" <> '' then
            ErrorStyleTxt := 'Unfavorable'
        else
            ErrorStyleTxt := 'Standard';
    end;

    var
        ErrorStyleTxt: Text;
}
