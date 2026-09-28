codeunit 60332 "CXW Export Sales Price Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        GenSPSetup: Record "CXW General Sales Price Setup";
        DataExportEntry: Record "Data Export Entry";
        ExportGatewaySalesPrice: Codeunit "CXW Export Gateway Sales Price";
        EntryNos: List of [BigInteger];
        EntryNo: BigInteger;
        MaxAttempts: Integer;
    begin
        if not GenSPSetup.Get() then
            exit;
        // Export switched off: pending entries simply wait for the next run.
        if (not GenSPSetup."CXW Price Export Active") or (GenSPSetup."CXW API Interface Code" = '') then
            exit;

        // A setup record created before the field existed holds 0 - same default as the field's InitValue.
        MaxAttempts := GenSPSetup."CXW Max. Export Attempts";
        if MaxAttempts <= 0 then
            MaxAttempts := 3;

        // Collect first - the loop below changes Status, which is part of the filter.
        DataExportEntry.SetRange("Destination Code", ExportGatewaySalesPrice.GetDestinationCode());
        DataExportEntry.SetFilter(Status, '%1|%2', DataExportEntry.Status::"CXW Pending", DataExportEntry.Status::Error);
        if DataExportEntry.FindSet() then
            repeat
                if (DataExportEntry.Status = DataExportEntry.Status::"CXW Pending") or
                   (DataExportEntry."Attempt Count" < MaxAttempts)
                then
                    EntryNos.Add(DataExportEntry."Entry No.");
            until DataExportEntry.Next() = 0;

        // Failures of single entries are recorded on the entry; the job run itself does not fail,
        // so that the recurring Job Queue Entry keeps running.
        foreach EntryNo in EntryNos do
            ExportEntry(EntryNo);
    end;

    local procedure ExportEntry(pEntryNo: BigInteger)
    var
        DataExportEntry: Record "Data Export Entry";
        ExportGatewaySalesPrice: Codeunit "CXW Export Gateway Sales Price";
        ErrorText: Text;
    begin
        if not DataExportEntry.Get(pEntryNo) then
            exit;

        Commit();
        ClearLastError();
        if not Codeunit.Run(Codeunit::"CXW Export Sales Price Entry", DataExportEntry) then begin
            ErrorText := GetLastErrorText();
            if ErrorText = '' then
                ErrorText := UnexpectedErrorTxt;
            DataExportEntry.Get(pEntryNo);
            ExportGatewaySalesPrice.SetAttemptResult(DataExportEntry, false, ErrorText);
        end;
        Commit();
    end;

    var
        UnexpectedErrorTxt: Label 'An unexpected error occurred while exporting the sales price.';
}
