xmlport 60328 "CXW Import Sales Price"
{
    Caption = 'Import Sales Price';
    Direction = Import;
    Format = VariableText;
    TextEncoding = UTF8;

    schema
    {
        textelement(ImportSalesPrice)
        {
            tableelement(SalesPriceChecking; "CXW Sales Price Checking")
            {
                XmlName = 'SalesPrice';
                SourceTableView = sorting("CXW Item No.", "CXW Currency Code", "CXW Country Code");

                fieldelement(ItemNo; SalesPriceChecking."CXW Item No.")
                {
                    MinOccurs = Zero;
                }
                fieldelement(StockPrice; SalesPriceChecking."CXW Stock Price")
                {
                    MinOccurs = Zero;
                }
                fieldelement(StrikePrice; SalesPriceChecking."CXW Strike Price")
                {
                }
                fieldelement(RecomRetailPrice; SalesPriceChecking."CXW Recom. Retail Price")
                {
                }
                fieldelement(CurrencyCode; SalesPriceChecking."CXW Currency Code")
                {
                    MinOccurs = Zero;
                }

                fieldelement(ReasonCode; SalesPriceChecking."CXW Reason Code")
                {
                }
                fieldelement("Comment"; SalesPriceChecking."CXW Comment")
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
        Message(ImportDoneMsg);
    end;

    var
        g_booCaptionRow: Boolean;
        g_booAllCountries: Boolean;
        ImportDoneMsg: Label 'done';
}
