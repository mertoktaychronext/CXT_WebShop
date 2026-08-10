table 60314 "CXW Sales Price Outbound File"
{
    Caption = 'Sales Price Outbound File';
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
        field(4; "CXW TargetFile"; Blob)
        {
            Caption = 'Target File';
            DataClassification = CustomerContent;
        }
        field(5; "CXW Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(6; "CXW Response Message"; Text[250])
        {
            Caption = 'Response Message';
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
        "CXW Created At" := CurrentDateTime;
    end;
}
