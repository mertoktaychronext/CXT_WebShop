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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetWorkshopLinePurchaseDataTag());
        PerCompanyUpgradeTags.Add(GetWorkshopLineAttributePrefillTag());
        PerCompanyUpgradeTags.Add(GetHoldOrderMigrationTag());
    end;
}
