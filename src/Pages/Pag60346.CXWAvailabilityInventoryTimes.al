page 60346 "CXW Availability Inv. Times"
{
    Caption = 'Availability Inventory Times';
    PageType = List;
    SourceTable = "CXW Availability Inv. Time";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = true;
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("CXW Item No."; Rec."CXW Item No.")
                {
                    ApplicationArea = All;
                }
                field("CXW Variant Code"; Rec."CXW Variant Code")
                {
                    ApplicationArea = All;
                }
                field("CXW Country/Region Code"; Rec."CXW Country/Region Code")
                {
                    ApplicationArea = All;
                }
                field("CXW Inventory Type"; Rec."CXW Inventory Type")
                {
                    ApplicationArea = All;
                }
                field("CXW Delivery Days"; Rec."CXW Delivery Days")
                {
                    ApplicationArea = All;
                }
                field("CXW Exported"; Rec."CXW Exported")
                {
                    ApplicationArea = All;
                }
                field("CXW Exported At"; Rec."CXW Exported At")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteSelectedEntries)
            {
                ApplicationArea = All;
                Caption = 'Delete Selected Entries';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Deletes the selected inventory time entries.';

                trigger OnAction()
                var
                    SelectedEntryCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    SelectedEntryCount := Rec.Count();
                    if not Confirm(DeleteSelectedQst, false, SelectedEntryCount) then
                        exit;

                    Rec.DeleteAll(true);
                    CurrPage.Update(false);
                end;
            }
            action(ExportOpenEntries)
            {
                ApplicationArea = All;
                Caption = 'Export Open Entries';
                Image = Export;
                ToolTip = 'Sends the selected inventory time entries that have not yet been exported to the UPDIN interface.';

                trigger OnAction()
                var
                    ExportAvailabilityChanges: Codeunit "CXW Export Availability Change";
                    ExportedCount: Integer;
                    FailedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    ExportAvailabilityChanges.ExportSelectedInventoryTimes(Rec, ExportedCount, FailedCount);
                    Message(ExportResultMsg, ExportedCount, FailedCount);
                end;
            }
        }
    }

    var
        ExportResultMsg: Label '%1 inventory time entries exported successfully. %2 entries could not be exported; see the HTTP call log for details.', Comment = '%1 = successful exports, %2 = failed exports';
        DeleteSelectedQst: Label 'Do you want to delete %1 selected inventory time entry(ies)?', Comment = '%1 = selected entry count';
}
