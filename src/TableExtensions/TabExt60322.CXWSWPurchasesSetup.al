tableextension 60322 "CXW SW Purchases Setup" extends "Purchases & Payables Setup"
{
    fields
    {
        field(60300; "CXW SW Item Template Code"; Code[20])
        {
            Caption = 'SellWatch Item Template';
            TableRelation = "Item Templ.";
            DataClassification = ToBeClassified;
        }
        field(60301; "CXW SW Consign.Inv.Delay(Days)"; Integer)
        {
            Caption = 'Consignment Invoice Delay (Days)';
            MinValue = 0;
            DataClassification = ToBeClassified;
        }
        field(60302; "CXW Workshop Tenant"; Text[30])
        {
            Caption = 'Workshop Tenant';
            DataClassification = ToBeClassified;
        }
    }
}
