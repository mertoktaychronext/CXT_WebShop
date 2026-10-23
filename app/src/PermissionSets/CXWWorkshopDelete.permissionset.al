permissionset 60303 "CXW Workshop Delete"
{
    Assignable = true;
    Caption = 'CXW Workshop Delete';
    // Workshop users who may also delete workshop lines (status New or Error) on the Workshop Lines page.
    IncludedPermissionSets = "CXW Workshop All";
    Permissions = tabledata "CXW Workshop Line" = RIMD;
}
