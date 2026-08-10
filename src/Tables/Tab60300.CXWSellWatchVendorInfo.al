table 60300 "CXW SellWatch Vendor Info"
{
    Caption = 'SellWatch Vendor Info';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "CXW Entry No"; Integer)
        {
            Caption = 'Entry No';
            AutoIncrement = true;
            DataClassification = ToBeClassified;
        }
        field(2; "CXW Vendor Name"; Text[50])
        {
            Caption = 'Vendor Name';
            DataClassification = ToBeClassified;
        }
        field(4; "CXW Name 2"; Text[50])
        {
            Caption = 'Name 2';
            DataClassification = ToBeClassified;
        }
        field(5; "CXW Address"; Text[50])
        {

            Caption = 'Address';
            DataClassification = ToBeClassified;
        }
        field(6; "CXW Address 2"; Text[50])
        {
            Caption = 'Address 2';
            DataClassification = ToBeClassified;
        }
        field(7; "CXW City"; Text[30])
        {
            Caption = 'City';

            DataClassification = ToBeClassified;
        }
        field(8; "CXW Contact"; Text[50])
        {

            Caption = 'Contact';
            DataClassification = ToBeClassified;
        }
        field(9; "CXW PhoneNo"; Text[30])
        {

            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
            DataClassification = ToBeClassified;
        }
        field(10; "CXW IBAN"; Code[50])
        {
            Caption = 'IBAN';
            DataClassification = ToBeClassified;
        }
        field(11; "CXW Email"; Text[50])
        {
            Caption = 'Email';
            DataClassification = ToBeClassified;
        }
        field(12; "CXW CountryCode"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
            DataClassification = ToBeClassified;
        }
        field(13; "CXW Post Code"; Code[20])
        {
            Caption = 'Zip';

            DataClassification = ToBeClassified;
        }
        field(14; "CXW County"; Text[30])
        {
            Caption = 'County';
            DataClassification = ToBeClassified;
        }
        field(15; "CXW Created"; Boolean)
        {
            Caption = 'Created';
            DataClassification = ToBeClassified;
        }
        field(16; "CXW Brand"; Text[250])
        {
            Caption = 'Brand';
            DataClassification = ToBeClassified;
        }
        field(17; "CXW Model"; Text[250])
        {
            Caption = 'Model';
            DataClassification = ToBeClassified;
        }
        field(18; "CXW Reference"; Text[250])
        {
            Caption = 'Reference';
            DataClassification = ToBeClassified;
        }
        field(19; "CXW SKU"; Text[250])
        {
            Caption = 'SKU';
            DataClassification = ToBeClassified;
        }
        field(20; "CXW Construction Year"; Text[30])
        {
            Caption = 'Construction Year';
            DataClassification = ToBeClassified;
        }
        field(21; "CXW Watch Condition"; Text[30])
        {
            Caption = 'Watch Condition';
            DataClassification = ToBeClassified;
        }
        field(22; "CXW Paper Available"; Boolean)
        {
            Caption = 'Paper Available';
            DataClassification = ToBeClassified;
        }
        field(23; "CXW Box Available"; Boolean)
        {
            Caption = 'Box Available';
            DataClassification = ToBeClassified;
        }
        field(24; "CXW Offer Type"; Text[250])
        {
            Caption = 'Offer Type';
            DataClassification = ToBeClassified;
        }
        field(25; "CXW Taxation"; Text[30])
        {
            Caption = 'Taxation';
            DataClassification = ToBeClassified;
        }
        field(26; "CXW Final Offer Price"; Decimal)
        {
            Caption = 'Final Offer Price';
            DataClassification = ToBeClassified;
        }
        field(27; "CXW Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
            DataClassification = ToBeClassified;
        }
        field(28; "CXW BIC"; Code[50])
        {
            Caption = 'BIC';
            DataClassification = ToBeClassified;
        }
        field(29; "CXW PO Number"; Code[50])
        {
            Caption = 'PO Number';
            DataClassification = ToBeClassified;
        }
        field(30; "CXW CurrencyCode"; Code[30])
        {
            Caption = 'Currency Code';
            DataClassification = ToBeClassified;
        }
        field(31; "CXW CreatePOinBV"; Boolean)
        {
            Caption = 'Create PO in BV';
            DataClassification = ToBeClassified;
        }
        field(32; "CXW SRid"; Code[30])
        {
            Caption = 'SRid';
            DataClassification = ToBeClassified;
        }
        field(33; "CXW VendorNo"; Code[30])
        {
            Caption = 'Vendor No.';
            DataClassification = ToBeClassified;
        }
        field(34; "CXW BillToAddress"; Text[50])
        {
            Caption = 'Bill-to Address';
            DataClassification = ToBeClassified;
        }
        field(35; "CXW BillToName"; Text[50])
        {
            Caption = 'Bill-to Name';
            DataClassification = ToBeClassified;
        }
        field(36; "CXW BillToCity"; Text[30])
        {
            Caption = 'Bill-to City';
            DataClassification = ToBeClassified;
        }
        field(37; "CXW BillToPostCode"; Code[10])
        {
            Caption = 'Bill-to Post Code';
            DataClassification = ToBeClassified;
        }
        field(38; "CXW BillToCountryCode"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            DataClassification = ToBeClassified;
        }
        field(39; "CXW BillToCounty"; Text[30])
        {
            Caption = 'Bill-to County';
            DataClassification = ToBeClassified;
        }
        field(40; "CXW PickupDate"; Date)
        {
            Caption = 'Pickup Date';
            DataClassification = ToBeClassified;
        }
        field(41; "CXW Tracking Number"; Text[30])
        {
            Caption = 'Tracking Number';
            FieldClass = FlowField;
            CalcFormula = lookup("Purchase Header"."CXW Tracking Number" where("Document Type" = const(Order), "No." = field("CXW PO Number")));
            Editable = false;
        }
        field(42; "CXW CXTSalesPrice"; Decimal)
        {
            Caption = 'CXT Sales Price';
            DataClassification = ToBeClassified;
        }
        field(43; "CXW Gender"; Text[30])
        {
            // Quelle: SKU ITBO-1223
            Caption = 'Gender';
            DataClassification = ToBeClassified;
        }
        field(44; "CXW LanguageCode"; Text[30])
        {
            // Quelle: SKU ITBO-1223
            Caption = 'Language Code';
            DataClassification = ToBeClassified;
        }
        field(45; "CXW NuveiAccountCode"; Text[50])
        {
            Caption = 'Nuvei Account Code';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "CXW Entry No")
        {
            Clustered = true;
        }
    }
}
