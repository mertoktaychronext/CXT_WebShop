pageextension 60334 "CXW Sales Order" extends "Sales Order"
{
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
