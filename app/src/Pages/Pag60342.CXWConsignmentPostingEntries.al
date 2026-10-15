page 60342 "CXW Cons. Posting Entries"
{
    Caption = 'Consignment Posting Entries';
    PageType = List;
    SourceTable = "CXW Consignment Posting Entry";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("CXW Entry No"; Rec."CXW Entry No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field("CXW Item No."; Rec."CXW Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the consignment item that was sold.';
                }
                field("CXW Purchase Order No."; Rec."CXW Purchase Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the purchase order to be invoiced for this consignment sale.';
                }
                field("CXW Sales Invoice No."; Rec."CXW Sales Invoice No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted sales invoice that triggered this entry.';
                }
                field("CXW Sales Posting Date"; Rec."CXW Sales Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the triggering sales invoice.';
                }
                field("CXW Due Date"; Rec."CXW Due Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date from which the purchase invoice may be posted automatically.';
                }
                field("CXW Status"; Rec."CXW Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the processing status of this entry.';
                }
                field("CXW Error Text"; Rec."CXW Error Text")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last error encountered while processing this entry.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Retry)
            {
                ApplicationArea = All;
                Caption = 'Retry';
                ToolTip = 'Resets the selected entries with status Error back to Open so they are processed again on the next run.';
                Image = ResetStatus;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    ConsignmentPostingEntry: Record "CXW Consignment Posting Entry";
                begin
                    CurrPage.SetSelectionFilter(ConsignmentPostingEntry);
                    ConsignmentPostingEntry.SetRange("CXW Status", ConsignmentPostingEntry."CXW Status"::Error);
                    if ConsignmentPostingEntry.FindSet() then
                        repeat
                            ConsignmentPostingEntry."CXW Status" := ConsignmentPostingEntry."CXW Status"::Open;
                            ConsignmentPostingEntry."CXW Error Text" := '';
                            ConsignmentPostingEntry.Modify();
                        until ConsignmentPostingEntry.Next() = 0;

                    CurrPage.Update(false);
                end;
            }
        }
    }
}
