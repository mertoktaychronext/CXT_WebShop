table 60318 "CXW Workshop Line"
{
    Caption = 'Workshop Line';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "CXW Document Type"; Enum "Purchase Document Type")
        {
            Caption = 'Document Type';
            DataClassification = ToBeClassified;
        }
        field(2; "CXW Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Purchase Header"."No." where("Document Type" = field("CXW Document Type"));
            DataClassification = ToBeClassified;
        }
        field(3; "CXW Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = ToBeClassified;
        }
        field(4; "CXW Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            DataClassification = ToBeClassified;
        }
        field(5; "CXW Manufacturer Serial No."; Text[50])
        {
            Caption = 'Manufacturer Serial No.';
            NotBlank = true;
            DataClassification = ToBeClassified;
        }
        field(6; "CXW Status"; Enum "CXW Workshop Line Status")
        {
            Caption = 'Status';
            DataClassification = ToBeClassified;
        }
        field(7; "CXW Genuine"; Boolean)
        {
            Caption = 'Genuine';
            DataClassification = ToBeClassified;
        }
        // TODO: Attributnamen final klären - Platzhalter-Captions "Attribut 1"-"Attribut 10"
        field(11; "CXW Attribute 1"; Text[250])
        {
            Caption = 'Attribut 1';
            DataClassification = ToBeClassified;
        }
        field(12; "CXW Attribute 2"; Text[250])
        {
            Caption = 'Attribut 2';
            DataClassification = ToBeClassified;
        }
        field(13; "CXW Attribute 3"; Text[250])
        {
            Caption = 'Attribut 3';
            DataClassification = ToBeClassified;
        }
        field(14; "CXW Attribute 4"; Text[250])
        {
            Caption = 'Attribut 4';
            DataClassification = ToBeClassified;
        }
        field(15; "CXW Attribute 5"; Text[250])
        {
            Caption = 'Attribut 5';
            DataClassification = ToBeClassified;
        }
        field(16; "CXW Attribute 6"; Text[250])
        {
            Caption = 'Attribut 6';
            DataClassification = ToBeClassified;
        }
        field(17; "CXW Attribute 7"; Text[250])
        {
            Caption = 'Attribut 7';
            DataClassification = ToBeClassified;
        }
        field(18; "CXW Attribute 8"; Text[250])
        {
            Caption = 'Attribut 8';
            DataClassification = ToBeClassified;
        }
        field(19; "CXW Attribute 9"; Text[250])
        {
            Caption = 'Attribut 9';
            DataClassification = ToBeClassified;
        }
        field(20; "CXW Attribute 10"; Text[250])
        {
            Caption = 'Attribut 10';
            DataClassification = ToBeClassified;
        }
        field(21; "CXW Created At"; DateTime)
        {
            Caption = 'Created At';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(22; "CXW Checked At"; DateTime)
        {
            Caption = 'Checked At';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(23; "CXW Processing Error"; Text[250])
        {
            Caption = 'Processing Error';
            Editable = false;
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "CXW Document Type", "CXW Document No.", "CXW Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if "CXW Created At" = 0DT then
            "CXW Created At" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        if (xRec."CXW Status" = xRec."CXW Status"::"WS geprüft") and ("CXW Status" = "CXW Status"::"Neu") then
            Error(StatusRegressionErr, xRec."CXW Status", "CXW Status");
        if (xRec."CXW Status" = xRec."CXW Status"::"Verarbeitet") and ("CXW Status" <> xRec."CXW Status") then
            Error(StatusRegressionErr, xRec."CXW Status", "CXW Status");

        if (xRec."CXW Status" <> "CXW Status") and ("CXW Status" = "CXW Status"::"WS geprüft") then
            "CXW Checked At" := CurrentDateTime;
    end;

    var
        StatusRegressionErr: Label 'The status cannot be changed from %1 to %2.', Comment = '%1 = old status, %2 = new status';
}
