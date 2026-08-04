// Schlanker, eigenständiger Ersatz für Table 5275378 "Ext. Interface Outbound File" (ISV-Modul EXIN).
// Auf Kundenwunsch NICHT die ISV-Matrix nachgebaut (kein Ext. Interface Setup/Message Setup,
// kein System-Value-Linking), sondern nur das für den Sales-Price-Export in Codeunit 51000
// "SL Export Gateway Sales Price" benötigte Minimum.
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
        field(3; "Message Code"; Code[10])
        {
            Caption = 'Message Code';
            DataClassification = ToBeClassified;
        }
        field(4; Filename; Text[250])
        {
            Caption = 'Filename';
            DataClassification = ToBeClassified;
        }
        field(5; SourceFile; Blob)
        {
            Caption = 'Source File';
            DataClassification = CustomerContent;
        }
        field(6; "Inserted At"; DateTime)
        {
            Caption = 'Inserted At';
            DataClassification = SystemMetadata;
        }
        field(7; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            DataClassification = SystemMetadata;
        }
        field(8; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(9; "Number of Attempts"; Integer)
        {
            Caption = 'Number of Attempts';
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
