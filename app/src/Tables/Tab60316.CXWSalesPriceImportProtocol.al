table 60316 "CXW Price Import Protocol"
{
    Caption = 'Sales Price Import Protocol';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "CXW Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "CXW Source Entry No."; BigInteger)
        {
            Caption = 'Source Entry No.';
            TableRelation = "CXW Sales Price Inbound File"."CXW Entry No.";
            DataClassification = SystemMetadata;
        }
        field(3; "CXW Message"; Text[250])
        {
            Caption = 'Message';
            DataClassification = ToBeClassified;
        }
        field(4; "CXW Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "CXW Entry No.")
        {
            Clustered = true;
        }
        key(Source; "CXW Source Entry No.") { }
    }

    trigger OnInsert()
    begin
        "CXW Created At" := CurrentDateTime;
    end;
}
