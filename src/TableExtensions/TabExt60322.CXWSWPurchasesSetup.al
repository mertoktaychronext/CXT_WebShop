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
    }
}
