table 51004 "SL Sales Price Outbound File"
{
    Caption = 'Sales Price Outbound File';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; Status; Enum "SL Ext Interface File Status")
        {
            Caption = 'Status';
            DataClassification = ToBeClassified;
        }
        field(3; Filename; Text[250])
        {
            Caption = 'Filename';
            DataClassification = ToBeClassified;
        }
        field(4; TargetFile; Blob)
        {
            Caption = 'Target File';
            DataClassification = CustomerContent;
        }
        field(5; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(6; "Response Message"; Text[250])
        {
            Caption = 'Response Message';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Status; Status) { }
    }

    trigger OnInsert()
    begin
        "Created At" := CurrentDateTime;
    end;
}
