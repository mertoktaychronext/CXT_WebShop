table 60302 "CXW Http Call Log"
{
    Caption = 'Http Call Log';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "CXW Entry No"; Integer)
        {
            Caption = 'Entry No';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "CXW Call DateTime"; DateTime)
        {
            Caption = 'Call Date/Time';
            DataClassification = SystemMetadata;
        }
        field(3; "CXW Source Entry No"; Integer)
        {
            Caption = 'Source Entry No';
            TableRelation = if ("CXW Source Table No." = const(60301)) "CXW Watch Online Approval"."CXW Entry No"
                             else
                             if ("CXW Source Table No." = const(60314)) "CXW Sales Price Outbound File"."CXW Entry No."
                             else
                             if ("CXW Source Table No." = const(50103)) "Data Export Entry"."Entry No.";
            DataClassification = SystemMetadata;
        }
        field(4; "CXW Endpoint URL"; Text[250])
        {
            Caption = 'Endpoint URL';
            DataClassification = SystemMetadata;
        }
        field(5; "CXW Success"; Boolean)
        {
            Caption = 'Success';
            DataClassification = SystemMetadata;
        }
        field(6; "CXW HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
            DataClassification = SystemMetadata;
        }
        field(7; "CXW Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = SystemMetadata;
        }
        field(8; "CXW Request"; Blob)
        {
            Caption = 'Request';
            DataClassification = CustomerContent;
        }
        field(9; "CXW Response"; Blob)
        {
            Caption = 'Response';
            DataClassification = CustomerContent;
        }
        field(10; "CXW Source Table No."; Integer)
        {
            Caption = 'Source Table No.';
            DataClassification = SystemMetadata;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
    }

    keys
    {
        key(PK; "CXW Entry No")
        {
            Clustered = true;
        }
        key(Source; "CXW Source Entry No") { }
    }

    trigger OnInsert()
    begin
        "CXW Call DateTime" := CurrentDateTime;
    end;
}
