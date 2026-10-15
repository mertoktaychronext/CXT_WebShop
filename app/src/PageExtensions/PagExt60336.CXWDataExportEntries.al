pageextension 60336 "CXW Data Export Entries" extends "Data Export Entries"
{
    actions
    {
        addlast(Processing)
        {
            action(CXWRequeueSalesPrice)
            {
                ApplicationArea = All;
                Caption = 'Requeue Sales Price';
                ToolTip = 'Sets the selected sales price entries with status Error back to pending, so that the sales price export job sends them again with the stored payload.';
                Image = Refresh;

                trigger OnAction()
                var
                    l_recDataExportEntry: Record "Data Export Entry";
                    l_cuExportGatewaySalesPrice: Codeunit "CXW Export Gateway Sales Price";
                    l_intCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(l_recDataExportEntry);
                    l_recDataExportEntry.SetRange("Destination Code", l_cuExportGatewaySalesPrice.GetDestinationCode());
                    l_recDataExportEntry.SetRange(Status, l_recDataExportEntry.Status::Error);
                    if l_recDataExportEntry.FindSet(true) then
                        repeat
                            l_recDataExportEntry.Status := l_recDataExportEntry.Status::"CXW Pending";
                            l_recDataExportEntry."Attempt Count" := 0;
                            l_recDataExportEntry."Error Message" := '';
                            l_recDataExportEntry.Modify(true);
                            l_intCount += 1;
                        until l_recDataExportEntry.Next() = 0;

                    Message(RequeuedMsg, l_intCount);
                end;
            }
        }
    }

    var
        RequeuedMsg: Label '%1 sales price entry(ies) set back to pending.', Comment = '%1 = number of requeued entries';
}
