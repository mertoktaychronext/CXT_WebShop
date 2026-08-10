table 60313 "CXW Sales Price Archive"
{
    Caption = 'Sales Price Archive';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "CXW Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
            NotBlank = true;
            TableRelation = Item;
        }
        field(3; "CXW Stock Price"; Decimal)
        {
            Caption = 'Stock Price';
            DataClassification = ToBeClassified;
        }
        field(4; "CXW Non Stock Price"; Decimal)
        {
            Caption = 'Non Stock Price';
            DataClassification = ToBeClassified;
        }
        field(5; "CXW Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = ToBeClassified;
            TableRelation = Currency;
        }
        field(6; "CXW Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;
        }
        field(7; "CXW Starting Time"; Time)
        {
            Caption = 'Starting Time';
            DataClassification = ToBeClassified;
        }
        field(8; "CXW Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = ToBeClassified;
        }
        field(9; "CXW Ending Time"; Time)
        {
            Caption = 'Ending Time';
            DataClassification = ToBeClassified;
        }
        field(10; "CXW Remark"; Text[150])
        {
            Caption = 'Remark';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(11; "CXW Last Modified UserID"; Code[50])
        {
            Caption = 'Last Modified UserID';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(12; "CXW Last Modified Date"; DateTime)
        {
            Caption = 'Last Modified Date';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(13; "CXW Accept New Setup"; Boolean)
        {
            Caption = 'Accept New Setup';
            DataClassification = ToBeClassified;
        }
        field(15; "CXW Reason Code"; Enum "CXW Sales Price Reason Code")
        {
            Caption = 'Reason Code';
            DataClassification = ToBeClassified;
        }
        field(16; "CXW Comment"; Text[250])
        {
            Caption = 'Comment';
            DataClassification = ToBeClassified;
        }
        field(17; "CXW Exchange Rate Amount"; Decimal)
        {
            Caption = 'Exchange Rate Amount';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(18; "CXW Exchange Rate Date"; Date)
        {
            Caption = 'Exchange Rate Date';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(19; "CXW Remark Backup"; Text[150])
        {
            Caption = 'Remark Backup';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(20; "CXW Strike Price"; Decimal)
        {
            Caption = 'Strike Price';
            DataClassification = ToBeClassified;
        }
        field(21; "CXW Recom. Retail Price"; Decimal)
        {
            Caption = 'Recom. Retail Price';
            DataClassification = ToBeClassified;
        }
        field(22; "CXW Validated"; Boolean)
        {
            Caption = 'Validated';
            DataClassification = ToBeClassified;
        }
        field(23; "CXW Old Stock Price"; Decimal)
        {
            Caption = 'Old Stock Price';
            DataClassification = ToBeClassified;
        }
        field(50000; "CXW Version No."; Integer)
        {
            Caption = 'Version No.';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "CXW Item No.", "CXW Currency Code", "CXW Version No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        "CXW Last Modified Date" := CurrentDateTime;
        "CXW Last Modified UserID" := UserId;
    end;

    trigger OnModify()
    begin
        "CXW Last Modified Date" := CurrentDateTime;
        "CXW Last Modified UserID" := UserId;
    end;
}
