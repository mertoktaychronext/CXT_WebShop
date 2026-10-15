page 60347 "CXWAvailabilityChange Entries"
{
    Caption = 'Availability Change Entries';
    PageType = List;
    SourceTable = "CXW Availability Change Entry";
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
                field("CXW Entry No."; Rec."CXW Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number of this availability change entry.';
                }
                field("CXW Item No."; Rec."CXW Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number of the moved article.';
                }
                field("CXW Variant Code"; Rec."CXW Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the variant code of the moved article.';
                }
                field("CXW Location Code"; Rec."CXW Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the location code involved in the availability change.';
                }
                field("CXW Item Ledger Entry No."; Rec."CXW Item Ledger Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item ledger entry that triggered this availability change.';
                }
                field("CXW Inventory Quantity"; Rec."CXW Inventory Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the available inventory quantity after all reservations have been deducted.';
                }
                field("CXW Differential Taxation Purchase"; Rec."CXW Diff. Taxation Purchase")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the triggering item ledger entry is subject to differential taxation.';
                }
                field("CXW Changed At"; Rec."CXW Changed At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the stock or reservation details were last refreshed.';
                }
                field("CXW Exported"; Rec."CXW Exported")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the availability change entry has already been exported.';
                }
                field("CXW Exported At"; Rec."CXW Exported At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the availability change entry was exported.';
                }
                field("CXW Deli. Time Exported"; Rec."CXW Deli. Time Exported")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the delivery times of the article have been sent to the UPDDLT interface for this entry.';
                }
                field("CXW Deli. Time Exported At"; Rec."CXW Deli. Time Exported At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the delivery times of the article were sent to the UPDDLT interface for this entry.';
                }
                field("CXW Inv. Time Exported"; Rec."CXW Inv. Time Exported")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the inventory times of the article have been sent to the UPDIN interface for this entry.';
                }
                field("CXW Inv. Time Exported At"; Rec."CXW Inv. Time Exported At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the inventory times of the article were sent to the UPDIN interface for this entry.';
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
                ToolTip = 'Deletes the selected availability change entries.';

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
                ToolTip = 'Sends the selected availability change entries that have not yet been exported to the UPDSTOFILE interface.';
                Image = Export;

                trigger OnAction()
                var
                    ExportAvailabilityChanges: Codeunit "CXW Export Availability Change";
                    ExportedCount: Integer;
                    FailedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    ExportAvailabilityChanges.ExportSelectedEntries(Rec, ExportedCount, FailedCount);
                    Message(ExportResultMsg, ExportedCount, FailedCount);
                end;
            }
        }
    }

    var
        ExportResultMsg: Label '%1 availability change entries exported successfully. %2 entries could not be exported; see the HTTP call log for details.', Comment = '%1 = successful exports, %2 = failed exports';
        DeleteSelectedQst: Label 'Do you want to delete %1 selected availability change entry(ies)?', Comment = '%1 = selected entry count';
}
