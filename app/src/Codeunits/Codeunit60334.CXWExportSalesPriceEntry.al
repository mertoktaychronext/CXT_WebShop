codeunit 60334 "CXW Export Sales Price Entry"
{
    // Builds and sends one SALESPRICE "Data Export Entry". Called via Codeunit.Run by the job,
    // so a runtime error only affects this entry.
    TableNo = "Data Export Entry";

    trigger OnRun()
    var
        ExportGatewaySalesPrice: Codeunit "CXW Export Gateway Sales Price";
    begin
        ExportGatewaySalesPrice.ExportEntry(Rec);
    end;
}
