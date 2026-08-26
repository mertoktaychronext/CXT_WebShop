pageextension 60333 "CXW Purchase Order Subform" extends "Purchase Order Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("CXW Sales Order No."; Rec."CXW Sales Order No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the linked sales order number for this purchase line.';
            }
            field("CXW Sales Line No."; Rec."CXW Sales Line No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the linked sales order line number for this purchase line.';
            }
        }
    }
}
