table 51000 "SL General Sales Price Setup"
{
    Caption = 'General Sales Price Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Minimum Margin %"; Decimal)
        {
            Caption = 'Minimum Margin %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(3; "If Stock Price From Cat 1"; Decimal)
        {
            Caption = 'If Stock Price From Cat 1';
            DataClassification = ToBeClassified;
        }
        field(4; "If Stock Price To Cat 1"; Decimal)
        {
            Caption = 'If Stock Price To Cat 1';
            DataClassification = ToBeClassified;
        }
        field(5; "If Stock Price From Cat 2"; Decimal)
        {
            Caption = 'If Stock Price From Cat 2';
            DataClassification = ToBeClassified;
        }
        field(6; "If Stock Price To Cat 2"; Decimal)
        {
            Caption = 'If Stock Price To Cat 2';
            DataClassification = ToBeClassified;
        }
        field(7; "If Stock Price From Cat 3"; Decimal)
        {
            Caption = 'If Stock Price From Cat 3';
            DataClassification = ToBeClassified;
        }
        field(8; "If Stock Price To Cat 3"; Decimal)
        {
            Caption = 'If Stock Price To Cat 3';
            DataClassification = ToBeClassified;
        }
        field(9; "Cat 1 Non Stock %"; Decimal)
        {
            Caption = 'Cat 1 Non Stock %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(10; "Cat 2 Non Stock %"; Decimal)
        {
            Caption = 'Cat 2 Non Stock %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(11; "Cat 3 Non Stock %"; Decimal)
        {
            Caption = 'Cat 3 Non Stock %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(12; "Stock Price Threshold %"; Decimal)
        {
            Caption = 'Stock Price Threshold %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(13; "Non Stock Price Threshold %"; Decimal)
        {
            Caption = 'Non Stock Price Threshold %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(14; "Price Export Active"; Boolean)
        {
            Caption = 'Price Export Active';
            DataClassification = ToBeClassified;
        }
        field(15; "API Interface Code"; Code[20])
        {
            Caption = 'API Interface Code';
            DataClassification = ToBeClassified;
            TableRelation = "SL API Interface Setup".Code;

            trigger OnValidate()
            var
                l_recApiInterfaceSetup: Record "SL API Interface Setup";
            begin
                if "API Interface Code" = '' then
                    exit;
                l_recApiInterfaceSetup.Get("API Interface Code");
                l_recApiInterfaceSetup.TestField("Source Table No.", Database::"Sales Price");
            end;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
