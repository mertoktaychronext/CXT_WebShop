permissionset 60350 "CXW Real. Inventory"
{
    Assignable = true;

    Permissions = tabledata "CXW Realtime Inventory" = RIMD,
        tabledata "Item Ledger Entry" = R,
        tabledata Item = R,
        tabledata "Sales Price" = R,
        tabledata "Item Attribute Value" = R,
        tabledata "Item Attribute Value Mapping" = R,
        table "CXW Realtime Inventory" = X,
        codeunit "CXW Realtime Inventory Mgt." = X,
        page "CXW Realtime Inventory" = X;
}
