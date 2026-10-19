table 60320 "CXW Sales Price Export"
{
    Caption = 'Sales Price Export';
    DataClassification = ToBeClassified;
    DrillDownPageId = "CXW Sales Price Export Entries";
    LookupPageId = "CXW Sales Price Export Entries";

    // One record per released country line: the price of that country as it was at release time.
    // The "Data Export Entry" (SALESPRICE) only points to this record via "Source Record ID".
    fields
    {
        field(1; "CXW Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "CXW Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
            TableRelation = Item;
        }
        field(3; "CXW Country Code"; Code[10])
        {
            Caption = 'Country Code';
            DataClassification = ToBeClassified;
            TableRelation = "Country/Region";
        }
        field(4; "CXW Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = ToBeClassified;
            TableRelation = Currency;
        }
        field(5; "CXW Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;
        }
        field(6; "CXW Starting Time"; Time)
        {
            Caption = 'Starting Time';
            DataClassification = ToBeClassified;
        }
        field(7; "CXW Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = ToBeClassified;
        }
        field(8; "CXW Ending Time"; Time)
        {
            Caption = 'Ending Time';
            DataClassification = ToBeClassified;
        }
        field(9; "CXW Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = ToBeClassified;
            AutoFormatType = 2;
            AutoFormatExpression = "CXW Currency Code";
        }
        field(10; "CXW Unit Price (LCY)"; Decimal)
        {
            Caption = 'Unit Price (LCY)';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
        }
        field(11; "CXW Non Stock Price"; Decimal)
        {
            Caption = 'Non Stock Price';
            DataClassification = ToBeClassified;
        }
        field(12; "CXW Strike Price"; Decimal)
        {
            Caption = 'Strike Price';
            DataClassification = ToBeClassified;
        }
        field(13; "CXW Recom. Retail Price"; Decimal)
        {
            Caption = 'Recom. Retail Price';
            DataClassification = ToBeClassified;
        }
        field(14; "CXW Exchange Rate Amount"; Decimal)
        {
            Caption = 'Exchange Rate Amount';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
        }
        field(15; "CXW Exchange Rate Date"; Date)
        {
            Caption = 'Exchange Rate Date';
            DataClassification = ToBeClassified;
        }
        field(16; "CXW Reason Code"; Enum "CXW Sales Price Reason Code")
        {
            Caption = 'Reason Code';
            DataClassification = ToBeClassified;
        }
        field(17; "CXW Comment"; Text[250])
        {
            Caption = 'Comment';
            DataClassification = ToBeClassified;
        }
        field(18; "CXW Remark"; Text[150])
        {
            Caption = 'Remark';
            DataClassification = ToBeClassified;
        }
        field(19; "CXW Last Modified UserID"; Code[50])
        {
            Caption = 'Last Modified UserID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; "CXW Last Modified Date"; DateTime)
        {
            Caption = 'Last Modified Date';
            DataClassification = ToBeClassified;
        }
        field(21; "CXW Sales Price SystemId"; Guid)
        {
            Caption = 'Sales Price SystemId';
            DataClassification = SystemMetadata;
        }
        field(22; "CXW Data Export Entry No."; BigInteger)
        {
            Caption = 'Data Export Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Data Export Entry"."Entry No.";
        }
        field(23; "CXW Export Status"; Enum "Data Export Statuses")
        {
            Caption = 'Export Status';
            FieldClass = FlowField;
            CalcFormula = lookup("Data Export Entry".Status where("Entry No." = field("CXW Data Export Entry No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "CXW Entry No.")
        {
            Clustered = true;
        }
        key(ItemCountry; "CXW Item No.", "CXW Country Code", "CXW Currency Code") { }
    }
}
