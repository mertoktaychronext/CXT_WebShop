pageextension 60335 "CXW Purchase Order" extends "Purchase Order"
{
    actions
    {
        addlast(Processing)
        {
            action(CXWOnDemandPurchaseLines)
            {
                ApplicationArea = All;
                Caption = 'On-Demand Purchase Lines';
                ToolTip = 'Opens the work list for open on-demand purchase lines that do not yet have a sales assignment.';

                trigger OnAction()
                begin
                    Page.RunModal(Page::"CXW On Demand Purchase Lines");
                end;
            }
        }
    }
}
