codeunit 60351 "CXW SellWatch Process Offer"
{
    // Processes exactly one SellWatch offer. Called via Codeunit.Run from "CXW SellWatch Mgt",
    // so that a failure rolls back everything done for this offer only.
    TableNo = "CXW SellWatch Vendor Info";

    trigger OnRun()
    var
        SellWatchMgt: Codeunit "CXW SellWatch Mgt";
    begin
        SellWatchMgt.ProcessOffer(Rec);
    end;
}
