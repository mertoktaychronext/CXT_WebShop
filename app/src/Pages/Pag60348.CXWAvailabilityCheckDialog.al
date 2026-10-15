page 60348 "CXW Availability Check Dialog"
{
    Caption = 'Availability Check';
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Options)
            {
                Caption = 'Options';

                field(CountryRegionCode; CountryRegionCode)
                {
                    Caption = 'Country/Region Code';
                    ApplicationArea = All;
                    TableRelation = "Country/Region";
                    ToolTip = 'Specifies the country/region code used for the delivery-time calculation.';
                }
                field(ZoneCode; ZoneCode)
                {
                    Caption = 'Zone Code';
                    ApplicationArea = All;
                    TableRelation = Zone.Code where("Location Code" = const('HL'));
                    ToolTip = 'Specifies the zone used for the delivery-time calculation when no bin is entered.';
                }
                field(BinCode; BinCode)
                {
                    Caption = 'Bin Code';
                    ApplicationArea = All;
                    TableRelation = Bin.Code where("Location Code" = const('HL'));
                    ToolTip = 'Specifies the bin used for the delivery-time calculation. If a bin is entered, the zone is ignored.';
                }
            }
        }
    }

    procedure GetCountryRegionCode(): Code[10]
    begin
        exit(CountryRegionCode);
    end;

    procedure GetZoneCode(): Code[10]
    begin
        exit(ZoneCode);
    end;

    procedure GetBinCode(): Code[20]
    begin
        exit(BinCode);
    end;

    var
        CountryRegionCode: Code[10];
        ZoneCode: Code[10];
        BinCode: Code[20];
}
