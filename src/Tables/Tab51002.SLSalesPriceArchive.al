table 51002 "SL Sales Price Archive"
{
    Caption = 'Sales Price Archive';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
            NotBlank = true;
            TableRelation = Item;
        }
        field(3; "Stock Price"; Decimal)
        {
            Caption = 'Stock Price';
            DataClassification = ToBeClassified;
        }
        field(4; "Non Stock Price"; Decimal)
        {
            Caption = 'Non Stock Price';
            DataClassification = ToBeClassified;
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = ToBeClassified;
            TableRelation = Currency;
        }
        field(6; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;
        }
        field(7; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            DataClassification = ToBeClassified;
        }
        field(8; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = ToBeClassified;
        }
        field(9; "Ending Time"; Time)
        {
            Caption = 'Ending Time';
            DataClassification = ToBeClassified;
        }
        field(10; Remark; Text[150])
        {
            Caption = 'Remark';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(11; "Last Modified UserID"; Code[50])
        {
            Caption = 'Last Modified UserID';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(12; "Last Modified Date"; DateTime)
        {
            Caption = 'Last Modified Date';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(13; "Accept New Setup"; Boolean)
        {
            Caption = 'Accept New Setup';
            DataClassification = ToBeClassified;
        }
        field(14; "Country Code"; Code[10])
        {
            Caption = 'Country Code';
            DataClassification = ToBeClassified;
            TableRelation = "Country/Region";
        }
        field(15; "Reason Code"; Enum "SL Sales Price Reason Code")
        {
            Caption = 'Reason Code';
            DataClassification = ToBeClassified;
        }
        field(16; Comment; Text[250])
        {
            Caption = 'Comment';
            DataClassification = ToBeClassified;
        }
        field(17; "Exchange Rate Amount"; Decimal)
        {
            Caption = 'Exchange Rate Amount';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(18; "Exchange Rate Date"; Date)
        {
            Caption = 'Exchange Rate Date';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(19; "Remark Backup"; Text[150])
        {
            Caption = 'Remark Backup';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(20; "Strike Price"; Decimal)
        {
            Caption = 'Strike Price';
            DataClassification = ToBeClassified;
        }
        field(21; "Recom. Retail Price"; Decimal)
        {
            Caption = 'Recom. Retail Price';
            DataClassification = ToBeClassified;
        }
        field(22; Validated; Boolean)
        {
            Caption = 'Validated';
            DataClassification = ToBeClassified;
        }
        field(23; "Old Stock Price"; Decimal)
        {
            Caption = 'Old Stock Price';
            DataClassification = ToBeClassified;
        }
        field(50000; "Version No."; Integer)
        {
            Caption = 'Version No.';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Item No.", "Currency Code", "Country Code", "Version No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        "Last Modified Date" := CurrentDateTime;
        "Last Modified UserID" := UserId;
    end;

    trigger OnModify()
    begin
        "Last Modified Date" := CurrentDateTime;
        "Last Modified UserID" := UserId;
    end;
}
