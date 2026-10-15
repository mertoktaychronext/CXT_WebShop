pageextension 60328 "CXW Workshop Purchase Order" extends "Purchase Order"
{
    layout
    {
        addlast(General)
        {
            field("CXW No. of Workshop Lines"; Rec."CXW No. of Workshop Lines")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies how many workshop lines exist for this order. Choose the value to open the workshop lines of this order.';

                trigger OnDrillDown()
                begin
                    ShowWorkshopLines();
                end;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action("CXW Send to Workshop")
            {
                ApplicationArea = All;
                Caption = 'Send to Workshop';
                ToolTip = 'Confirms arrival per line, assigns a serial number if none is assigned yet, opens the serial no. information card to capture the manufacturer serial number, and creates a workshop line for each arrived item.';

                trigger OnAction()
                begin
                    SendLinesToWorkshop();
                end;
            }
        }
    }

    local procedure ShowWorkshopLines()
    var
        WorkshopLine: Record "CXW Workshop Line";
    begin
        WorkshopLine.SetRange("CXW Document Type", Rec."Document Type");
        WorkshopLine.SetRange("CXW Document No.", Rec."No.");
        Page.Run(Page::"CXW Workshop Lines", WorkshopLine);
    end;

    local procedure CountWorkshopLines(): Integer
    var
        WorkshopLine: Record "CXW Workshop Line";
    begin
        WorkshopLine.SetRange("CXW Document Type", Rec."Document Type");
        WorkshopLine.SetRange("CXW Document No.", Rec."No.");
        exit(WorkshopLine.Count());
    end;

    local procedure SendLinesToWorkshop()
    var
        PurchLine: Record "Purchase Line";
        LineNos: List of [Integer];
        LineNo: Integer;
        ErrorLines: Text;
        NoOfWorkshopLines: Integer;
    begin
        // Collect first: ProcessLine changes the filter field "CXW Sent to Workshop" and commits per line.
        PurchLine.SetRange("Document Type", Rec."Document Type");
        PurchLine.SetRange("Document No.", Rec."No.");
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetFilter(Quantity, '<>%1', 0);
        PurchLine.SetRange("CXW Sent to Workshop", false);
        PurchLine.SetLoadFields("Line No.");
        if PurchLine.FindSet() then
            repeat
                LineNos.Add(PurchLine."Line No.");
            until PurchLine.Next() = 0;

        // Repeated call: point out existing workshop lines; open lines (e.g. not arrived) may still be sent.
        NoOfWorkshopLines := CountWorkshopLines();
        if NoOfWorkshopLines > 0 then begin
            if LineNos.Count() = 0 then begin
                Message(AllLinesAlreadySentMsg);
                exit;
            end;
            if not Confirm(WorkshopLinesExistQst, false, NoOfWorkshopLines) then
                exit;
        end;

        foreach LineNo in LineNos do begin
            PurchLine.Reset();
            if PurchLine.Get(Rec."Document Type", Rec."No.", LineNo) then
                ProcessLine(PurchLine, ErrorLines);
        end;

        CurrPage.Update(false);

        if ErrorLines <> '' then
            Message(LinesNotSentMsg, ErrorLines);
    end;

    local procedure ProcessLine(var PurchLine: Record "Purchase Line"; var ErrorLines: Text)
    var
        SerialNoInformation: Record "Serial No. Information";
        WorkshopLineMgt: Codeunit "CXW Workshop Line Mgt.";
        SerialNo: Code[50];
    begin
        if not Confirm(StrSubstNo(ArrivedQst, PurchLine."No.", PurchLine.Description)) then begin
            PurchLine."CXW Not Arrived" := true;
            PurchLine.Modify();
            exit;
        end;

        // One workshop line = one watch = one serial number.
        if PurchLine."Quantity (Base)" <> 1 then begin
            AddErrorLine(ErrorLines, PurchLine, QuantityNotOneErr);
            exit;
        end;
        if not WorkshopLineMgt.IsSerialNoTracked(PurchLine."No.") then begin
            AddErrorLine(ErrorLines, PurchLine, NoSerialNoTrackingErr);
            exit;
        end;

        // Reuse a serial no. already assigned to the line (also from an earlier, aborted attempt);
        // otherwise draw the next one and assign it as item tracking.
        SerialNo := WorkshopLineMgt.FindPurchLineSerialNo(PurchLine);
        if SerialNo = '' then begin
            SerialNo := WorkshopLineMgt.AssignNextSerialNo(PurchLine);
            if SerialNo = '' then begin
                AddErrorLine(ErrorLines, PurchLine, NoSerialNosErr);
                exit;
            end;
        end;

        WorkshopLineMgt.GetOrCreateSerialNoInformation(PurchLine."No.", PurchLine."Variant Code", SerialNo, SerialNoInformation);
        // Page.RunModal is not allowed in a write transaction. Serial no., item tracking and serial no.
        // information are meant to persist anyway, so an aborted attempt reuses them on the next run.
        Commit();
        Page.RunModal(Page::"Serial No. Information Card", SerialNoInformation);
        // The card has no OK/Cancel; only the data entered on it counts.
        SerialNoInformation.Get(PurchLine."No.", PurchLine."Variant Code", SerialNo);

        if SerialNoInformation."CXB Manufacturer Serial No." = '' then begin
            AddErrorLine(ErrorLines, PurchLine, SerialNoRequiredErr);
            exit;
        end;
        ClearLastError();
        if not TryCheckPresenceMandatory(PurchLine."No.", PurchLine."Variant Code", SerialNo) then begin
            AddErrorLine(ErrorLines, PurchLine, GetLastErrorText());
            exit;
        end;

        PurchLine."CXW Manufacturer Serial No." := SerialNoInformation."CXB Manufacturer Serial No.";
        PurchLine."CXW Not Arrived" := false;
        PurchLine."CXW Sent to Workshop" := true;
        PurchLine.Modify();

        CreateWorkshopLine(PurchLine);
    end;

    // Read-only check from CHX.Base (manufacturer serial no./box/papers mandatory per item tracking code);
    // wrapped so that a missing value becomes a line error instead of aborting the whole action.
    [TryFunction]
    local procedure TryCheckPresenceMandatory(ItemNo: Code[20]; VariantCode: Code[10]; SerialNo: Code[50])
    var
        SerialNoBinEnforcement: Codeunit "CXB Serial No. Bin Enforcement";
    begin
        SerialNoBinEnforcement.CheckPresenceMandatory(ItemNo, VariantCode, SerialNo);
    end;

    local procedure AddErrorLine(var ErrorLines: Text; PurchLine: Record "Purchase Line"; Reason: Text)
    begin
        if ErrorLines <> '' then
            ErrorLines += '\';
        ErrorLines += StrSubstNo(ErrorLineTxt, PurchLine."Line No.", PurchLine."No.", Reason);
    end;

    local procedure CreateWorkshopLine(PurchLine: Record "Purchase Line")
    var
        WorkshopLine: Record "CXW Workshop Line";
        WorkshopLineMgt: Codeunit "CXW Workshop Line Mgt.";
    begin
        WorkshopLine.Init();
        WorkshopLine."CXW Document Type" := PurchLine."Document Type";
        WorkshopLine."CXW Document No." := PurchLine."Document No.";
        WorkshopLine."CXW Line No." := PurchLine."Line No.";
        WorkshopLine."CXW Item No." := PurchLine."No.";
        WorkshopLine."CXW Manufacturer Serial No." := PurchLine."CXW Manufacturer Serial No.";
        WorkshopLine."CXW Status" := WorkshopLine."CXW Status"::"new";
        WorkshopLineMgt.FillPurchaseData(WorkshopLine, PurchLine);
        WorkshopLineMgt.PrefillEmptyWorkshopAttributes(WorkshopLine);
        WorkshopLine.Insert(true);
    end;

    var
        // DE-Übersetzung muss wörtlich lauten: "Ist Artikel %1 %2 wirklich angekommen?" (fachlich vorgegebener Wortlaut)
        ArrivedQst: Label 'Has item %1 %2 actually arrived?', Comment = '%1 = item no., %2 = description';
        SerialNoRequiredErr: Label 'The manufacturer serial number is required.';
        QuantityNotOneErr: Label 'Only lines with a quantity of 1 can be sent to the workshop.';
        NoSerialNoTrackingErr: Label 'The item is not set up for serial number tracking on purchases.';
        NoSerialNosErr: Label 'No serial number is assigned and the item has no serial no. series.';
        ErrorLineTxt: Label 'Line %1 (%2): %3', Comment = '%1 = line no., %2 = item no., %3 = reason';
        LinesNotSentMsg: Label 'The following lines were not sent to the workshop:\%1', Comment = '%1 = list of line errors';
        WorkshopLinesExistQst: Label 'There are already %1 workshop lines for this order. Do you want to send the remaining lines to the workshop?', Comment = '%1 = number of existing workshop lines';
        AllLinesAlreadySentMsg: Label 'Workshop lines already exist for this order. There are no further lines to send to the workshop.';
}
