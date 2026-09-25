namespace SLChronextWebshop.SLChronextWebshop;

using Microsoft.Foundation.Address;
using Microsoft.Finance.Currency;

tableextension 60346 "CXW Country/Region" extends "Country/Region"
{
    fields
    {
        field(60300; "CXW Sales Price Activated"; Boolean)
        {
            Caption = 'Sales Price Activated';
            DataClassification = ToBeClassified;
        }
        field(60301; "CXW Sales Price Currency Code"; Code[10])
        {
            Caption = 'Sales Price Currency Code';
            DataClassification = ToBeClassified;
            TableRelation = Currency;
        }
    }
}
