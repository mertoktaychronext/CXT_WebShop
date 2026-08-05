tableextension 51000 "SL Country Region" extends "Country/Region"
{
    fields
    {
        field(51000; "Taxation Type"; Enum "SL Taxation Type")
        {
            Caption = 'Taxation Type';
            DataClassification = ToBeClassified;
        }
        field(51001; "Delivery Time"; DateFormula)
        {
            Caption = 'Delivery Time (Days)';
            DataClassification = ToBeClassified;
        }
        field(51002; "Sales Price Currency Code"; Code[10])
        {
            Caption = 'Sales Price Currency Code';
            DataClassification = ToBeClassified;
            TableRelation = Currency;
        }
    }
}
