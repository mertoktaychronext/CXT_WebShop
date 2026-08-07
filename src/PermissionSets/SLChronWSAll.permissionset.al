namespace SL;

permissionset 51000 SLChronWSAll
{
    Assignable = true;
    Permissions = tabledata "SL General Sales Price Setup" = RIMD,
        tabledata "SL Sales Price Archive" = RIMD,
        tabledata "SL Sales Price Checking" = RIMD,
        tabledata "SL Sales Price Import Protocol" = RIMD,
        tabledata "SL Sales Price Inbound File" = RIMD,
        tabledata "SL Sales Price Outbound File" = RIMD,
        tabledata "SL API Interface Setup" = RIMD,
        table "SL General Sales Price Setup" = X,
        table "SL Sales Price Archive" = X,
        table "SL Sales Price Checking" = X,
        table "SL Sales Price Import Protocol" = X,
        table "SL Sales Price Inbound File" = X,
        table "SL Sales Price Outbound File" = X,
        table "SL API Interface Setup" = X,
        codeunit "SL Import Sales Prices" = X,
        codeunit "SL Export Gateway Sales Price" = X,
        xmlport "SL Import Sales Price" = X,
        page "SL General Sales Price Setup" = X,
        page "SL Sales Price Archive" = X,
        page "SL Sales Price Checking List" = X,
        page "SL API Interface Setup" = X;
}
