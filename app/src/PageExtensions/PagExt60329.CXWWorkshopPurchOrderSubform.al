pageextension 60329 "CXW Workshop Purch Order Subf" extends "Purchase Order Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("CXW Manufacturer Serial No."; Rec."CXW Manufacturer Serial No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the manufacturer serial number captured when this line was sent to the workshop.';
            }
            field("CXW Sent to Workshop"; Rec."CXW Sent to Workshop")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies whether this line has already been sent to the workshop.';
            }
        }

        // Sperrt die Standardfelder der Zeile, sobald sie bereits an den Workshop
        // gesendet wurde (siehe design.md, "Sperrung der Purchase Line nach Übertragung").
        modify(Type)
        {
            Editable = LineEditable;
        }
        modify("No.")
        {
            Editable = LineEditable;
        }
        modify("Variant Code")
        {
            Editable = LineEditable;
        }
        modify(Description)
        {
            Editable = LineEditable;
        }
        modify("Location Code")
        {
            Editable = LineEditable;
        }
        modify(Quantity)
        {
            Editable = LineEditable;
        }
        modify("Unit of Measure Code")
        {
            Editable = LineEditable;
        }
        modify("Direct Unit Cost")
        {
            Editable = LineEditable;
        }
    }

    trigger OnAfterGetRecord()
    begin
        LineEditable := not Rec."CXW Sent to Workshop";
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        LineEditable := true;
    end;

    var
        LineEditable: Boolean;
}
