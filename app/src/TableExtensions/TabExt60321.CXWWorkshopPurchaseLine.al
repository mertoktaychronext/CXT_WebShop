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
        OnDemandLinkMgt: Codeunit "CXW On Demand Link Mgt";
        WorkshopLineMgt: Codeunit "CXW Workshop Line Mgt.";
    begin
        OnDemandLinkMgt.ClearLinkedSalesForDeletedPurchaseLine(Rec);

        // Workshop Lines im Status "Processed" bleiben als Prüfnachweis bestehen (kein Cascade-Delete).
        // Über die Codeunit, weil "CXW Workshop All" nur indirektes Löschrecht auf die Workshop Line hat.
        WorkshopLineMgt.DeleteForDeletedPurchLine(Rec);
    end;
}
