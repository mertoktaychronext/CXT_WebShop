page 60321 "CXW General Sales Price Setup"
{
    Caption = 'General Sales Price Setup';
    PageType = Card;
    SourceTable = "CXW General Sales Price Setup";
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

                field("CXW Minimum Margin %"; Rec."CXW Minimum Margin %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Watch will be deactivated on WebShop if the sales price is below min. margin';
                }
                field("CXW Prices Incl. VAT"; Rec."CXW Prices Incl. VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default value for Price Includes VAT on manually created and imported sales price checking lines.';
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

                        field("Cat 1 Stock Price From"; Rec."CXW If Stock Price From Cat 1")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 1 Stock Price From';
                            ToolTip = 'Category 1 Stock Price From';
                        }
                        field("Cat 1 Stock Price To"; Rec."CXW If Stock Price To Cat 1")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 1 Stock Price To';
                            ToolTip = 'Category 1 Stock Price To';
                        }
                        field("CXW Cat 1 Non Stock %"; Rec."CXW Cat 1 Non Stock %")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 1 Non Stock %';
                            ToolTip = 'Category 1 Non Stock %';
                        }
                    }
                    group(Cat2)
                    {
                        ShowCaption = false;

                        field("Cat 2 Stock Price From"; Rec."CXW If Stock Price From Cat 2")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 2 Stock Price From';
                            ToolTip = 'Category 2 Stock Price From';
                        }
                        field("Cat 2 Stock Price To"; Rec."CXW If Stock Price To Cat 2")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 2 Stock Price To';
                            ToolTip = 'Category 2 Stock Price To';
                        }
                        field("CXW Cat 2 Non Stock %"; Rec."CXW Cat 2 Non Stock %")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Category 2 Non Stock %';
                        }
                    }
                    group(Cat3)
                    {
                        ShowCaption = false;

                        field("Cat 3 Stock Price From"; Rec."CXW If Stock Price From Cat 3")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 3 Stock Price From';
                            ToolTip = 'Category 3 Stock Price From';
                        }
                        field("Cat 3 Stock Price To"; Rec."CXW If Stock Price To Cat 3")
                        {
                            ApplicationArea = All;
                            Caption = 'Cat 3 Stock Price To';
                            ToolTip = 'Category 3 Stock Price To';
                        }
                        field("CXW Cat 3 Non Stock %"; Rec."CXW Cat 3 Non Stock %")
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

                field("CXW Stock Price Threshold %"; Rec."CXW Stock Price Threshold %")
                {
                    ApplicationArea = All;
                }
                field("CXW Non Stock Price Thresh %"; Rec."CXW Non Stock Price Thresh %")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
            group(Export)
            {
                Caption = 'Export';

                field("CXW Price Export Active"; Rec."CXW Price Export Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether approved sales prices are sent to an external system via the selected API interface.';
                }
                field("CXW API Interface Code"; Rec."CXW API Interface Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which API interface is used to send approved sales prices to an external system.';
                }
                field("CXW Max. Export Attempts"; Rec."CXW Max. Export Attempts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how often the sales price export job tries to send a price. After that, the entry stays in status Error until it is requeued manually.';
                }
                field("CXW Archive Country Code"; Rec."CXW Archive Country Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country whose released sales prices are written to the sales price archive. Prices of all other countries are only kept in the sales price export entries.';
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
                RunObject = page "CXW API Interface Setup";
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
