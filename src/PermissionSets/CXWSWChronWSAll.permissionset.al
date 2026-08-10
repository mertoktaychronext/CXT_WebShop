permissionset 60310 "CXW SWChronWSAll"
{
    Assignable = true;
    Permissions = tabledata "CXW SellWatch Vendor Info" = RIMD,
        tabledata "CXW Watch Online Approval" = RIMD,
        tabledata "CXW SW Http Call Log" = RIMD,
        table "CXW SellWatch Vendor Info" = X,
        table "CXW Watch Online Approval" = X,
        table "CXW SW Http Call Log" = X,
        codeunit "CXW SellWatch Mgt" = X,
        page "CXW SellWatch-Overview" = X,
        page "CXW SellWatch info" = X,
        page "CXW SW Http Call Log" = X;
}
