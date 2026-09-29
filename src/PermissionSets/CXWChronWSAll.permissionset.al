namespace SL;

permissionset 60336 CXWChronWSAll
{
    Assignable = true;
    Permissions = tabledata "CXW General Sales Price Setup" = RIMD,
        tabledata "CXW Sales Price Archive" = RIMD,
        tabledata "CXW Sales Price Checking" = RIMD,
        tabledata "CXW Price Import Protocol" = RIMD,
        tabledata "CXW Sales Price Inbound File" = RIMD,
        tabledata "CXW Sales Price Out. File" = RIMD,
        tabledata "CXW API Interface Setup" = RIMD,
        tabledata "CXW Http Call Log" = RIMD,
        tabledata "Data Export Entry" = RIM,
        table "CXW General Sales Price Setup" = X,
        table "CXW Sales Price Archive" = X,
        table "CXW Sales Price Checking" = X,
        table "CXW Price Import Protocol" = X,
        table "CXW Sales Price Inbound File" = X,
        table "CXW Sales Price Out. File" = X,
        table "CXW API Interface Setup" = X,
        table "CXW Http Call Log" = X,
        table "Data Export Entry" = X,
        codeunit "CXW Import Sales Prices" = X,
        codeunit "CXW Export Gateway Sales Price" = X,
        xmlport "CXW Import Sales Price" = X,
        page "CXW General Sales Price Setup" = X,
        page "CXW Sales Price Archive" = X,
        page "CXW Sales Price Checking List" = X,
        page "CXW API Interface Setup" = X,
        page "CXW API Interface Setup Card" = X,
        page "CXW Http Call Log" = X;
}
