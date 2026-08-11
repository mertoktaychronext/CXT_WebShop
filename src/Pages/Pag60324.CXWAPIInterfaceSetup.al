page 60324 "CXW API Interface Setup"
{
    Caption = 'API Interface Setup';
    PageType = List;
    SourceTable = "CXW API Interface Setup";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("CXW Code"; Rec."CXW Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code of this API interface.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"CXW API Interface Setup Card", Rec);
                    end;
                }
                field("CXW Description"; Rec."CXW Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of this API interface.';
                }
                field("CXW Endpoint URL"; Rec."CXW Endpoint URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the endpoint URL that data is sent to.';
                }
                field("CXW Auth Type"; Rec."CXW Auth Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how requests to this endpoint are authenticated.';
                }
                field("CXW Active"; Rec."CXW Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this interface can be selected and used for sending data.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(EditDetails)
            {
                ApplicationArea = All;
                Caption = 'Edit Details';
                ToolTip = 'Open the full setup details for this interface, including authentication fields relevant to its auth type.';
                Image = Setup;
                RunObject = page "CXW API Interface Setup Card";
                RunPageOnRec = true;
            }
        }
    }
}
