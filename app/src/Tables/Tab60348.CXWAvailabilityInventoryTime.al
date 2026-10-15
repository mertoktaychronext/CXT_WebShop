table 60348 "CXW Availability Inv. Time"
{
    Caption = 'Availability Inventory Time';
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
        field(4; "CXW Inventory Type"; Code[10])
        {
            Caption = 'Inventory Type';
        }
        field(5; "CXW Delivery Days"; Integer)
        {
            Caption = 'Delivery Days';
            ToolTip = 'Specifies the delivery time in days for the inventory type.';
        }
        field(6; "CXW Exported"; Boolean)
        {
            Caption = 'Exported';
            Editable = false;
        }
        field(7; "CXW Exported At"; DateTime)
        {
            Caption = 'Exported At';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "CXW Item No.", "CXW Variant Code", "CXW Country/Region Code", "CXW Inventory Type")
        {
            Clustered = true;
        }
        key(Exported; "CXW Exported")
        {
        }
    }
}
