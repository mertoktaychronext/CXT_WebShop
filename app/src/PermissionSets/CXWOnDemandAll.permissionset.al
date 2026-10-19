permissionset 60337 "CXW On Demand All"
{
    Assignable = true;
    Permissions = tabledata "Sales Header" = R,
        tabledata "Sales Line" = RM,
        tabledata "Purchase Header" = RIMD,
        tabledata "Purchase Line" = RIMD,
        tabledata Vendor = R,
        tabledata Item = R,
        tabledata "Reservation Entry" = R,
        tabledata "Item Attribute" = R,
        tabledata "Item Attribute Value" = R,
        tabledata "Item Attribute Value Mapping" = R,
        codeunit "CXW On Demand Link Mgt" = X,
        page "CXW On Demand Sales Lines" = X,
        page "CXW On Demand Purch. Lookup" = X,
        page "CXW On Demand Purchase Lines" = X,
        page "CXW On Demand Sales Lookup" = X;
}
