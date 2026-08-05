page 51001 "SL Sales Price Checking List"
{
    Caption = 'Sales Price Checking List';
    PageType = Worksheet;
    SourceTable = "SL Sales Price Checking";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Validated; Rec.Validated)
                {
                    ApplicationArea = All;
                    Enabled = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                }
                field(FinalPrice; Rec."Stock Price")
                {
                    ApplicationArea = All;
                    Caption = 'FinalPrice';

                    trigger OnValidate()
                    begin
                        if Rec."Stock Price" <> xRec."Stock Price" then
                            Rec.Validated := false;
                    end;
                }
                field("Strike Price"; Rec."Strike Price")
                {
                    ApplicationArea = All;
                }
                field("Recom. Retail Price"; Rec."Recom. Retail Price")
                {
                    ApplicationArea = All;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Enabled = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Non Stock Price"; Rec."Non Stock Price")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Exchange Rate Amount"; Rec."Exchange Rate Amount")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Exchange Rate Date"; Rec."Exchange Rate Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Remark; Rec.Remark)
                {
                    ApplicationArea = All;
                    Enabled = false;
                    Editable = true;
                    Style = StandardAccent;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                }
                field(Approved; Rec."Accept New Setup")
                {
                    ApplicationArea = All;
                    Caption = 'Approved';
                }
                field(Approver; Rec."Approved By")
                {
                    ApplicationArea = All;
                    Caption = 'Approver';
                    Enabled = false;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(GeneralSalesPriceSetup)
            {
                ApplicationArea = All;
                Caption = 'General Sales Price Setup';
                ToolTip = 'Open the general sales price setup (minimum margin, thresholds).';
                Image = Setup;
                RunObject = page "SL General Sales Price Setup";
            }
            action(SalesPriceArchiveNav)
            {
                ApplicationArea = All;
                Caption = 'Sales Price Archive';
                ToolTip = 'Open the archive of previously processed sales prices.';
                Image = History;
                RunObject = page "SL Sales Price Archive";
            }
        }
        area(Processing)
        {
            group(Import)
            {
                Caption = 'Import';
                Image = Worksheet;

                action("Import CSV")
                {
                    ApplicationArea = All;
                    Caption = 'Import CSV';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = New;
                    PromotedIsBig = true;
                    Visible = true;

                    trigger OnAction()
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("Minimum Margin %");
                        g_recGenSPSetup.TestField("Stock Price Threshold %");

                        if Rec.FindFirst() then
                            Error(TXT009);

                        Xmlport.Run(Xmlport::"SL Import Sales Price", false, true);
                    end;
                }
                action(Validate)
                {
                    ApplicationArea = All;
                    Caption = 'Validate';
                    Image = CheckList;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("Minimum Margin %");
                        g_recGenSPSetup.TestField("Stock Price Threshold %");

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange(Validated, true);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetFilter("Stock Price", '>%1', 0);
                        if g_recSalesPriceCheck.FindSet() then
                            repeat
                                g_recSalesPriceCheck."Stock Price" := Round(g_recSalesPriceCheck."Stock Price", 10, '>');
                                if g_recSalesPriceCheck."Recom. Retail Price" > 0 then
                                    g_recSalesPriceCheck."Recom. Retail Price" := Round(g_recSalesPriceCheck."Recom. Retail Price", 10, '>');
                                if g_recSalesPriceCheck."Strike Price" > 0 then
                                    g_recSalesPriceCheck."Strike Price" := Round(g_recSalesPriceCheck."Strike Price", 10, '>');

                                g_recSalesPriceCheck.Modify();
                            until g_recSalesPriceCheck.Next() = 0;

                        fnValidate();

                        Message('validate data is done');
                    end;
                }
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = AdjustVATExemption;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        l_recSalesPriceCheck: Record "SL Sales Price Checking";
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("Minimum Margin %");
                        g_recGenSPSetup.TestField("Stock Price Threshold %");

                        g_recSalesPriceCheck.Reset();
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange(Validated, false);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange("Accept New Setup", true);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        if Confirm('Are you sure want to Accept New Price Setup?', false) then begin
                            l_recSalesPriceCheck.Reset();
                            if l_recSalesPriceCheck.FindSet() then begin
                                repeat
                                    l_recSalesPriceCheck."Accept New Setup" := true;
                                    l_recSalesPriceCheck."Remark Backup" := Rec.Remark;
                                    l_recSalesPriceCheck.Remark := '';
                                    l_recSalesPriceCheck."Approved By" := UserId;
                                    l_recSalesPriceCheck.Modify();
                                until l_recSalesPriceCheck.Next() = 0;
                                Message('done');
                            end;
                        end;
                    end;
                }
                action("Add all Currencies")
                {
                    ApplicationArea = All;
                    Caption = 'Add all Currencies';
                    Image = Add;
                    Promoted = true;
                    PromotedCategory = New;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("Minimum Margin %");
                        g_recGenSPSetup.TestField("Stock Price Threshold %");

                        g_recSalesPriceCheck.Reset();
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();

                        g_recSalesPriceCheck.SetRange("Currencies Processed", false);
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange(Validated, false);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange("Accept New Setup", false);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error('Nothing to process');

                        g_recSalesPriceCheck.Reset();

                        g_recSalesPriceCheck.SetRange("Currencies Processed", false);
                        if g_recSalesPriceCheck.FindSet() then
                            repeat
                                g_recCurrencies.Reset();
                                g_recCurrencies.SetFilter(Code, '<>%1', 'DE');
                                g_recCurrencies.SetRange("Sales Price Activated", true);
                                if g_recCurrencies.FindSet() then
                                    repeat
                                        if (g_recCurrencies."Code" <> '') and
                                           (g_recCurrencies."Code" <> g_recSalesPriceCheck."Currency Code") and
                                           (not g_recSalesPriceCheck2.Get(g_recSalesPriceCheck."Item No.", g_recSalesPriceCheck."Variant Code", g_recCurrencies."Code"))
                                        then begin
                                            g_recSalesPriceCheck2.Init();
                                            g_recSalesPriceCheck2."Item No." := g_recSalesPriceCheck."Item No.";
                                            g_recSalesPriceCheck2."Variant Code" := g_recSalesPriceCheck."Variant Code";

                                            g_recSalesPriceCheck2."Currency Code" := g_recCurrencies."Code";
                                            g_recCurrExcRate.Reset();
                                            g_recCurrExcRate.SetRange("Currency Code", g_recSalesPriceCheck2."Currency Code");
                                            if g_recCurrExcRate.FindLast() then begin
                                                g_recCurrExcRate.GetLastestExchangeRate(g_recSalesPriceCheck2."Currency Code", g_dateExchangeRateDate, g_decExchangeRateAmt);
                                                g_recSalesPriceCheck2."Stock Price" := g_recSalesPriceCheck."Stock Price" * (1 / g_decExchangeRateAmt);
                                                g_recSalesPriceCheck2."Recom. Retail Price" := g_recSalesPriceCheck."Recom. Retail Price" * (1 / g_decExchangeRateAmt);
                                                g_recSalesPriceCheck2."Strike Price" := g_recSalesPriceCheck."Strike Price" * (1 / g_decExchangeRateAmt);
                                                g_recSalesPriceCheck2."Exchange Rate Amount" := 1 / g_decExchangeRateAmt;
                                                g_recSalesPriceCheck2."Exchange Rate Date" := g_dateExchangeRateDate;
                                            end;
                                            g_recSalesPriceCheck2."Starting Date" := g_recSalesPriceCheck."Starting Date";
                                            g_recSalesPriceCheck2."Starting Time" := g_recSalesPriceCheck."Starting Time";
                                            g_recSalesPriceCheck2."Ending Date" := g_recSalesPriceCheck."Ending Date";
                                            g_recSalesPriceCheck2."Ending Time" := g_recSalesPriceCheck."Ending Time";
                                            g_recSalesPriceCheck2."Reason Code" := g_recSalesPriceCheck."Reason Code";
                                            g_recSalesPriceCheck2.Comment := g_recSalesPriceCheck.Comment;
                                            g_recSalesPriceCheck2.Validated := true;
                                            g_recSalesPriceCheck2."Approved By" := g_recSalesPriceCheck."Approved By";
                                            g_recSalesPriceCheck2."Accept New Setup" := g_recSalesPriceCheck."Accept New Setup";
                                            g_recSalesPriceCheck2.Insert(true);
                                        end;
                                    until g_recCurrencies.Next() = 0;
                                UpdateSalesPriceCheck.Get(g_recSalesPriceCheck."Item No.", g_recSalesPriceCheck."Variant Code", g_recSalesPriceCheck."Currency Code");
                                UpdateSalesPriceCheck."Currencies Processed" := true;
                                UpdateSalesPriceCheck.Modify();
                            until g_recSalesPriceCheck.Next() = 0;

                        Message('done');
                    end;
                }
            }
            group(Export)
            {
                Caption = 'Export';
                Image = ExportFile;

                action("Upload Sales Price")
                {
                    ApplicationArea = All;
                    Caption = 'Upload Sales Price';
                    ToolTip = 'Exports the approved sales prices to the outbound interface file.';
                    Image = SendConfirmation;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        l_recSalesPriceCheck: Record "SL Sales Price Checking";
                        l_recSP: Record "Sales Price";
                        l_intTotal: Integer;
                        l_intExported: Integer;
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("Price Export Active", true);

                        l_recSalesPriceCheck.Reset();
                        l_recSalesPriceCheck.SetRange("Accept New Setup", true);
                        l_recSalesPriceCheck.SetRange("Export Processed", false);
                        if not l_recSalesPriceCheck.FindSet() then
                            Error('Nothing to process');

                        repeat
                            l_intTotal += 1;
                            l_recSP.Reset();
                            l_recSP.SetRange("Item No.", l_recSalesPriceCheck."Item No.");
                            l_recSP.SetRange("Variant Code", l_recSalesPriceCheck."Variant Code");
                            l_recSP.SetRange("Currency Code", l_recSalesPriceCheck."Currency Code");
                            if l_recSP.FindFirst() then begin
                                g_cuExportGatewaySalesPrice.CreateExternalInterfaceFile(l_recSP);
                                l_recSalesPriceCheck."Export Processed" := true;
                                l_recSalesPriceCheck.Modify();
                                l_intExported += 1;
                            end;
                        until l_recSalesPriceCheck.Next() = 0;

                        Message(ExportResultMsg, l_intExported, l_intTotal);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Rec."Accept New Setup" then
            Error('not possible');

    end;

    var
        g_recSP: Record "Sales Price";
        g_recSalesPriceCheck: Record "SL Sales Price Checking";
        g_recSalesPriceCheck2: Record "SL Sales Price Checking";
        TXT001: Label 'New Final Price %1% less than existing Final Price %2', Comment = '%1 = percent, %2 = old price';
        g_recILE: Record "Item Ledger Entry";
        g_decSPExclVAT: Decimal;
        g_decProfit: Decimal;
        g_decProfitPercent: Decimal;
        TXT003: Label 'New Final Price has %1% profit, less than %2% setup margin';
        g_recCurrencies: Record currency;
        TXT005: Label 'Currency Code %1 is not set for Country %2';

        TXT006: Label 'Starting Date %1 cannot be greater than Ending Date %2';
        MissingCountryCodeErr: Label 'Item %1, variant %2 has no country code. Please set a country code in the imported file or fill it in manually before validating.', Comment = '%1 = item no., %2 = variant code';
        g_recCurrExcRate: Record "Currency Exchange Rate";
        g_dateExchangeRateDate: Date;
        g_decExchangeRateAmt: Decimal;
        ProgressWindow: Dialog;
        TotalCount: Integer;
        CountToValidate: Integer;
        TXT007: Label 'New Final Price %1% greater than existing Final Price %2';
        g_decStockPricePercentFromPrev: Decimal;
        g_decNonStockPricePercentFromPrev: Decimal;
        g_recGenSPSetup: Record "SL General Sales Price Setup";
        TXT009: Label 'Please delete existing entries to import new price';
        UpdateSalesPriceCheck: Record "SL Sales Price Checking";
        g_cuExportGatewaySalesPrice: Codeunit "SL Export Gateway Sales Price";
        ExportResultMsg: Label '%1 of %2 approved lines exported. Lines already exported or without a matching sales price were skipped.', Comment = '%1 = number of lines actually exported, %2 = number of approved lines considered';

    local procedure fnValidate()
    begin
        g_recSalesPriceCheck.Reset();
        g_recSalesPriceCheck.SetRange(Validated, false);
        if g_recSalesPriceCheck.FindSet() then begin
            ProgressWindow.Open('Validating Sales Price @1@@@@@@@@@@@@@@@');
            TotalCount := g_recSalesPriceCheck.Count();
            repeat
                Clear(g_recSalesPriceCheck.Remark);
                Clear(g_decStockPricePercentFromPrev);
                Clear(g_decNonStockPricePercentFromPrev);

                g_recSP.Reset();
                g_recSP.SetRange("Item No.", g_recSalesPriceCheck."Item No.");
                g_recSP.SetRange("Variant Code", g_recSalesPriceCheck."Variant Code");
                g_recSP.SetRange("Currency Code", g_recSalesPriceCheck."Currency Code");
                g_recSP.SetRange("Starting Date", g_recSalesPriceCheck."Starting Date");
                if g_recSP.FindFirst() then begin
                    g_recSalesPriceCheck."Old Stock Price" := g_recSP."Unit Price (LCY)";
                    if g_recSalesPriceCheck."Stock Price" < g_recSP."Unit Price (LCY)" then
                        g_recSalesPriceCheck.Remark :=
                            StrSubstNo(
                                TXT001,
                                Round(((g_recSP."Unit Price (LCY)" - g_recSalesPriceCheck."Stock Price") / g_recSP."Unit Price (LCY)") * 100, 0.01, '='),
                                g_recSP."Unit Price (LCY)");

                    g_decStockPricePercentFromPrev :=
                        Round(((g_recSalesPriceCheck."Stock Price" - g_recSP."Unit Price (LCY)") / g_recSP."Unit Price (LCY)") * 100, 0.01, '=');
                    if (g_recSalesPriceCheck."Stock Price" > g_recSP."Unit Price (LCY)") and
                       (g_decStockPricePercentFromPrev > g_recGenSPSetup."Stock Price Threshold %")
                    then
                        g_recSalesPriceCheck.Remark := StrSubstNo(TXT007, g_decStockPricePercentFromPrev, g_recSP."Unit Price (LCY)");
                end;

                g_decSPExclVAT := 0;
                g_decProfit := 0;
                g_decProfitPercent := 0;

                g_recILE.Reset();
                g_recILE.SetRange("Item No.", g_recSalesPriceCheck."Item No.");
                g_recILE.SetRange("Variant Code", g_recSalesPriceCheck."Variant Code");
                g_recILE.SetRange("Invoiced Quantity", 1);
                g_recILE.SetRange("Location Code", 'HL');
                if g_recILE.FindLast() then begin
                    g_recILE.CalcFields("Cost Amount (Actual)");
                    g_decSPExclVAT := (g_recSalesPriceCheck."Stock Price" * 100) / 119;
                    g_decProfit := g_decSPExclVAT - g_recILE."Cost Amount (Actual)";
                    g_decProfitPercent := Round((g_decProfit / g_decSPExclVAT) * 100, 0.01, '=');
                    if g_decProfitPercent < g_recGenSPSetup."Minimum Margin %" then
                        g_recSalesPriceCheck.Remark := StrSubstNo(TXT003, g_decProfitPercent, g_recGenSPSetup."Minimum Margin %");
                end;

                if (g_recSalesPriceCheck."Starting Date" > g_recSalesPriceCheck."Ending Date") and (g_recSalesPriceCheck."Ending Date" <> 0D) then
                    g_recSalesPriceCheck.Remark := StrSubstNo(TXT006, g_recSalesPriceCheck."Starting Date", g_recSalesPriceCheck."Ending Date");

                if g_recSalesPriceCheck."Accept New Setup" then
                    g_recSalesPriceCheck.Remark := '';

                g_recSalesPriceCheck.Validated := true;

                g_recSalesPriceCheck.Modify();
                CountToValidate += 1;
                ProgressWindow.Update(1, Round(CountToValidate / TotalCount * 10000, 1));
            until g_recSalesPriceCheck.Next() = 0;
            ProgressWindow.Close();
        end;
    end;

    procedure fnCalcNonStockPrice(p_decStockPriceFrom: Decimal; p_decStockPriceTo: Decimal; p_decNonStockPercent: Decimal)
    begin
        g_recSalesPriceCheck2.Reset();
        g_recSalesPriceCheck2.SetRange("Non Stock Price", 0);
        g_recSalesPriceCheck2.SetFilter("Stock Price", '%1..%2', p_decStockPriceFrom, p_decStockPriceTo);
        if g_recSalesPriceCheck2.FindSet() then
            repeat
                if g_recSalesPriceCheck2."Currency Code" <> '' then begin
                    g_recCurrExcRate.Reset();
                    g_recCurrExcRate.SetRange("Currency Code", g_recSalesPriceCheck2."Currency Code");
                    if g_recCurrExcRate.FindLast() then begin
                        g_recCurrExcRate.GetLastestExchangeRate(g_recSalesPriceCheck2."Currency Code", g_dateExchangeRateDate, g_decExchangeRateAmt);
                        g_recSalesPriceCheck2."Non Stock Price" :=
                            ((g_recSalesPriceCheck2."Stock Price" / (1 / g_decExchangeRateAmt)) +
                             ((g_recSalesPriceCheck2."Stock Price" / (1 / g_decExchangeRateAmt)) * p_decNonStockPercent / 100)) * (1 / g_decExchangeRateAmt);
                    end;
                end else
                    g_recSalesPriceCheck2."Non Stock Price" :=
                        g_recSalesPriceCheck2."Stock Price" + (g_recSalesPriceCheck2."Stock Price" * p_decNonStockPercent / 100);
                g_recSalesPriceCheck2.Modify();
            until g_recSalesPriceCheck2.Next() = 0;
    end;
}
