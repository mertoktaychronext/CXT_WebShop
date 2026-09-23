table 60347 "CXW Availability Delivery Time"
{
    Caption = 'Availability Delivery Time';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "CXW Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(2; "CXW Variant Code"; Code[20])
        {
            Caption = 'Variant Code';
        }
        field(3; "CXW Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(4; "CXW Delivery Days"; Integer)
        {
            Caption = 'Delivery Days';
            ToolTip = 'Specifies the calculated delivery time in days. A value of -1 means that the item is currently not deliverable.';
        }
        field(5; "CXW Inserted At"; DateTime)
        {
            Caption = 'Inserted At';
            Editable = false;
        }
        field(6; "CXW Inserted By"; Code[50])
        {
            Caption = 'Inserted By';
            Editable = false;
        }
        field(7; "CXW Modified At"; DateTime)
        {
            Caption = 'Modified At';
            Editable = false;
        }
        field(8; "CXW Modified By"; Code[50])
        {
            Caption = 'Modified By';
            Editable = false;
        }
        field(9; "CXW Exported"; Boolean)
        {
            Caption = 'Exported';
            Editable = false;
        }
        field(10; "CXW Exported At"; DateTime)
        {
            Caption = 'Exported At';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "CXW Item No.", "CXW Variant Code", "CXW Country/Region Code")
        {
            Clustered = true;
        }
        key(Exported; "CXW Exported")
        {
        }
    }

    trigger OnInsert()
    begin
        "CXW Inserted At" := CurrentDateTime;
        "CXW Inserted By" := CopyStr(UserId, 1, MaxStrLen("CXW Inserted By"));
    end;

    trigger OnModify()
    begin
        "CXW Modified At" := CurrentDateTime;
        "CXW Modified By" := CopyStr(UserId, 1, MaxStrLen("CXW Modified By"));
    end;
}
