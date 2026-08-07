permissionset 51001 SWChronWSAll
{
    Assignable = true;
    Permissions = tabledata "SellWatch Vendor Info" = RIMD,
        tabledata "Watch Online Approval" = RIMD,
        table "SellWatch Vendor Info" = X,
        table "Watch Online Approval" = X,
        codeunit "SellWatch Mgt" = X,
        page "SellWatch-Overview" = X,
        page "SellWatch info" = X;
}
