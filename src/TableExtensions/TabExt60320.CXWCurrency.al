namespace SLChronextWebshop.SLChronextWebshop;

using Microsoft.Finance.Currency;

tableextension 60320 CXWCurrency extends Currency
{
    fields
    {
        field(60300; "CXW Sales Price Activated"; Boolean)
        {
            Caption = 'Sales Price Activated';
            DataClassification = ToBeClassified;
        }

    }
}
