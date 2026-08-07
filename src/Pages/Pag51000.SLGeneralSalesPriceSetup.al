page 51000 "SL General Sales Price Setup"
{
    Caption = 'General Sales Price Setup';
    PageType = Card;
    SourceTable = "SL General Sales Price Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group("Stock Price")
            {
                Caption = 'Stock Price';

                field("Minimum Margin %"; Rec."Minimum Margin %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Watch will be deactivated on WebShop if the sales price is below min. margin';
                }
            }
            group("Non Stock Price Formula")
            {
                Caption = 'Non Stock Price Formula';
                Visible = false;

                grid(GridControl)
                {
                    GridLayout = Rows;

                    group(Cat1)
                    {
                        ShowCaption = false;

                        field("Cat 1 Stock Price From"; Rec."If Stock Price From Cat 1")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 1 Stock Price From';
                            ToolTip = 'Category 1 Stock Price From';
                        }
                        field("Cat 1 Stock Price To"; Rec."If Stock Price To Cat 1")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 1 Stock Price To';
                            ToolTip = 'Category 1 Stock Price To';
                        }
                        field("Cat 1 Non Stock %"; Rec."Cat 1 Non Stock %")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 1 Non Stock %';
                            ToolTip = 'Category 1 Non Stock %';
                        }
                    }
                    group(Cat2)
                    {
                        ShowCaption = false;

                        field("Cat 2 Stock Price From"; Rec."If Stock Price From Cat 2")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 2 Stock Price From';
                            ToolTip = 'Category 2 Stock Price From';
                        }
                        field("Cat 2 Stock Price To"; Rec."If Stock Price To Cat 2")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 2 Stock Price To';
                            ToolTip = 'Category 2 Stock Price To';
                        }
                        field("Cat 2 Non Stock %"; Rec."Cat 2 Non Stock %")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Category 2 Non Stock %';
                        }
                    }
                    group(Cat3)
                    {
                        ShowCaption = false;

                        field("Cat 3 Stock Price From"; Rec."If Stock Price From Cat 3")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 3 Stock Price From';
                            ToolTip = 'Category 3 Stock Price From';
                        }
                        field("Cat 3 Stock Price To"; Rec."If Stock Price To Cat 3")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 3 Stock Price To';
                            ToolTip = 'Category 3 Stock Price To';
                        }
                        field("Cat 3 Non Stock %"; Rec."Cat 3 Non Stock %")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 3 Non Stock %';
                            ToolTip = 'Category 3 Non Stock %';
                        }
                    }
                }
            }
            group(Threshold)
            {
                Caption = 'Threshold';

                field("Stock Price Threshold %"; Rec."Stock Price Threshold %")
                {
                    ApplicationArea = All;
                }
                field("Non Stock Price Threshold %"; Rec."Non Stock Price Threshold %")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
            group(Export)
            {
                Caption = 'Export';

                field("Price Export Active"; Rec."Price Export Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether approved sales prices are sent to an external system via the selected API interface.';
                }
                field("API Interface Code"; Rec."API Interface Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which API interface is used to send approved sales prices to an external system.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(APIInterfaceSetup)
            {
                ApplicationArea = All;
                Caption = 'API Interface Setup';
                ToolTip = 'Open the setup for outbound API interfaces.';
                Image = Setup;
                RunObject = page "SL API Interface Setup";
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
