permissionset 60301 "CXW Workshop All"
{
    Assignable = true;
    Permissions = tabledata "CXW Workshop Line" = RIMD,
        tabledata "Purchase Header" = RMD,
        tabledata "Purchase Line" = RMD,
        tabledata Item = RM,
        tabledata "Item Attribute" = RIM,
        tabledata "Item Attribute Value" = RIM,
        tabledata "Item Attribute Value Mapping" = RIM,
        tabledata "Purchases & Payables Setup" = R,
        tabledata "Sales Invoice Header" = R,
        tabledata "Sales Invoice Line" = R,
        tabledata "CXW Consignment Posting Entry" = RIMD,
        table "CXW Workshop Line" = X,
        table "CXW Consignment Posting Entry" = X,
        codeunit "CXW Process Workshop Lines" = X,
        codeunit "CXW Consignment Sale Detection" = X,
        codeunit "CXW Post Consignment Purchases" = X,
        page "CXW Workshop Lines" = X,
        page "CXW Workshop Line API" = X,
        page "CXW Serial No. Input" = X,
        page "CXW Cons. Posting Entries" = X;
}
