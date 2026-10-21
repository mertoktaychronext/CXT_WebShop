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
        field(7; "CXW isAuthentic"; Boolean)
        {
            Caption = 'Authentic';
            DataClassification = ToBeClassified;
        }
        // TODO: Attributnamen für Attribut 9/10 final klären - Platzhalter-Captions "Attribut 9"-"Attribut 10"
        field(11; "CXW Dial Color"; Text[250])
        {
            Caption = 'Dial Color';
            DataClassification = ToBeClassified;
        }
        field(12; "CXW Case Diameter"; Text[250])
        {
            Caption = 'Case Diameter';
            DataClassification = ToBeClassified;
        }
        field(13; "CXW Bracelet Material"; Text[250])
        {
            Caption = 'Bracelet Material';
            DataClassification = ToBeClassified;
        }
        field(14; "CXW Case Material"; Text[250])
        {
            Caption = 'Case Material';
            DataClassification = ToBeClassified;
        }
        field(15; "CXW Movement"; Text[250])
        {
            Caption = 'Movement';
            DataClassification = ToBeClassified;
        }
        field(16; "CXW Gender"; Text[250])
        {
            Caption = 'Gender';
            DataClassification = ToBeClassified;
        }
        field(17; "CXW Crystal"; Text[250])
        {
            Caption = 'Crystal';
            DataClassification = ToBeClassified;
        }
        field(18; "CXW Features"; Text[250])
        {
            Caption = 'Features';
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
        field(23; "CXW Last Error"; Text[250])
        {
            Caption = 'Last Error';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        // Snapshot of the purchase order and the watch data at the time the line was sent to the workshop,
        // so that the workshop API user needs no access to purchase documents, vendors or items.
        field(30; "CXW Vendor Order No."; Code[35])
        {
            Caption = 'Vendor Order No.';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(31; "CXW Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(32; "CXW Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(33; "CXW Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(34; "CXW Description"; Text[100])
        {
            Caption = 'Description';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(35; "CXW Quantity"; Decimal)
        {
            Caption = 'Quantity';
            Editable = false;
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
        }
        field(36; "CXW Unit Price"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            Editable = false;
            DataClassification = ToBeClassified;
            AutoFormatType = 2;
            AutoFormatExpression = "CXW Currency Code";
        }
        field(37; "CXW Used Goods"; Boolean)
        {
            Caption = 'Used Goods';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(38; "CXW Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        // BC serial number from the item tracking of the purchase line; the manufacturer serial number is field 5.
        field(39; "CXW Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(40; "CXW Brand"; Text[250])
        {
            Caption = 'Brand';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(41; "CXW Model"; Text[250])
        {
            Caption = 'Model';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(42; "CXW Sub Model"; Text[250])
        {
            Caption = 'Sub Model';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(43; "CXW Reference"; Text[250])
        {
            Caption = 'Reference';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(44; "CXW Year"; Integer)
        {
            Caption = 'Year';
            Editable = false;
            DataClassification = ToBeClassified;
            BlankZero = true;
        }
        field(45; "CXW Condition"; Text[250])
        {
            Caption = 'Condition';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(46; "CXW Box"; Text[250])
        {
            Caption = 'Box';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(47; "CXW Certificate"; Text[250])
        {
            Caption = 'Certificate';
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
        if (xRec."CXW Status" = xRec."CXW Status"::"WS checked") and ("CXW Status" = "CXW Status"::"new") then
            Error(StatusRegressionErr, xRec."CXW Status", "CXW Status");
        if (xRec."CXW Status" = xRec."CXW Status"::"Processed") and ("CXW Status" <> xRec."CXW Status") then
            Error(StatusRegressionErr, xRec."CXW Status", "CXW Status");
        if (xRec."CXW Status" <> "CXW Status") and ("CXW Status" = "CXW Status"::Error) and (xRec."CXW Status" <> xRec."CXW Status"::"WS checked") then
            Error(StatusRegressionErr, xRec."CXW Status", "CXW Status");

        if (xRec."CXW Status" <> "CXW Status") and ("CXW Status" = "CXW Status"::"WS checked") then
            "CXW Checked At" := CurrentDateTime;
    end;

    var
        StatusRegressionErr: Label 'The status cannot be changed from %1 to %2.', Comment = '%1 = old status, %2 = new status';
}
