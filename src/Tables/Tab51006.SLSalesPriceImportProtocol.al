table 51006 "SL Sales Price Import Protocol"
{
    Caption = 'Sales Price Import Protocol';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Source Entry No."; BigInteger)
        {
            Caption = 'Source Entry No.';
            TableRelation = "SL Sales Price Inbound File"."Entry No.";
            DataClassification = SystemMetadata;
        }
        field(3; Message; Text[250])
        {
            Caption = 'Message';
            DataClassification = ToBeClassified;
        }
        field(4; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Source; "Source Entry No.") { }
    }

    trigger OnInsert()
    begin
        "Created At" := CurrentDateTime;
    end;
}
