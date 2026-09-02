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
        field(5; "CXW Inserted At"; DateTime)
        {
            Caption = 'Inserted At';
            DataClassification = SystemMetadata;
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
    }

    trigger OnInsert()
    begin
        "CXW Inserted At" := CurrentDateTime;
    end;
}
