pageextension 60328 "CXW Workshop Purchase Order" extends "Purchase Order"
{
    actions
    {
        addlast(Processing)
        {
            action("CXW Send to Workshop")
            {
                ApplicationArea = All;
                Caption = 'Send to Workshop';
                ToolTip = 'Confirms arrival per line, captures the manufacturer serial number, and creates a workshop line for each arrived item.';

                trigger OnAction()
                begin
                    SendLinesToWorkshop();
                end;
            }
        }
    }

    local procedure SendLinesToWorkshop()
    var
        PurchLine: Record "Purchase Line";
        ErrorLines: Text;
    begin
        PurchLine.SetRange("Document Type", Rec."Document Type");
        PurchLine.SetRange("Document No.", Rec."No.");
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetFilter(Quantity, '<>%1', 0);
        PurchLine.SetRange("CXW Sent to Workshop", false);
        if PurchLine.FindSet() then
            repeat
                ProcessLine(PurchLine, ErrorLines);
            until PurchLine.Next() = 0;

        CurrPage.Update(false);

        if ErrorLines <> '' then
            Message(LinesNotSentMsg, ErrorLines);
    end;

    local procedure ProcessLine(var PurchLine: Record "Purchase Line"; var ErrorLines: Text)
    var
        SerialNoInput: Page "CXW Serial No. Input";
        SerialNo: Text[50];
    begin
        if not Confirm(StrSubstNo(ArrivedQst, PurchLine."No.", PurchLine.Description)) then begin
            PurchLine."CXW Not Arrived" := true;
            PurchLine.Modify();
            exit;
        end;

        if SerialNoInput.RunModal() <> Action::OK then begin
            AddErrorLine(ErrorLines, PurchLine, SerialNoInputCancelledErr);
            exit;
        end;

        SerialNo := SerialNoInput.GetSerialNo();
        if SerialNo = '' then begin
            AddErrorLine(ErrorLines, PurchLine, SerialNoRequiredErr);
            exit;
        end;

        PurchLine."CXW Manufacturer Serial No." := SerialNo;
        PurchLine."CXW Not Arrived" := false;
        PurchLine."CXW Sent to Workshop" := true;
        PurchLine.Modify();

        CreateWorkshopLine(PurchLine);
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
        SerialNoInputCancelledErr: Label 'The serial number input was cancelled.';
        ErrorLineTxt: Label 'Line %1 (%2): %3', Comment = '%1 = line no., %2 = item no., %3 = reason';
        LinesNotSentMsg: Label 'The following lines were not sent to the workshop:\%1', Comment = '%1 = list of line errors';
}
