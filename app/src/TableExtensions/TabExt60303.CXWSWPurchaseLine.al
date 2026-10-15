tableextension 60303 "CXW SW Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(60300; "CXW Used good"; Boolean)
        {
            Caption = 'Used Good';
            DataClassification = ToBeClassified;
        }
        field(60304; "CXW Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            DataClassification = ToBeClassified;
        }
        field(60305; "CXW Sales Line No."; Integer)
        {
            Caption = 'Sales Line No.';
            DataClassification = ToBeClassified;
        }
    }

    trigger OnDelete()
    var
        OnDemandLinkMgt: Codeunit "CXW On Demand Link Mgt";
    begin
        OnDemandLinkMgt.ClearLinkedSalesForDeletedPurchaseLine(Rec);
    end;
}
