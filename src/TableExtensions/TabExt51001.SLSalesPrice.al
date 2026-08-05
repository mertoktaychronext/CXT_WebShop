tableextension 51001 "SL Sales Price" extends "Sales Price"
{
    fields
    {
        field(51000; "Reason Code"; Enum "SL Sales Price Reason Code")
        {
            Caption = 'Reason Code';
            DataClassification = ToBeClassified;
        }
        field(51001; Comment; Text[250])
        {
            Caption = 'Comment';
            DataClassification = ToBeClassified;
        }
        field(51002; Remark; Text[150])
        {
            Caption = 'Remark';
            DataClassification = ToBeClassified;
        }
        field(51003; "Recom. Retail Price incl. VAT"; Decimal)
        {
            Caption = 'Recom. Retail Price incl. VAT';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
        field(51004; "Strike-Price incl. VAT"; Decimal)
        {
            Caption = 'Strike-Price incl. VAT';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
        field(51005; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = ToBeClassified;
            TableRelation = "Country/Region";
        }
        field(51006; "Unit Price (LCY)"; Decimal)
        {
            Caption = 'Unit Price (LCY)';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
        field(51007; "Unit Price (LCY) incl. VAT"; Decimal)
        {
            Caption = 'Unit Price (LCY) incl. VAT';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
    }
}
