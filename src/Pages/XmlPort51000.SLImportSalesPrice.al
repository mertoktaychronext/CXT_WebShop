xmlport 51000 "SL Import Sales Price"
{
    Caption = 'Import Sales Price';
    Direction = Import;
    Format = VariableText;
    TextEncoding = UTF8;

    schema
    {
        textelement(ImportSalesPrice)
        {
            tableelement(SalesPriceChecking; "SL Sales Price Checking")
            {
                XmlName = 'SalesPrice';
                SourceTableView = sorting("Item No.", "Variant Code", "Currency Code");

                fieldelement(ItemNo; SalesPriceChecking."Item No.")
                {
                    MinOccurs = Zero;
                }
                fieldelement(VarCode; SalesPriceChecking."Variant Code")
                {
                    MinOccurs = Zero;
                }
                fieldelement(StockPrice; SalesPriceChecking."Stock Price")
                {
                    MinOccurs = Zero;
                }
                fieldelement(StrikePrice; SalesPriceChecking."Strike Price")
                {
                }
                fieldelement(RecomRetailPrice; SalesPriceChecking."Recom. Retail Price")
                {
                }
                fieldelement(CurrencyCode; SalesPriceChecking."Currency Code")
                {
                    MinOccurs = Zero;
                }

                fieldelement(ReasonCode; SalesPriceChecking."Reason Code")
                {
                }
                fieldelement("Comment"; SalesPriceChecking.Comment)
                {
                }

                trigger OnAfterInitRecord()
                begin
                    if g_booCaptionRow then begin
                        g_booCaptionRow := false;
                        CurrXmlPort.Skip();
                    end;
                end;

                trigger OnAfterInsertRecord()
                begin
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Option';
                    Visible = false;

                    field(SetPriceForAllCountries; g_booAllCountries)
                    {
                        ApplicationArea = All;
                        Caption = 'Set Price for All Countries';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            g_booAllCountries := false;
        end;
    }

    trigger OnPreXmlPort()
    begin
        g_booCaptionRow := true;
    end;

    trigger OnPostXmlPort()
    begin
        Message('done');
    end;

    var
        g_booCaptionRow: Boolean;
        g_booAllCountries: Boolean;
}
