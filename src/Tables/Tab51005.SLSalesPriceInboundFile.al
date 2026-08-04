// Schlanker, eigenständiger Ersatz für Table 5275377 "Ext. Interface Inbound File" (ISV-Modul EXIN).
// Nur das für Codeunit 51001 "SL Import Sales Prices" benötigte Minimum, keine ISV-Matrix.
table 51005 "SL Sales Price Inbound File"
{
    Caption = 'Sales Price Inbound File';
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
        field(4; SourceFile; Blob)
        {
            Caption = 'Source File';
            DataClassification = CustomerContent;
        }
        field(5; "Inserted At"; DateTime)
        {
            Caption = 'Inserted At';
            DataClassification = SystemMetadata;
        }
        field(6; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
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
        "Inserted At" := CurrentDateTime;
    end;
}
