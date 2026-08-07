tableextension 51003 "SW Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(51000; "Used good"; Boolean)
        {
            Caption = 'Used Good';
            DataClassification = ToBeClassified;
        }
    }
}
