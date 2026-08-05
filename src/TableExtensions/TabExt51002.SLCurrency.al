namespace SLChronextWebshop.SLChronextWebshop;

using Microsoft.Finance.Currency;

tableextension 51002 SLCurrency extends Currency
{
    fields
    {
        field(51000; "Sales Price Activated"; Boolean)
        {
            Caption = 'Sales Price Activated';
            DataClassification = ToBeClassified;
        }

    }
}
