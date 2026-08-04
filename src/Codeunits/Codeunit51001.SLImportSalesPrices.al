// Migriert aus NAV Codeunit 82012 "Import Sales Prices" (Objekt-ID umnummeriert wegen
// app.json idRanges 51000-51049). TableNo zeigt jetzt auf "SL Sales Price Inbound File" (51005,
// schlanker Ersatz für Table 5275377 "Ext. Interface Inbound File" - siehe Codeunit 51000 für die
// Begründung, warum das ISV-Modul EXIN nicht 1:1 nachgebaut wurde).
//
// Abweichungen vom Original:
//   - Die DotNet-basierte Zeilenaufteilung (System.String.Split) wurde durch die native AL-Methode
//     Text.Split() ersetzt (DotNet-Interop ist in modernem/SaaS-fähigem AL nicht verfügbar).
//   - "RunTriggerAndEvents := Rec.\"Ext Interface Setup Name\" <> 'IMPPRI'" entfällt, da es dieses
//     ISV-Feld nicht mehr gibt; es wird immer TRUE gesetzt (Trigger/Events laufen immer normal).
//   - "Ext. Interface Protocol" (Table 5275379) wurde durch die schlanke Table 51006
//     "SL Sales Price Import Protocol" ersetzt.
codeunit 51001 "SL Import Sales Prices"
{
    TableNo = "SL Sales Price Inbound File";

    trigger OnRun()
    begin
        RunTriggerAndEvents := true;
        ProcessFile(Rec);
    end;

    var
        UnknownColumnErr: Label 'Unkown Column: %1.';
        RowCountDifferingErr: Label 'Read lines: %1, marked for processing: %2.';
        ProcessingErrorErr: Label 'Error while processing sales prices.';
        RunTriggerAndEvents: Boolean;

    local procedure ProcessFile(var vExtInterfaceInboundFile: Record "SL Sales Price Inbound File")
    var
        GenLedgerSetup: Record "General Ledger Setup";
        SalesPriceTemp: Record "Sales Price" temporary;
        InStr: InStream;
        CurrentLine: Text;
        LineValues: List of [Text];
        RowCount: Integer;
        ErrorText: Text[250];
    begin
        vExtInterfaceInboundFile.CalcFields(SourceFile);
        vExtInterfaceInboundFile.SourceFile.CreateInStream(InStr);
        RowCount := 0;
        GenLedgerSetup.Get();

        while not InStr.Eos do begin
            InStr.ReadText(CurrentLine);
            LineValues := CurrentLine.Split(',');

            if RowCount <> 0 then
                ProcessLine(LineValues, SalesPriceTemp, GenLedgerSetup)
            else
                if not EvaluateHeaderRow(LineValues, ErrorText) then begin
                    vExtInterfaceInboundFile.Status := vExtInterfaceInboundFile.Status::Error;
                    vExtInterfaceInboundFile.Modify();
                    WriteProtocol(vExtInterfaceInboundFile."Entry No.", ErrorText);
                    exit;
                end;

            RowCount += 1;
        end;

        if (RowCount - 1) <> SalesPriceTemp.Count() then begin
            vExtInterfaceInboundFile.Status := vExtInterfaceInboundFile.Status::Error;
            vExtInterfaceInboundFile.Modify();
            WriteProtocol(vExtInterfaceInboundFile."Entry No.", StrSubstNo(RowCountDifferingErr, RowCount, SalesPriceTemp.Count()));
            exit;
        end;

        if not WriteSalesPrices(SalesPriceTemp) then begin
            vExtInterfaceInboundFile.Status := vExtInterfaceInboundFile.Status::Error;
            WriteProtocol(vExtInterfaceInboundFile."Entry No.", ProcessingErrorErr);
        end else
            vExtInterfaceInboundFile.Status := vExtInterfaceInboundFile.Status::Processed;
        vExtInterfaceInboundFile.Modify();
    end;

    local procedure ProcessLine(LineValues: List of [Text]; var vSalesPriceTemp: Record "Sales Price" temporary; pGeneralLedgerSetup: Record "General Ledger Setup")
    var
        Value: Text;
        IntValue: Integer;
        DecimalValue: Decimal;
        BoolValue: Boolean;
        Index: Integer;
    begin
        vSalesPriceTemp.Init();

        for Index := 1 to LineValues.Count do begin
            Value := LineValues.Get(Index).Replace('"', '');
            case Index of
                1:
                    vSalesPriceTemp."Item No." := CopyStr(Value, 1, MaxStrLen(vSalesPriceTemp."Item No."));
                2:
                    vSalesPriceTemp."Variant Code" := CopyStr(Value, 1, MaxStrLen(vSalesPriceTemp."Variant Code"));
                3:
                    if Evaluate(IntValue, Value) then
                        vSalesPriceTemp."Sales Type" := IntValue;
                4:
                    vSalesPriceTemp."Sales Code" := CopyStr(Value, 1, MaxStrLen(vSalesPriceTemp."Sales Code"));
                5:
                    if Value <> pGeneralLedgerSetup."LCY Code" then
                        vSalesPriceTemp."Currency Code" := CopyStr(Value, 1, MaxStrLen(vSalesPriceTemp."Currency Code"))
                    else
                        vSalesPriceTemp."Currency Code" := '';
                6:
                    vSalesPriceTemp."Country/Region Code" := CopyStr(Value, 1, MaxStrLen(vSalesPriceTemp."Country/Region Code"));
                7:
                    if Evaluate(DecimalValue, Value) then
                        vSalesPriceTemp."Unit Price" := DecimalValue;
                8:
                    if Evaluate(BoolValue, Value) then
                        vSalesPriceTemp."Price Includes VAT" := BoolValue;
                9:
                    if Evaluate(DecimalValue, Value) then
                        vSalesPriceTemp."Strike-Price incl. VAT" := DecimalValue;
                10:
                    if Evaluate(DecimalValue, Value) then
                        vSalesPriceTemp."Recom. Retail Price incl. VAT" := DecimalValue;
            end;
        end;

        vSalesPriceTemp.Insert();
    end;

    local procedure EvaluateHeaderRow(LineValues: List of [Text]; var vErrorText: Text[250]): Boolean
    var
        AllowedValues: List of [Text];
        Value: Text;
    begin
        AllowedValues.Add('Item No_');
        AllowedValues.Add('Variant Code');
        AllowedValues.Add('Sales Type');
        AllowedValues.Add('Sales Code');
        AllowedValues.Add('Currency Code');
        AllowedValues.Add('Country_Region Code');
        AllowedValues.Add('Unit Price');
        AllowedValues.Add('Price Includes VAT');
        AllowedValues.Add('Strike-Price incl_ VAT');
        AllowedValues.Add('Recom_ Retail Price incl_ VAT');

        foreach Value in LineValues do begin
            Value := Value.Replace('"', '');
            if not AllowedValues.Contains(Value) then begin
                vErrorText := StrSubstNo(UnknownColumnErr, Value);
                exit(false);
            end;
        end;

        exit(true);
    end;

    local procedure WriteProtocol(pSourceNo: BigInteger; pMessage: Text[250])
    var
        ImportProtocol: Record "SL Sales Price Import Protocol";
        LastEntryNo: Integer;
    begin
        if pMessage = '' then
            exit;

        ImportProtocol.Reset();
        ImportProtocol.SetCurrentKey("Entry No.");
        ImportProtocol.SetRange("Source Entry No.", pSourceNo);
        if ImportProtocol.FindLast() then
            LastEntryNo := ImportProtocol."Entry No.";
        LastEntryNo += 1;

        ImportProtocol.Init();
        ImportProtocol."Entry No." := LastEntryNo;
        ImportProtocol."Source Entry No." := pSourceNo;
        ImportProtocol.Message := pMessage;
        ImportProtocol.Insert(true);
    end;

    local procedure WriteSalesPrices(var vSalesPriceTemp: Record "Sales Price" temporary): Boolean
    var
        SalesPrice: Record "Sales Price";
        SalesPriceCopy: Record "Sales Price";
        GenLedgerSetup: Record "General Ledger Setup";
    begin
        GenLedgerSetup.Get();
        vSalesPriceTemp.Reset();
        if vSalesPriceTemp.FindSet() then begin
            SalesPrice.LockTable();
            repeat
                if not SalesPrice.Get(
                     vSalesPriceTemp."Item No.", vSalesPriceTemp."Sales Type", vSalesPriceTemp."Sales Code",
                     //vSalesPriceTemp."Promotion Medium No.", vSalesPriceTemp."Prom.Med.Tar.Grp.No.", vSalesPriceTemp."Set No.",
                     vSalesPriceTemp."Starting Date", vSalesPriceTemp."Currency Code", vSalesPriceTemp."Country/Region Code",
                     vSalesPriceTemp."Variant Code", vSalesPriceTemp."Unit of Measure Code", vSalesPriceTemp."Minimum Quantity")
                then begin
                    SalesPrice.Init();
                    SalesPrice."Item No." := vSalesPriceTemp."Item No.";
                    SalesPrice."Variant Code" := vSalesPriceTemp."Variant Code";
                    SalesPrice.Validate("Sales Type", vSalesPriceTemp."Sales Type");
                    SalesPrice.Validate("Sales Code", vSalesPriceTemp."Sales Code");
                    if vSalesPriceTemp."Currency Code" <> GenLedgerSetup."LCY Code" then
                        SalesPrice.Validate("Currency Code", vSalesPriceTemp."Currency Code");
                    SalesPrice.Validate("Country/Region Code", vSalesPriceTemp."Country/Region Code");
                    SalesPrice.Validate("Unit Price", vSalesPriceTemp."Unit Price");
                    SalesPrice.Validate("Price Includes VAT", vSalesPriceTemp."Price Includes VAT");
                    SalesPrice."Strike-Price incl. VAT" := vSalesPriceTemp."Strike-Price incl. VAT";
                    SalesPrice."Recom. Retail Price incl. VAT" := vSalesPriceTemp."Recom. Retail Price incl. VAT";
                    SalesPrice.Insert(RunTriggerAndEvents);
                end else begin
                    SalesPriceCopy.Copy(SalesPrice);
                    SalesPrice.Validate("Unit Price", vSalesPriceTemp."Unit Price");
                    SalesPrice.Validate("Price Includes VAT", vSalesPriceTemp."Price Includes VAT");
                    SalesPrice."Strike-Price incl. VAT" := vSalesPriceTemp."Strike-Price incl. VAT";
                    SalesPrice."Recom. Retail Price incl. VAT" := vSalesPriceTemp."Recom. Retail Price incl. VAT";
                    SalesPrice.Modify();
                    OnAfterSalesPriceModify(SalesPrice, SalesPriceCopy, RunTriggerAndEvents);
                end;
            until vSalesPriceTemp.Next() = 0;
        end;

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesPriceModify(var vSalesPriceRec: Record "Sales Price"; var vSalesPricexRec: Record "Sales Price"; RunTrigger: Boolean)
    begin
    end;
}
