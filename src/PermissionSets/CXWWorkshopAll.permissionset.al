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
        table "CXW Workshop Line" = X,
        codeunit "CXW Process Workshop Lines" = X,
        page "CXW Workshop Lines" = X,
        page "CXW Workshop Line API" = X,
        page "CXW Serial No. Input" = X;
}
