tableextension 60304 "CXW SW Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(60300; "CXW Tracking Number"; Text[30])
        {
            Caption = 'Tracking Number';
            DataClassification = ToBeClassified;
        }
    }
}
