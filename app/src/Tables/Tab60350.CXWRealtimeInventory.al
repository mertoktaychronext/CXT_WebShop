table 60350 "CXW Realtime Inventory"
{
    Caption = 'Realtime Inventory';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "CXW Entry No."; BigInteger) { AutoIncrement = true; }
        field(2; "CXW Item No."; Code[20]) { TableRelation = Item; }
        field(3; "CXW Variant Code"; Code[10]) { }
        field(4; "CXW Quantity"; Decimal) { DecimalPlaces = 0 : 5; }
        field(5; "CXW Company Name"; Text[30]) { }
        field(6; "CXW Sales Price"; Decimal) { AutoFormatType = 1; }
        field(7; "CXW Location Code"; Code[10]) { TableRelation = Location; }
        field(8; "CXW Serial No."; Code[50]) { }
        field(9; "CXW Purchase Price"; Decimal) { AutoFormatType = 1; }
        field(10; "CXW Brand"; Text[250]) { }
        field(11; "CXW Model"; Text[250]) { }
        field(12; "CXW Reference"; Text[250]) { }
        field(13; "CXW Variant Category"; Text[250]) { }
        field(14; "CXW Condition"; Text[250]) { }
        field(15; "CXW Visibility"; Text[250]) { }
        field(16; "CXW Certificate"; Text[250]) { }
        field(17; "CXW Differential Taxation"; Boolean) { }
        field(18; "CXW Posting Date"; Date) { }
        field(19; "CXW Purchase Order No."; Code[20]) { }
        field(20; "CXW Vendor No."; Code[20]) { TableRelation = Vendor; }
    }

    keys
    {
        key(PK; "CXW Entry No.") { Clustered = true; }
        key(ItemVariant; "CXW Item No.", "CXW Variant Code") { }
    }
}
