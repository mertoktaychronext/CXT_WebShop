permissionset 51001 SWChronWSAll
{
    Assignable = true;
    Permissions = tabledata "SellWatch Vendor Info" = RIMD,
        tabledata "Watch Online Approval" = RIMD,
        tabledata "SW Http Call Log" = RIMD,
        table "SellWatch Vendor Info" = X,
        table "Watch Online Approval" = X,
        table "SW Http Call Log" = X,
        codeunit "SellWatch Mgt" = X,
        page "SellWatch-Overview" = X,
        page "SellWatch info" = X,
        page "SW Http Call Log" = X;
}
