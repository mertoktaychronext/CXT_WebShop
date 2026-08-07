tableextension 51004 "SW Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(51000; "Tracking Number"; Text[30])
        {
            Caption = 'Tracking Number';
            DataClassification = ToBeClassified;
        }
    }
}
