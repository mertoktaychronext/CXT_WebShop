page 60320 "CXW Sales Price Export Entries"
{
    Caption = 'Sales Price Export Entries';
    PageType = List;
    SourceTable = "CXW Sales Price Export";
    SourceTableView = sorting("CXW Entry No.") order(descending);
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("CXW Entry No."; Rec."CXW Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the sales price export entry.';
                }
                field("CXW Item No."; Rec."CXW Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item the price was released for.';
                }
                field("CXW Country Code"; Rec."CXW Country Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country the price was released for.';
                }
                field("CXW Currency Code"; Rec."CXW Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the released price. Blank means local currency.';
                }
                field("CXW Unit Price"; Rec."CXW Unit Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the released final price in the currency of the country.';
                }
                field("CXW Unit Price (LCY)"; Rec."CXW Unit Price (LCY)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the released final price converted to local currency at release time.';
                }
                field("CXW Strike Price"; Rec."CXW Strike Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the released strike price.';
                }
                field("CXW Recom. Retail Price"; Rec."CXW Recom. Retail Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the released recommended retail price.';
                }
                field("CXW Non Stock Price"; Rec."CXW Non Stock Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the released non-stock price.';
                }
                field("CXW Starting Date"; Rec."CXW Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("CXW Starting Time"; Rec."CXW Starting Time")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the time from which the price is valid.';
                }
                field("CXW Ending Date"; Rec."CXW Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date until which the price is valid.';
                }
                field("CXW Ending Time"; Rec."CXW Ending Time")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the time until which the price is valid.';
                }
                field("CXW Exchange Rate Amount"; Rec."CXW Exchange Rate Amount")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the exchange rate captured on the sales price line.';
                }
                field("CXW Exchange Rate Date"; Rec."CXW Exchange Rate Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the date of the exchange rate captured on the sales price line.';
                }
                field("CXW Reason Code"; Rec."CXW Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason for the price change.';
                }
                field("CXW Comment"; Rec."CXW Comment")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the comment of the sales price line.';
                }
                field("CXW Remark"; Rec."CXW Remark")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the remark of the sales price line.';
                }
                field("CXW Last Modified UserID"; Rec."CXW Last Modified UserID")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies who last changed the sales price line before release.';
                }
                field("CXW Last Modified Date"; Rec."CXW Last Modified Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies when the sales price line was last changed before release.';
                }
                field("CXW Export Status"; Rec."CXW Export Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current status of the related data export entry.';
                }
                field("CXW Data Export Entry No."; Rec."CXW Data Export Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the data export entry that sends this price.';

                    trigger OnDrillDown()
                    begin
                        ShowDataExportEntry();
                    end;
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ApplicationArea = All;
                    Caption = 'Released At';
                    ToolTip = 'Specifies when the price was released.';
                }
                field(SystemCreatedBy; ReleasedByUserName)
                {
                    ApplicationArea = All;
                    Caption = 'Released By';
                    ToolTip = 'Specifies who released the price.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(DataExportEntry)
            {
                ApplicationArea = All;
                Caption = 'Data Export Entry';
                ToolTip = 'Open the data export entry that sends this price.';
                Image = ExportFile;

                trigger OnAction()
                begin
                    ShowDataExportEntry();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        l_recUser: Record User;
    begin
        ReleasedByUserName := '';
        if l_recUser.Get(Rec.SystemCreatedBy) then
            ReleasedByUserName := l_recUser."User Name";
    end;

    var
        ReleasedByUserName: Code[50];

    local procedure ShowDataExportEntry()
    var
        l_recDataExportEntry: Record "Data Export Entry";
    begin
        l_recDataExportEntry.SetRange("Entry No.", Rec."CXW Data Export Entry No.");
        Page.Run(Page::"Data Export Entries", l_recDataExportEntry);
    end;
}
