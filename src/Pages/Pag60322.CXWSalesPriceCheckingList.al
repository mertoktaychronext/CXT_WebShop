page 60322 "CXW Sales Price Checking List"
{
    Caption = 'Sales Price Checking List';
    PageType = Worksheet;
    SourceTable = "CXW Sales Price Checking";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("CXW Validated"; Rec."CXW Validated")
                {
                    ApplicationArea = All;
                    Enabled = false;
                }
                field("CXW Item No."; Rec."CXW Item No.")
                {
                    ApplicationArea = All;
                }
                field(FinalPrice; Rec."CXW Stock Price")
                {
                    ApplicationArea = All;
                    Caption = 'FinalPrice';

                    trigger OnValidate()
                    begin
                        if Rec."CXW Stock Price" <> xRec."CXW Stock Price" then
                            Rec."CXW Validated" := false;
                    end;
                }
                field("CXW Strike Price"; Rec."CXW Strike Price")
                {
                    ApplicationArea = All;
                }
                field("CXW Recom. Retail Price"; Rec."CXW Recom. Retail Price")
                {
                    ApplicationArea = All;
                }
                field("CXW Currency Code"; Rec."CXW Currency Code")
                {
                    ApplicationArea = All;
                    Enabled = false;
                }
                field("CXW Country Code"; Rec."CXW Country Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country/region the line was created for by Add all Countries. Blank for imported source lines.';

                }
                field("CXW Price Includes VAT"; Rec."CXW Price Includes VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the final price includes VAT. This value is copied to generated country lines and the final sales price.';
                }
                field("CXW Starting Date"; Rec."CXW Starting Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("CXW Starting Time"; Rec."CXW Starting Time")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("CXW Ending Date"; Rec."CXW Ending Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("CXW Ending Time"; Rec."CXW Ending Time")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("CXW Non Stock Price"; Rec."CXW Non Stock Price")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("CXW Exchange Rate Amount"; Rec."CXW Exchange Rate Amount")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("CXW Exchange Rate Date"; Rec."CXW Exchange Rate Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("CXW Remark"; Rec."CXW Remark")
                {
                    ApplicationArea = All;
                    Enabled = false;
                    Editable = true;
                    Style = StandardAccent;
                }
                field("CXW Reason Code"; Rec."CXW Reason Code")
                {
                    ApplicationArea = All;
                }
                field("CXW Comment"; Rec."CXW Comment")
                {
                    ApplicationArea = All;
                }
                field(Approved; Rec."CXW Accept New Setup")
                {
                    ApplicationArea = All;
                    Caption = 'Approved';
                }
                field(Approver; Rec."CXW Approved By")
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
                RunObject = page "CXW General Sales Price Setup";
            }
            action(SalesPriceArchiveNav)
            {
                ApplicationArea = All;
                Caption = 'Sales Price Archive';
                ToolTip = 'Open the archive of previously processed sales prices.';
                Image = History;
                RunObject = page "CXW Sales Price Archive";
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
                        g_recGenSPSetup.TestField("CXW Minimum Margin %");
                        g_recGenSPSetup.TestField("CXW Stock Price Threshold %");

                        if Rec.FindFirst() then
                            Error(TXT009);

                        Xmlport.Run(Xmlport::"CXW Import Sales Price", false, true);
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
                        g_recGenSPSetup.TestField("CXW Minimum Margin %");
                        g_recGenSPSetup.TestField("CXW Stock Price Threshold %");

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange("CXW Validated", true);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error(NothingToProcessErr);

                        g_recSalesPriceCheck.Reset();
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error(NothingToProcessErr);

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetFilter("CXW Stock Price", '>%1', 0);
                        if g_recSalesPriceCheck.FindSet() then
                            repeat
                                g_recSalesPriceCheck."CXW Stock Price" := Round(g_recSalesPriceCheck."CXW Stock Price", 10, '>');
                                if g_recSalesPriceCheck."CXW Recom. Retail Price" > 0 then
                                    g_recSalesPriceCheck."CXW Recom. Retail Price" := Round(g_recSalesPriceCheck."CXW Recom. Retail Price", 10, '>');
                                if g_recSalesPriceCheck."CXW Strike Price" > 0 then
                                    g_recSalesPriceCheck."CXW Strike Price" := Round(g_recSalesPriceCheck."CXW Strike Price", 10, '>');

                                g_recSalesPriceCheck.Modify();
                            until g_recSalesPriceCheck.Next() = 0;

                        fnValidate();

                        Message(ValidateDoneMsg);
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
                        l_recSalesPriceCheck: Record "CXW Sales Price Checking";
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("CXW Minimum Margin %");
                        g_recGenSPSetup.TestField("CXW Stock Price Threshold %");

                        g_recSalesPriceCheck.Reset();
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error(NothingToProcessErr);

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange("CXW Validated", false);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error(NothingToProcessErr);

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange("CXW Accept New Setup", true);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error(NothingToProcessErr);

                        if Confirm(AcceptNewPriceSetupQst, false) then begin
                            l_recSalesPriceCheck.Reset();
                            if l_recSalesPriceCheck.FindSet() then begin
                                repeat
                                    l_recSalesPriceCheck."CXW Accept New Setup" := true;
                                    l_recSalesPriceCheck."CXW Remark Backup" := Rec."CXW Remark";
                                    l_recSalesPriceCheck."CXW Remark" := '';
                                    l_recSalesPriceCheck."CXW Approved By" := UserId;
                                    l_recSalesPriceCheck.Modify();
                                until l_recSalesPriceCheck.Next() = 0;
                                Message(DoneMsg);
                            end;
                        end;
                    end;
                }
                action(AddAllCountries)
                {
                    ApplicationArea = All;
                    Caption = 'Add all Countries';
                    ToolTip = 'Creates one sales price line per country/region activated for sales prices, in the sales price currency of that country/region.';
                    Image = Add;
                    Promoted = true;
                    PromotedCategory = New;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("CXW Minimum Margin %");
                        g_recGenSPSetup.TestField("CXW Stock Price Threshold %");

                        g_recSalesPriceCheck.Reset();
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error(NothingToProcessErr);

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange("CXW Countries Processed", false);
                        if not g_recSalesPriceCheck.FindFirst() then
                            Error(NothingToProcessErr);

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange("CXW Validated", false);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error(NothingToProcessErr);

                        g_recSalesPriceCheck.Reset();
                        g_recSalesPriceCheck.SetRange("CXW Accept New Setup", false);
                        if g_recSalesPriceCheck.FindFirst() then
                            Error(NothingToProcessErr);

                        fnAddAllCountries();

                        Message(DoneMsg);
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
                        l_recSalesPriceCheck: Record "CXW Sales Price Checking";
                        l_recSP: Record "Sales Price";
                        l_intTotal: Integer;
                        l_intExported: Integer;
                        l_intAlreadySent: Integer;
                        l_boolResendAlreadySent: Boolean;
                    begin
                        g_recGenSPSetup.Get();
                        g_recGenSPSetup.TestField("CXW Price Export Active", true);
                        g_recGenSPSetup.TestField("CXW API Interface Code");

                        l_recSalesPriceCheck.Reset();
                        l_recSalesPriceCheck.SetRange("CXW Accept New Setup", true);
                        if not l_recSalesPriceCheck.FindSet() then
                            Error(NothingToProcessErr);

                        l_recSalesPriceCheck.Reset();
                        l_recSalesPriceCheck.SetRange("CXW Accept New Setup", true);
                        l_recSalesPriceCheck.SetRange("CXW Export Status", l_recSalesPriceCheck."CXW Export Status"::Sent);
                        l_intAlreadySent := l_recSalesPriceCheck.Count();
                        if l_intAlreadySent > 0 then
                            l_boolResendAlreadySent := Confirm(StrSubstNo(ResendAlreadySentQst, l_intAlreadySent), false);

                        l_recSalesPriceCheck.Reset();
                        l_recSalesPriceCheck.SetRange("CXW Accept New Setup", true);
                        if l_recSalesPriceCheck.FindSet() then
                            repeat
                                if (l_recSalesPriceCheck."CXW Export Status" <> l_recSalesPriceCheck."CXW Export Status"::Sent) or l_boolResendAlreadySent then begin
                                    l_intTotal += 1;
                                    if g_cuExportGatewaySalesPrice.WriteBackAndArchive(l_recSalesPriceCheck, l_recSP) and
                                       g_cuExportGatewaySalesPrice.CreateExternalInterfaceFile(l_recSP, l_recSalesPriceCheck."CXW Country Code")
                                    then begin
                                        l_recSalesPriceCheck."CXW Export Status" := l_recSalesPriceCheck."CXW Export Status"::Sent;
                                        l_intExported += 1;
                                    end else
                                        l_recSalesPriceCheck."CXW Export Status" := l_recSalesPriceCheck."CXW Export Status"::Error;
                                    l_recSalesPriceCheck.Modify();
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if g_recGenSPSetup.Get() then
            Rec."CXW Price Includes VAT" := g_recGenSPSetup."CXW Prices Incl. VAT";
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Rec."CXW Accept New Setup" then
            Error(ModifyNotAllowedErr);

    end;

    var
        g_recSP: Record "Sales Price";
        g_recSalesPriceCheck: Record "CXW Sales Price Checking";
        g_recSalesPriceCheck2: Record "CXW Sales Price Checking";
        TXT001: Label 'New Final Price %1% less than existing Final Price %2', Comment = '%1 = percent, %2 = old price';
        g_recILE: Record "Item Ledger Entry";
        g_decSPExclVAT: Decimal;
        g_decProfit: Decimal;
        g_decProfitPercent: Decimal;
        TXT003: Label 'New Final Price has %1% profit, less than %2% setup margin';
        g_recCountryRegion: Record "Country/Region";
        TXT005: Label 'Currency Code %1 is not set for Country %2';

        TXT006: Label 'Starting Date %1 cannot be greater than Ending Date %2';
        g_recCurrExcRate: Record "Currency Exchange Rate";
        g_dateExchangeRateDate: Date;
        g_decExchangeRateAmt: Decimal;
        ProgressWindow: Dialog;
        TotalCount: Integer;
        CountToValidate: Integer;
        TXT007: Label 'New Final Price %1% greater than existing Final Price %2';
        g_decStockPricePercentFromPrev: Decimal;
        g_decNonStockPricePercentFromPrev: Decimal;
        g_recGenSPSetup: Record "CXW General Sales Price Setup";
        TXT009: Label 'Please delete existing entries to import new price';
        FinalPriceMustBeGreaterThanZeroErr: Label 'Final price must be greater than zero to calculate margin.';
        UpdateSalesPriceCheck: Record "CXW Sales Price Checking";
        g_cuExportGatewaySalesPrice: Codeunit "CXW Export Gateway Sales Price";
        ExportResultMsg: Label '%1 of %2 approved lines exported. Lines already exported were skipped.', Comment = '%1 = number of lines actually exported, %2 = number of approved lines considered';
        ResendAlreadySentQst: Label '%1 line(s) were already sent previously. Do you want to send them again?', Comment = '%1 = number of previously sent lines';
        NothingToProcessErr: Label 'Nothing to process';
        ValidateDoneMsg: Label 'validate data is done';
        AcceptNewPriceSetupQst: Label 'Are you sure want to Accept New Price Setup?';
        DoneMsg: Label 'done';
        ModifyNotAllowedErr: Label 'not possible';
        ValidatingProgressMsg: Label 'Validating Sales Price @1@@@@@@@@@@@@@@@';

    local procedure fnValidate()
    begin
        g_recSalesPriceCheck.Reset();
        g_recSalesPriceCheck.SetRange("CXW Validated", false);
        if g_recSalesPriceCheck.FindSet() then begin
            ProgressWindow.Open(ValidatingProgressMsg);
            TotalCount := g_recSalesPriceCheck.Count();
            repeat
                Clear(g_recSalesPriceCheck."CXW Remark");
                Clear(g_decStockPricePercentFromPrev);
                Clear(g_decNonStockPricePercentFromPrev);

                g_recSP.Reset();
                g_recSP.SetRange("Item No.", g_recSalesPriceCheck."CXW Item No.");
                g_recSP.SetRange("Currency Code", g_recSalesPriceCheck."CXW Currency Code");
                g_recSP.SetRange("Starting Date", g_recSalesPriceCheck."CXW Starting Date");
                if g_recSP.FindFirst() then begin
                    g_recSalesPriceCheck."CXW Old Stock Price" := g_recSP."CXW Unit Price (LCY)";
                    if g_recSP."CXW Unit Price (LCY)" <> 0 then begin
                        if g_recSalesPriceCheck."CXW Stock Price" < g_recSP."CXW Unit Price (LCY)" then
                            g_recSalesPriceCheck."CXW Remark" :=
                                StrSubstNo(
                                    TXT001,
                                    Round(((g_recSP."CXW Unit Price (LCY)" - g_recSalesPriceCheck."CXW Stock Price") / g_recSP."CXW Unit Price (LCY)") * 100, 0.01, '='),
                                    g_recSP."CXW Unit Price (LCY)");

                        g_decStockPricePercentFromPrev :=
                            Round(((g_recSalesPriceCheck."CXW Stock Price" - g_recSP."CXW Unit Price (LCY)") / g_recSP."CXW Unit Price (LCY)") * 100, 0.01, '=');
                        if (g_recSalesPriceCheck."CXW Stock Price" > g_recSP."CXW Unit Price (LCY)") and
                           (g_decStockPricePercentFromPrev > g_recGenSPSetup."CXW Stock Price Threshold %")
                        then
                            g_recSalesPriceCheck."CXW Remark" := StrSubstNo(TXT007, g_decStockPricePercentFromPrev, g_recSP."CXW Unit Price (LCY)");
                    end;
                end;

                g_decSPExclVAT := 0;
                g_decProfit := 0;
                g_decProfitPercent := 0;

                g_recILE.Reset();
                g_recILE.SetRange("Item No.", g_recSalesPriceCheck."CXW Item No.");
                g_recILE.SetRange("Invoiced Quantity", 1);
                g_recILE.SetRange("Location Code", 'HL');
                if g_recILE.FindLast() then begin
                    g_recILE.CalcFields("Cost Amount (Actual)");
                    g_decSPExclVAT := (g_recSalesPriceCheck."CXW Stock Price" * 100) / 119;
                    g_decProfit := g_decSPExclVAT - g_recILE."Cost Amount (Actual)";
                    if g_decSPExclVAT <> 0 then begin
                        g_decProfitPercent := Round((g_decProfit / g_decSPExclVAT) * 100, 0.01, '=');
                        if g_decProfitPercent < g_recGenSPSetup."CXW Minimum Margin %" then
                            g_recSalesPriceCheck."CXW Remark" := StrSubstNo(TXT003, g_decProfitPercent, g_recGenSPSetup."CXW Minimum Margin %");
                    end else
                        g_recSalesPriceCheck."CXW Remark" := FinalPriceMustBeGreaterThanZeroErr;
                end;

                if (g_recSalesPriceCheck."CXW Starting Date" > g_recSalesPriceCheck."CXW Ending Date") and (g_recSalesPriceCheck."CXW Ending Date" <> 0D) then
                    g_recSalesPriceCheck."CXW Remark" := StrSubstNo(TXT006, g_recSalesPriceCheck."CXW Starting Date", g_recSalesPriceCheck."CXW Ending Date");

                if g_recSalesPriceCheck."CXW Accept New Setup" then
                    g_recSalesPriceCheck."CXW Remark" := '';

                g_recSalesPriceCheck."CXW Validated" := true;

                g_recSalesPriceCheck.Modify();
                CountToValidate += 1;
                ProgressWindow.Update(1, Round(CountToValidate / TotalCount * 10000, 1));
            until g_recSalesPriceCheck.Next() = 0;
            ProgressWindow.Close();
        end;
    end;

    local procedure fnAddAllCountries()
    begin
        // Source lines are the imported lines without a country; generated lines always carry one.
        g_recSalesPriceCheck.Reset();
        g_recSalesPriceCheck.SetRange("CXW Countries Processed", false);
        if g_recSalesPriceCheck.FindSet() then
            repeat
                g_recCountryRegion.Reset();
                g_recCountryRegion.SetRange("CXW Sales Price Activated", true);
                if g_recCountryRegion.FindSet() then
                    repeat
                        if not g_recSalesPriceCheck2.Get(
                             g_recSalesPriceCheck."CXW Item No.", g_recCountryRegion."CXW Sales Price Currency Code", g_recCountryRegion.Code)
                        then
                            CreateCountryLine(g_recSalesPriceCheck, g_recCountryRegion);
                    until g_recCountryRegion.Next() = 0;
                UpdateSalesPriceCheck.Get(g_recSalesPriceCheck."CXW Item No.", g_recSalesPriceCheck."CXW Currency Code", g_recSalesPriceCheck."CXW Country Code");
                UpdateSalesPriceCheck."CXW Countries Processed" := true;
                UpdateSalesPriceCheck.Modify();
            until g_recSalesPriceCheck.Next() = 0;
    end;

    local procedure CreateCountryLine(p_recSourceLine: Record "CXW Sales Price Checking"; p_recCountryRegion: Record "Country/Region")
    begin
        g_recSalesPriceCheck2.Init();
        g_recSalesPriceCheck2."CXW Item No." := p_recSourceLine."CXW Item No.";
        g_recSalesPriceCheck2."CXW Country Code" := p_recCountryRegion.Code;
        g_recSalesPriceCheck2."CXW Currency Code" := p_recCountryRegion."CXW Sales Price Currency Code";
        g_recSalesPriceCheck2."CXW Price Includes VAT" := p_recSourceLine."CXW Price Includes VAT";

        if g_recSalesPriceCheck2."CXW Currency Code" = p_recSourceLine."CXW Currency Code" then begin
            g_recSalesPriceCheck2."CXW Stock Price" := RoundUpToTen(p_recSourceLine."CXW Stock Price");
            g_recSalesPriceCheck2."CXW Recom. Retail Price" := RoundUpToTen(p_recSourceLine."CXW Recom. Retail Price");
            g_recSalesPriceCheck2."CXW Strike Price" := RoundUpToTen(p_recSourceLine."CXW Strike Price");
            g_recSalesPriceCheck2."CXW Exchange Rate Amount" := p_recSourceLine."CXW Exchange Rate Amount";
            g_recSalesPriceCheck2."CXW Exchange Rate Date" := p_recSourceLine."CXW Exchange Rate Date";
        end else begin
            g_recCurrExcRate.Reset();
            g_recCurrExcRate.SetRange("Currency Code", g_recSalesPriceCheck2."CXW Currency Code");
            if g_recCurrExcRate.FindLast() then begin
                g_recCurrExcRate.GetLastestExchangeRate(g_recSalesPriceCheck2."CXW Currency Code", g_dateExchangeRateDate, g_decExchangeRateAmt);
                g_recSalesPriceCheck2."CXW Stock Price" := RoundUpToTen(p_recSourceLine."CXW Stock Price" * (1 / g_decExchangeRateAmt));
                g_recSalesPriceCheck2."CXW Recom. Retail Price" := RoundUpToTen(p_recSourceLine."CXW Recom. Retail Price" * (1 / g_decExchangeRateAmt));
                g_recSalesPriceCheck2."CXW Strike Price" := RoundUpToTen(p_recSourceLine."CXW Strike Price" * (1 / g_decExchangeRateAmt));
                g_recSalesPriceCheck2."CXW Exchange Rate Amount" := 1 / g_decExchangeRateAmt;
                g_recSalesPriceCheck2."CXW Exchange Rate Date" := g_dateExchangeRateDate;
            end;
        end;

        g_recSalesPriceCheck2."CXW Starting Date" := p_recSourceLine."CXW Starting Date";
        g_recSalesPriceCheck2."CXW Starting Time" := p_recSourceLine."CXW Starting Time";
        g_recSalesPriceCheck2."CXW Ending Date" := p_recSourceLine."CXW Ending Date";
        g_recSalesPriceCheck2."CXW Ending Time" := p_recSourceLine."CXW Ending Time";
        g_recSalesPriceCheck2."CXW Reason Code" := p_recSourceLine."CXW Reason Code";
        g_recSalesPriceCheck2."CXW Comment" := p_recSourceLine."CXW Comment";
        g_recSalesPriceCheck2."CXW Validated" := true;
        g_recSalesPriceCheck2."CXW Approved By" := p_recSourceLine."CXW Approved By";
        g_recSalesPriceCheck2."CXW Accept New Setup" := p_recSourceLine."CXW Accept New Setup";
        g_recSalesPriceCheck2.Insert(true);
    end;

    // Country prices are always rounded up to the next full ten (0 stays 0).
    local procedure RoundUpToTen(p_decAmount: Decimal): Decimal
    begin
        exit(Round(p_decAmount, 10, '>'));
    end;

    procedure fnCalcNonStockPrice(p_decStockPriceFrom: Decimal; p_decStockPriceTo: Decimal; p_decNonStockPercent: Decimal)
    begin
        g_recSalesPriceCheck2.Reset();
        g_recSalesPriceCheck2.SetRange("CXW Non Stock Price", 0);
        g_recSalesPriceCheck2.SetFilter("CXW Stock Price", '%1..%2', p_decStockPriceFrom, p_decStockPriceTo);
        if g_recSalesPriceCheck2.FindSet() then
            repeat
                if g_recSalesPriceCheck2."CXW Currency Code" <> '' then begin
                    g_recCurrExcRate.Reset();
                    g_recCurrExcRate.SetRange("Currency Code", g_recSalesPriceCheck2."CXW Currency Code");
                    if g_recCurrExcRate.FindLast() then begin
                        g_recCurrExcRate.GetLastestExchangeRate(g_recSalesPriceCheck2."CXW Currency Code", g_dateExchangeRateDate, g_decExchangeRateAmt);
                        g_recSalesPriceCheck2."CXW Non Stock Price" :=
                            ((g_recSalesPriceCheck2."CXW Stock Price" / (1 / g_decExchangeRateAmt)) +
                             ((g_recSalesPriceCheck2."CXW Stock Price" / (1 / g_decExchangeRateAmt)) * p_decNonStockPercent / 100)) * (1 / g_decExchangeRateAmt);
                    end;
                end else
                    g_recSalesPriceCheck2."CXW Non Stock Price" :=
                        g_recSalesPriceCheck2."CXW Stock Price" + (g_recSalesPriceCheck2."CXW Stock Price" * p_decNonStockPercent / 100);
                g_recSalesPriceCheck2.Modify();
            until g_recSalesPriceCheck2.Next() = 0;
    end;
}
