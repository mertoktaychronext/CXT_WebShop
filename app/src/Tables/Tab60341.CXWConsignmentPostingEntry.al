table 60341 "CXW Consignment Posting Entry"
{
    Caption = 'Consignment Posting Entry';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "CXW Entry No"; Integer)
        {
            Caption = 'Entry No';
            AutoIncrement = true;
            DataClassification = ToBeClassified;
        }
        field(2; "CXW Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            DataClassification = ToBeClassified;
        }
        field(3; "CXW Purchase Order No."; Code[20])
        {
            Caption = 'Purchase Order No.';
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
            DataClassification = ToBeClassified;
        }
        field(4; "CXW Sales Invoice No."; Code[20])
        {
            Caption = 'Sales Invoice No.';
            TableRelation = "Sales Invoice Header";
            DataClassification = ToBeClassified;
        }
        field(5; "CXW Sales Posting Date"; Date)
        {
            Caption = 'Sales Posting Date';
            DataClassification = ToBeClassified;
        }
        field(6; "CXW Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = ToBeClassified;
        }
        field(7; "CXW Status"; Enum "CXW Consignment Posting Status")
        {
            Caption = 'Status';
            DataClassification = ToBeClassified;
        }
        field(8; "CXW Error Text"; Text[250])
        {
            Caption = 'Error Text';
            Editable = false;
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "CXW Entry No")
        {
            Clustered = true;
        }
    }
}
