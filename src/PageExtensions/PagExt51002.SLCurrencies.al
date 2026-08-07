namespace SLChronextWebshop.SLChronextWebshop;

using Microsoft.Finance.Currency;

pageextension 51002 SLCurrencies extends Currencies
{
    layout
    {
        addafter("Description")
        {
            field("Sales Price Activated"; Rec."Sales Price Activated")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the currency is activated for webshop sales prices.';
            }
        }
    }
}
