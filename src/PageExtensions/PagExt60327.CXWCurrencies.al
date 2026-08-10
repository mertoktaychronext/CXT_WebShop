namespace SLChronextWebshop.SLChronextWebshop;

using Microsoft.Finance.Currency;

pageextension 60327 CXWCurrencies extends Currencies
{
    layout
    {
        addafter("Description")
        {
            field("CXW Sales Price Activated"; Rec."CXW Sales Price Activated")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the currency is activated for webshop sales prices.';
            }
        }
    }
}
