codeunit 60336 "CXW Workshop Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetWorkshopLinePurchaseDataTag()) then
            exit;

        FillPurchaseDataOnOpenLines();

        UpgradeTag.SetUpgradeTag(GetWorkshopLinePurchaseDataTag());
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

    local procedure GetWorkshopLinePurchaseDataTag(): Code[250]
    begin
        exit('CXW-WORKSHOPLINE-PURCHASEDATA-20260928');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetWorkshopLinePurchaseDataTag());
    end;
}
