table 60315 "CXW Sales Price Inbound File"
{
    Caption = 'Sales Price Inbound File';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "CXW Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "CXW Status"; Enum "CXW Ext Interface File Status")
        {
            Caption = 'Status';
            DataClassification = ToBeClassified;
        }
        field(3; "CXW Filename"; Text[250])
        {
            Caption = 'Filename';
            DataClassification = ToBeClassified;
        }
        field(4; "CXW SourceFile"; Blob)
        {
            Caption = 'Source File';
            DataClassification = CustomerContent;
        }
        field(5; "CXW Inserted At"; DateTime)
        {
            Caption = 'Inserted At';
            DataClassification = SystemMetadata;
        }
        field(6; "CXW Processed At"; DateTime)
        {
            Caption = 'Processed At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "CXW Entry No.")
        {
            Clustered = true;
        }
        key(Status; "CXW Status") { }
    }

    trigger OnInsert()
    begin
        "CXW Inserted At" := CurrentDateTime;
    end;
}
