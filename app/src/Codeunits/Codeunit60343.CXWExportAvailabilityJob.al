codeunit 60343 "CXW Export Availability Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ExportAvailabilityChange: Codeunit "CXW Export Availability Change";
        AvailabilityChangeMgt: Codeunit "CXW Availability Change Mgt";
        Parameter: Text;
        ExportedCount: Integer;
        FailedCount: Integer;
    begin
        Parameter := UpperCase(DelChr(Rec."Parameter String", '<>', ' '));

        case Parameter of
            '', AllParameterLbl:
                begin
                    ExportAvailabilityChange.ExportOpenEntries(ExportedCount, FailedCount);
                    ExportAvailabilityChange.ExportOpenDeliveryTimes(ExportedCount, FailedCount);
                    ExportAvailabilityChange.ExportOpenInventoryTimes(ExportedCount, FailedCount);
                end;
            StockParameterLbl:
                ExportAvailabilityChange.ExportOpenEntries(ExportedCount, FailedCount);
            DeliveryTimeParameterLbl:
                ExportAvailabilityChange.ExportOpenDeliveryTimes(ExportedCount, FailedCount);
            InventoryTimeParameterLbl:
                ExportAvailabilityChange.ExportOpenInventoryTimes(ExportedCount, FailedCount);
            CalculateParameterLbl:
                AvailabilityChangeMgt.RefreshDeliveryTimesForActiveCountries();
            else
                Error(UnsupportedParameterErr, Rec."Parameter String", StockParameterLbl, DeliveryTimeParameterLbl, InventoryTimeParameterLbl, CalculateParameterLbl, AllParameterLbl);
        end;

        if FailedCount <> 0 then
            Error(ExportFailedErr, FailedCount);
    end;

    var
        StockParameterLbl: Label 'UPDSTOFILE', Locked = true;
        DeliveryTimeParameterLbl: Label 'UPDDLT', Locked = true;
        InventoryTimeParameterLbl: Label 'UPDIN', Locked = true;
        CalculateParameterLbl: Label 'CALCULATE', Locked = true;
        AllParameterLbl: Label 'ALL', Locked = true;
        UnsupportedParameterErr: Label 'Unsupported parameter %1. Use %2, %3, %4, %5, or %6.', Comment = '%1 = supplied parameter, %2 = stock parameter, %3 = delivery time parameter, %4 = inventory time parameter, %5 = calculation parameter, %6 = all parameter';
        ExportFailedErr: Label '%1 availability export(s) failed. See the HTTP call log for details.', Comment = '%1 = failed export count';
}
