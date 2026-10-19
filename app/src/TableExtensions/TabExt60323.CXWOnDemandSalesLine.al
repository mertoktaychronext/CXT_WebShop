tableextension 60323 "CXW On Demand Sales Line" extends "Sales Line"
{
    fields
    {
        field(60300; "CXW Purchase Order No."; Code[20])
        {
            Caption = 'Purchase Order No.';
            DataClassification = ToBeClassified;
        }
        field(60301; "CXW Purchase Line No."; Integer)
        {
            Caption = 'Purchase Line No.';
            DataClassification = ToBeClassified;
        }
    }

    trigger OnDelete()
    var
        OnDemandLinkMgt: Codeunit "CXW On Demand Link Mgt";
    begin
        OnDemandLinkMgt.ClearLinkedPurchaseForDeletedSalesLine(Rec);
    end;
}
