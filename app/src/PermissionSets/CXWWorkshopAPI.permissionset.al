permissionset 60302 "CXW Workshop API"
{
    Assignable = true;
    Caption = 'CXW Workshop API';
    // Read on the purchases setup only for the "tenant" field of the workshop lines API.
    Permissions = tabledata "CXW Workshop Line" = RM,
        tabledata "Purchases & Payables Setup" = R;
}
