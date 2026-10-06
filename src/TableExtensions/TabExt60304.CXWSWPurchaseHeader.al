tableextension 60304 "CXW SW Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(60300; "CXW Tracking Number"; Text[30])
        {
            Caption = 'Tracking Number';
            DataClassification = ToBeClassified;
        }
        field(60301; "CXW No. of Workshop Lines"; Integer)
        {
            Caption = 'No. of Workshop Lines';
            FieldClass = FlowField;
            CalcFormula = count("CXW Workshop Line" where("CXW Document Type" = field("Document Type"),
                                                          "CXW Document No." = field("No.")));
            Editable = false;
            BlankZero = true;
        }
    }
}
