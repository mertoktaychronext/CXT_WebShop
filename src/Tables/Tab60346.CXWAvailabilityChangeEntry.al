table 60346 "CXW Availability Change Entry"
{
    Caption = 'Availability Change Entry';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "CXW Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "CXW Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            DataClassification = CustomerContent;
        }
        field(3; "CXW Variant Code"; Code[20])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
        }
        field(4; "CXW Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
            DataClassification = CustomerContent;
        }
        field(6; "CXW Exported"; Boolean)
        {
            Caption = 'Exported';
            DataClassification = SystemMetadata;
        }
        field(7; "CXW Exported At"; DateTime)
        {
            Caption = 'Exported At';
            DataClassification = SystemMetadata;
        }
        field(8; "CXW Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; "CXW Inventory Quantity"; Decimal)
        {
            Caption = 'Available Inventory Quantity';
            DataClassification = CustomerContent;
        }
        field(16; "CXW Changed At"; DateTime)
        {
            Caption = 'Changed At';
            DataClassification = SystemMetadata;
        }
        field(17; "CXW Differential Taxation Purchase"; Boolean)
        {
            Caption = 'Differential Taxation Purchase';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "CXW Entry No.")
        {
            Clustered = true;
        }
        key(Exported; "CXW Exported")
        {
        }
        key(ItemLedgerEntry; "CXW Item Ledger Entry No.", "CXW Exported")
        {
        }
    }

    trigger OnInsert()
    begin
        "CXW Changed At" := CurrentDateTime;
    end;
}
