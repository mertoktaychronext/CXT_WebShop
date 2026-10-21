codeunit 60336 "CXW Workshop Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetWorkshopLinePurchaseDataTag()) then begin
            FillPurchaseDataOnOpenLines();
            UpgradeTag.SetUpgradeTag(GetWorkshopLinePurchaseDataTag());
        end;

        if not UpgradeTag.HasUpgradeTag(GetWorkshopLineAttributePrefillTag()) then begin
            PrefillAttributesOnNewLines();
            UpgradeTag.SetUpgradeTag(GetWorkshopLineAttributePrefillTag());
        end;

        if not UpgradeTag.HasUpgradeTag(GetHoldOrderMigrationTag()) then begin
            MigrateHoldOrderToBase();
            UpgradeTag.SetUpgradeTag(GetHoldOrderMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(GetAvailabilityTimeExportTag()) then begin
            MarkSentEntriesAsTimeExported();
            UpgradeTag.SetUpgradeTag(GetAvailabilityTimeExportTag());
        end;

        if not UpgradeTag.HasUpgradeTag(GetWorkshopLineSerialNoTag()) then begin
            FillSerialNoOnOpenLines();
            UpgradeTag.SetUpgradeTag(GetWorkshopLineSerialNoTag());
        end;
    end;

    // Only lines the workshop still works on; after posting the receipt the purchase line has no item tracking left.
    local procedure FillSerialNoOnOpenLines()
    var
        WorkshopLine: Record "CXW Workshop Line";
        PurchLine: Record "Purchase Line";
        WorkshopLineMgt: Codeunit "CXW Workshop Line Mgt.";
    begin
        WorkshopLine.SetFilter("CXW Status", '%1|%2', WorkshopLine."CXW Status"::"new", WorkshopLine."CXW Status"::"WS checked");
        WorkshopLine.SetRange("CXW Serial No.", '');
        if WorkshopLine.FindSet(true) then
            repeat
                if PurchLine.Get(WorkshopLine."CXW Document Type", WorkshopLine."CXW Document No.", WorkshopLine."CXW Line No.") then
                    if WorkshopLineMgt.FillSerialNoFromPurchLine(WorkshopLine, PurchLine) then
                        WorkshopLine.Modify(false);
            until WorkshopLine.Next() = 0;
    end;

    // UPDDLT/UPDIN now work off the change entry log. Entries already sent as stock count as sent for the
    // time interfaces too, otherwise the first run after the upgrade would send the whole history again.
    local procedure MarkSentEntriesAsTimeExported()
    var
        AvailabilityChangeEntry: Record "CXW Availability Change Entry";
    begin
        AvailabilityChangeEntry.SetRange("CXW Exported", true);
        AvailabilityChangeEntry.ModifyAll("CXW Deli. Time Exported", true, false);
        AvailabilityChangeEntry.ModifyAll("CXW Inv. Time Exported", true, false);
    end;

    // Only lines the workshop has not reported on yet; filled fields are never overwritten.
    local procedure PrefillAttributesOnNewLines()
    var
        WorkshopLine: Record "CXW Workshop Line";
        WorkshopLineMgt: Codeunit "CXW Workshop Line Mgt.";
    begin
        WorkshopLine.SetRange("CXW Status", WorkshopLine."CXW Status"::"new");
        if WorkshopLine.FindSet(true) then
            repeat
                WorkshopLineMgt.PrefillEmptyWorkshopAttributes(WorkshopLine);
                WorkshopLine.Modify(false);
            until WorkshopLine.Next() = 0;
    end;

    // Lines the workshop still works on get the purchase and watch data; processed lines stay as they are.
    local procedure FillPurchaseDataOnOpenLines()
    var
        WorkshopLine: Record "CXW Workshop Line";
        PurchLine: Record "Purchase Line";
        WorkshopLineMgt: Codeunit "CXW Workshop Line Mgt.";
    begin
        WorkshopLine.SetFilter("CXW Status", '%1|%2', WorkshopLine."CXW Status"::"new", WorkshopLine."CXW Status"::"WS checked");
        if WorkshopLine.FindSet(true) then
            repeat
                if PurchLine.Get(WorkshopLine."CXW Document Type", WorkshopLine."CXW Document No.", WorkshopLine."CXW Line No.") then begin
                    WorkshopLineMgt.FillPurchaseData(WorkshopLine, PurchLine);
                    WorkshopLine.Modify(false);
                end;
            until WorkshopLine.Next() = 0;
    end;

    local procedure MigrateHoldOrderToBase()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("CXW Hold Order", true);
        if not SalesHeader.FindSet(true) then
            exit;

        repeat
            if not SalesHeader."CXB Hold Order" then begin
                // Do not validate: historical released orders may also have the legacy flag set.
                SalesHeader."CXB Hold Order" := true;
                SalesHeader.Modify(false);
            end;
        until SalesHeader.Next() = 0;
    end;

    local procedure GetWorkshopLinePurchaseDataTag(): Code[250]
    begin
        exit('CXW-WORKSHOPLINE-PURCHASEDATA-20260928');
    end;

    local procedure GetWorkshopLineAttributePrefillTag(): Code[250]
    begin
        exit('CXW-WORKSHOPLINE-ATTRIBUTEPREFILL-20260930');
    end;

    local procedure GetHoldOrderMigrationTag(): Code[250]
    begin
        exit('CXW-HOLD-ORDER-TO-BASE-20261001');
    end;

    local procedure GetAvailabilityTimeExportTag(): Code[250]
    begin
        exit('CXW-AVAILABILITY-TIME-EXPORT-LOG-20261009');
    end;

    local procedure GetWorkshopLineSerialNoTag(): Code[250]
    begin
        exit('CXW-WORKSHOPLINE-SERIALNO-20261021');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetWorkshopLinePurchaseDataTag());
        PerCompanyUpgradeTags.Add(GetWorkshopLineAttributePrefillTag());
        PerCompanyUpgradeTags.Add(GetHoldOrderMigrationTag());
        PerCompanyUpgradeTags.Add(GetAvailabilityTimeExportTag());
        PerCompanyUpgradeTags.Add(GetWorkshopLineSerialNoTag());
    end;
}
