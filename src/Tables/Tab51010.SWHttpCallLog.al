table 51010 "SW Http Call Log"
{
    Caption = 'SW Http Call Log';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No"; Integer)
        {
            Caption = 'Entry No';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Call DateTime"; DateTime)
        {
            Caption = 'Call Date/Time';
            DataClassification = SystemMetadata;
        }
        field(3; "Source Entry No"; Integer)
        {
            Caption = 'Source Entry No';
            TableRelation = "Watch Online Approval"."Entry No";
            DataClassification = SystemMetadata;
        }
        field(4; "Endpoint URL"; Text[250])
        {
            Caption = 'Endpoint URL';
            DataClassification = SystemMetadata;
        }
        field(5; Success; Boolean)
        {
            Caption = 'Success';
            DataClassification = SystemMetadata;
        }
        field(6; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
            DataClassification = SystemMetadata;
        }
        field(7; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = SystemMetadata;
        }
        field(8; Request; Blob)
        {
            Caption = 'Request';
            DataClassification = CustomerContent;
        }
        field(9; Response; Blob)
        {
            Caption = 'Response';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No")
        {
            Clustered = true;
        }
        key(Source; "Source Entry No") { }
    }

    trigger OnInsert()
    begin
        "Call DateTime" := CurrentDateTime;
    end;
}
