pageextension 60334 "CXW Sales Order" extends "Sales Order"
{
    layout
    {
        addlast(General)
        {
            field("CXW Hold Order"; Rec."CXW Hold Order")
            {
                ApplicationArea = All;
                Editable = Rec.Status = Rec.Status::Open;
                ToolTip = 'Specifies that the order is on hold. This is for information only and does not block releasing, posting or shipping. You can only change it while the order is open.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(CXWOnDemandLines)
            {
                ApplicationArea = All;
                Caption = 'On Demand Lines';
                ToolTip = 'Opens the work list for on-demand sales lines that are still open, not released, and without reservation.';

                trigger OnAction()
                begin
                    Page.RunModal(Page::"CXW On Demand Sales Lines");
                end;
            }
        }
    }
}
