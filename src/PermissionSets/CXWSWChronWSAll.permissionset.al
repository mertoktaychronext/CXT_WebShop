permissionset 60310 "CXW SWChronWSAll"
{
    Assignable = true;
    Permissions = tabledata "CXW SellWatch Vendor Info" = RIMD,
        tabledata "CXW Watch Online Approval" = RIMD,
        tabledata "CXW Http Call Log" = RIMD,
        tabledata "Purchases & Payables Setup" = R,
        table "CXW SellWatch Vendor Info" = X,
        table "CXW Watch Online Approval" = X,
        table "CXW Http Call Log" = X,
        codeunit "CXW SellWatch Mgt" = X,
        codeunit "CXW SellWatch Process Offer" = X,
        page "CXW SellWatch-Overview" = X,
        page "CXW SellWatch info" = X,
        page "CXW SellWatch API" = X,
        page "CXW Http Call Log" = X;
}
