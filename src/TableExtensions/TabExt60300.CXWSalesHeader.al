tableextension 60300 "CXW Sales Header" extends "Sales Header"
{
    fields
    {
        field(60300; "CXW Hold Order"; Boolean)
        {
            Caption = 'Hold Order';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                // Informational flag only; it must not change once the order has left status Open.
                // Re-validating the unchanged value (e.g. from a configuration package) is allowed.
                if Rec."CXW Hold Order" <> xRec."CXW Hold Order" then
                    TestField(Status, Status::Open);
            end;
        }
    }
}
