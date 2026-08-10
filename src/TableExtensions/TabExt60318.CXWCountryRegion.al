tableextension 60318 "CXW Country Region" extends "Country/Region"
{
    fields
    {
        field(60300; "CXW Taxation Type"; Enum "CXW Taxation Type")
        {
            Caption = 'Taxation Type';
            DataClassification = ToBeClassified;
        }
        field(60301; "CXW Delivery Time"; DateFormula)
        {
            Caption = 'Delivery Time (Days)';
            DataClassification = ToBeClassified;
        }
        field(60302; "CXW Sales Price Currency Code"; Code[10])
        {
            Caption = 'Sales Price Currency Code';
            DataClassification = ToBeClassified;
            TableRelation = Currency;
        }
    }
}
