pageextension 60331 "CXW Item Card" extends "Item Card"
{
    actions
    {
        addlast(Processing)
        {
            action(CXWExportAvailability)
            {
                Caption = 'Export Availability';
                ApplicationArea = All;
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepares and exports the current item, its variants, delivery times, and inventory times.';

                trigger OnAction()
                var
                    ExportAvailabilityChange: Codeunit "CXW Export Availability Change";
                    ExportedCount: Integer;
                    FailedCount: Integer;
                begin
                    ExportAvailabilityChange.ExportItem(Rec."No.", ExportedCount, FailedCount);
                    Message(ExportResultMsg, Rec."No.", ExportedCount, FailedCount);
                end;
            }
            action(CXWCheckAvailabilityDeliveryDate)
            {
                Caption = 'Check Availability Date';
                ApplicationArea = All;
                Image = CalculateCalendar;
                ToolTip = 'Calculates the current delivery date for this item based on availability and delivery-time rules.';

                trigger OnAction()
                var
                    AvailabilityCalculation: Codeunit "CXW Availability Calculation";
                    AvailabilityCheckDialog: Page "CXW Availability Check Dialog";
                    DeliveryDate: Date;
                    DeliveryDays: Integer;
                    Availability: Decimal;
                begin
                    if AvailabilityCheckDialog.RunModal() <> Action::OK then
                        exit;

                    Availability := AvailabilityCalculation.GetArticleAvailability(Rec."No.");
                    if AvailabilityCalculation.TryGetArticleDeliveryDate(
                           Rec."No.",
                           AvailabilityCheckDialog.GetCountryRegionCode(),
                           AvailabilityCheckDialog.GetZoneCode(),
                           AvailabilityCheckDialog.GetBinCode(),
                           DeliveryDate)
                    then begin
                        DeliveryDays := DeliveryDate - Today;
                        Message(
                          DeliveryDateMsg,
                          Rec."No.",
                          Format(Availability),
                          Format(DeliveryDate),
                          DeliveryDays);
                    end else
                        Message(NotDeliverableMsg, Rec."No.", Format(Availability));
                end;
            }
        }
    }

    var
        DeliveryDateMsg: Label 'Item %1 has availability %2. Calculated delivery date: %3 (%4 day(s)).', Comment = '%1 = item no.; %2 = availability; %3 = delivery date; %4 = day count';
        NotDeliverableMsg: Label 'Item %1 has availability %2 and is currently not deliverable.', Comment = '%1 = item no.; %2 = availability';
        ExportResultMsg: Label 'Item %1: %2 entry(ies) exported successfully. %3 entry(ies) could not be exported; see the HTTP call log for details.', Comment = '%1 = item no., %2 = exported count, %3 = failed count';
}
