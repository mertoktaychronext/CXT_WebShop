tableextension 60321 "CXW Workshop Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(60301; "CXW Manufacturer Serial No."; Text[50])
        {
            Caption = 'Manufacturer Serial No.';
            DataClassification = ToBeClassified;
        }
        field(60302; "CXW Not Arrived"; Boolean)
        {
            Caption = 'Not Arrived';
            DataClassification = ToBeClassified;
        }
        field(60303; "CXW Sent to Workshop"; Boolean)
        {
            Caption = 'Sent to Workshop';
            DataClassification = ToBeClassified;
        }
    }

    trigger OnDelete()
    var
        WorkshopLine: Record "CXW Workshop Line";
    begin
        if WorkshopLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then
            if WorkshopLine."CXW Status" <> WorkshopLine."CXW Status"::"Processed" then
                WorkshopLine.Delete();
        // Workshop Lines im Status "Processed" bleiben als Prüfnachweis bestehen (kein Cascade-Delete).
    end;
}
