table 60311 "CXW General Sales Price Setup"
{
    Caption = 'General Sales Price Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "CXW Primary Key"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "CXW Minimum Margin %"; Decimal)
        {
            Caption = 'Minimum Margin %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(3; "CXW If Stock Price From Cat 1"; Decimal)
        {
            Caption = 'If Stock Price From Cat 1';
            DataClassification = ToBeClassified;
        }
        field(4; "CXW If Stock Price To Cat 1"; Decimal)
        {
            Caption = 'If Stock Price To Cat 1';
            DataClassification = ToBeClassified;
        }
        field(5; "CXW If Stock Price From Cat 2"; Decimal)
        {
            Caption = 'If Stock Price From Cat 2';
            DataClassification = ToBeClassified;
        }
        field(6; "CXW If Stock Price To Cat 2"; Decimal)
        {
            Caption = 'If Stock Price To Cat 2';
            DataClassification = ToBeClassified;
        }
        field(7; "CXW If Stock Price From Cat 3"; Decimal)
        {
            Caption = 'If Stock Price From Cat 3';
            DataClassification = ToBeClassified;
        }
        field(8; "CXW If Stock Price To Cat 3"; Decimal)
        {
            Caption = 'If Stock Price To Cat 3';
            DataClassification = ToBeClassified;
        }
        field(9; "CXW Cat 1 Non Stock %"; Decimal)
        {
            Caption = 'Cat 1 Non Stock %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(10; "CXW Cat 2 Non Stock %"; Decimal)
        {
            Caption = 'Cat 2 Non Stock %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(11; "CXW Cat 3 Non Stock %"; Decimal)
        {
            Caption = 'Cat 3 Non Stock %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(12; "CXW Stock Price Threshold %"; Decimal)
        {
            Caption = 'Stock Price Threshold %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(13; "CXW Non Stock Price Thresh %"; Decimal)
        {
            Caption = 'Non Stock Price Threshold %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 2;
        }
        field(14; "CXW Price Export Active"; Boolean)
        {
            Caption = 'Price Export Active';
            DataClassification = ToBeClassified;
        }
        field(15; "CXW API Interface Code"; Code[20])
        {
            Caption = 'API Interface Code';
            DataClassification = ToBeClassified;
            TableRelation = "CXW API Interface Setup"."CXW Code";

            trigger OnValidate()
            var
                l_recApiInterfaceSetup: Record "CXW API Interface Setup";
            begin
                if "CXW API Interface Code" = '' then
                    exit;
                l_recApiInterfaceSetup.Get("CXW API Interface Code");
                l_recApiInterfaceSetup.TestField("CXW Source Table No.", Database::"Sales Price");
            end;
        }
        field(16; "CXW Prices Incl. VAT"; Boolean)
        {
            Caption = 'Prices Incl. VAT';
            DataClassification = ToBeClassified;
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "CXW Primary Key")
        {
            Clustered = true;
        }
    }
}
