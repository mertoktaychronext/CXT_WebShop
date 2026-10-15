codeunit 60350 "CXW Realtime Inventory Mgt."
{
    procedure RefreshCurrentCompany()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RealtimeInventory: Record "CXW Realtime Inventory";
    begin
        RealtimeInventory.DeleteAll();

        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>%1', 0);
        ItemLedgerEntry.SetFilter("Item No.", '<>%1', 'BOX');
        if ItemLedgerEntry.FindSet() then
            repeat
                CreateRealtimeInventoryEntry(ItemLedgerEntry, RealtimeInventory);
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure CreateRealtimeInventoryEntry(ItemLedgerEntry: Record "Item Ledger Entry"; var RealtimeInventory: Record "CXW Realtime Inventory")
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
    begin
        Clear(RealtimeInventory);
        RealtimeInventory.Init();
        RealtimeInventory."CXW Item No." := ItemLedgerEntry."Item No.";
        RealtimeInventory."CXW Variant Code" := ItemLedgerEntry."Variant Code";
        RealtimeInventory."CXW Quantity" := ItemLedgerEntry."Remaining Quantity";
        RealtimeInventory."CXW Company Name" := CompanyName;
        RealtimeInventory."CXW Location Code" := ItemLedgerEntry."Location Code";
        RealtimeInventory."CXW Serial No." := ItemLedgerEntry."Serial No.";
        RealtimeInventory."CXW Differential Taxation" := ItemLedgerEntry."SLPSBC Margin Taxation";
        RealtimeInventory."CXW Posting Date" := ItemLedgerEntry."Posting Date";
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        RealtimeInventory."CXW Purchase Price" := ItemLedgerEntry."Cost Amount (Actual)";
        SetPurchaseDetails(ItemLedgerEntry, RealtimeInventory);

        if Item.Get(ItemLedgerEntry."Item No.") then begin
            RealtimeInventory."CXW Brand" := GetItemAttributeValue(Item."No.", 1);
            RealtimeInventory."CXW Model" := GetItemAttributeValue(Item."No.", 2);
            RealtimeInventory."CXW Reference" := GetItemAttributeValue(Item."No.", 5);
            RealtimeInventory."CXW Variant Category" := GetItemAttributeValue(Item."No.", 37);
            RealtimeInventory."CXW Condition" := GetItemAttributeValue(Item."No.", 10);
            RealtimeInventory."CXW Visibility" := GetItemAttributeValue(Item."No.", 41);
            RealtimeInventory."CXW Certificate" := GetItemAttributeValue(Item."No.", 13);
        end;

        SalesPrice.SetRange("Item No.", ItemLedgerEntry."Item No.");
        SalesPrice.SetRange("Variant Code", ItemLedgerEntry."Variant Code");
        if SalesPrice.FindLast() then
            RealtimeInventory."CXW Sales Price" := SalesPrice."Unit Price";

        RealtimeInventory.Insert();
    end;

    local procedure SetPurchaseDetails(ItemLedgerEntry: Record "Item Ledger Entry"; var RealtimeInventory: Record "CXW Realtime Inventory")
    var
        PurchaseItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ItemLedgerEntry."Serial No." <> '' then begin
            PurchaseItemLedgerEntry.SetRange("Item No.", ItemLedgerEntry."Item No.");
            PurchaseItemLedgerEntry.SetRange("Variant Code", ItemLedgerEntry."Variant Code");
            PurchaseItemLedgerEntry.SetRange("Serial No.", ItemLedgerEntry."Serial No.");
            PurchaseItemLedgerEntry.SetRange("Entry Type", PurchaseItemLedgerEntry."Entry Type"::Purchase);
            if PurchaseItemLedgerEntry.FindFirst() then begin
                RealtimeInventory."CXW Vendor No." := PurchaseItemLedgerEntry."Source No.";
                RealtimeInventory."CXW Purchase Order No." := PurchaseItemLedgerEntry."Order No.";
                exit;
            end;
        end;

        if ItemLedgerEntry."Source Type" = Database::Vendor then begin
            RealtimeInventory."CXW Vendor No." := ItemLedgerEntry."Source No.";
            RealtimeInventory."CXW Purchase Order No." := ItemLedgerEntry."Order No.";
        end;
    end;

    local procedure GetItemAttributeValue(ItemNo: Code[20]; AttributeId: Integer): Text[250]
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        if not ItemAttributeValueMapping.Get(Database::Item, ItemNo, AttributeId) then
            exit('');
        if not ItemAttributeValue.Get(AttributeId, ItemAttributeValueMapping."Item Attribute Value ID") then
            exit('');
        exit(ItemAttributeValue.Value);
    end;
}
