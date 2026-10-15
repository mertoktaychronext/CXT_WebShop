codeunit 60333 "CXW Release Sales Price Line"
{
    // Releases one approved checking line as a single unit (write-back, archive, export record, export entry).
    // Called via Codeunit.Run so that a failure rolls back everything done for that line.
    TableNo = "CXW Sales Price Checking";

    trigger OnRun()
    var
        SalesPrice: Record "Sales Price";
        ExportGatewaySalesPrice: Codeunit "CXW Export Gateway Sales Price";
    begin
        Rec.TestField("CXW Country Code");
        ExportGatewaySalesPrice.WriteBackAndArchive(Rec, SalesPrice);
        ExportGatewaySalesPrice.QueueExport(Rec, SalesPrice);

        Rec."CXW Export Status" := Rec."CXW Export Status"::Queued;
        Rec.Modify();
    end;
}
