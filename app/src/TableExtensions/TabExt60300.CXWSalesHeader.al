tableextension 60300 "CXW Sales Header" extends "Sales Header"
{
    fields
    {
        // Kept for schema compatibility with versions that published this field.
        // New code must use CHX.Base field "CXB Hold Order" instead.
        field(60300; "CXW Hold Order"; Boolean)
        {
            Caption = 'Hold Order';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by CHX.Base field "CXB Hold Order".';
            ObsoleteTag = '27.0.0.13';
        }
    }
}
