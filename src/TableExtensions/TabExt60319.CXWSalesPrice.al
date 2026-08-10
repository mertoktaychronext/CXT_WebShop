tableextension 60319 "CXW Sales Price" extends "Sales Price"
{
    fields
    {
        field(60300; "CXW Reason Code"; Enum "CXW Sales Price Reason Code")
        {
            Caption = 'Reason Code';
            DataClassification = ToBeClassified;
        }
        field(60301; "CXW Comment"; Text[250])
        {
            Caption = 'Comment';
            DataClassification = ToBeClassified;
        }
        field(60302; "CXW Remark"; Text[150])
        {
            Caption = 'Remark';
            DataClassification = ToBeClassified;
        }
        field(60303; "CXW Rec. Retail Price incl VAT"; Decimal)
        {
            Caption = 'Recom. Retail Price incl. VAT';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
        field(60304; "CXW Strike-Price incl. VAT"; Decimal)
        {
            Caption = 'Strike-Price incl. VAT';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
        field(60305; "CXW Unit Price (LCY)"; Decimal)
        {
            Caption = 'Unit Price (LCY)';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
        field(60306; "CXW Unit Price (LCY) incl. VAT"; Decimal)
        {
            Caption = 'Unit Price (LCY) incl. VAT';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
    }
}
