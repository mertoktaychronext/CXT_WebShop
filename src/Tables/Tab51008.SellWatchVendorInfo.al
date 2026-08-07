table 51008 "SellWatch Vendor Info"
{
    Caption = 'SellWatch Vendor Info';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No"; Integer)
        {
            Caption = 'Entry No';
            AutoIncrement = true;
            DataClassification = ToBeClassified;
        }
        field(2; "Vendor Name"; Text[50])
        {
            Caption = 'Vendor Name';
            DataClassification = ToBeClassified;
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
            DataClassification = ToBeClassified;
        }
        field(5; Address; Text[50])
        {
            // TODO: Original-OnValidate referenzierte Codeunit 5275321 "Postal Check Management" mit leerem Trigger-Body (keine Logik) – Codeunit ist laut Nutzer nicht mehr im Einsatz, daher ersatzlos entfernt.
            Caption = 'Address';
            DataClassification = ToBeClassified;
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            DataClassification = ToBeClassified;
        }
        field(7; City; Text[30])
        {
            Caption = 'City';

            DataClassification = ToBeClassified;
        }
        field(8; Contact; Text[50])
        {
            // TODO: Original-OnLookup deklarierte Record 5054 "Contact Business Relation" und Record 5050 Contact mit leerem Trigger-Body (keine Logik) – ersatzlos entfernt.
            Caption = 'Contact';
            DataClassification = ToBeClassified;
        }
        field(9; PhoneNo; Text[30])
        {
            // TODO: Original-OnValidate referenzierte Codeunit 5105000 "System Management" mit leerem Trigger-Body (keine Logik) – Codeunit ist laut Nutzer nicht mehr im Einsatz, daher ersatzlos entfernt.
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
            DataClassification = ToBeClassified;
        }
        field(10; IBAN; Code[50])
        {
            Caption = 'IBAN';
            DataClassification = ToBeClassified;
        }
        field(11; Email; Text[50])
        {
            Caption = 'Email';
            DataClassification = ToBeClassified;
        }
        field(12; CountryCode; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
            DataClassification = ToBeClassified;
        }
        field(13; "Post Code"; Code[20])
        {
            Caption = 'Zip';

            DataClassification = ToBeClassified;
        }
        field(14; County; Text[30])
        {
            Caption = 'County';
            DataClassification = ToBeClassified;
        }
        field(15; Created; Boolean)
        {
            Caption = 'Created';
            DataClassification = ToBeClassified;
        }
        field(16; Brand; Text[250])
        {
            Caption = 'Brand';
            DataClassification = ToBeClassified;
        }
        field(17; Model; Text[250])
        {
            Caption = 'Model';
            DataClassification = ToBeClassified;
        }
        field(18; Reference; Text[250])
        {
            Caption = 'Reference';
            DataClassification = ToBeClassified;
        }
        field(19; SKU; Text[250])
        {
            Caption = 'SKU';
            DataClassification = ToBeClassified;
        }
        field(20; "Construction Year"; Text[30])
        {
            Caption = 'Construction Year';
            DataClassification = ToBeClassified;
        }
        field(21; "Watch Condition"; Text[30])
        {
            Caption = 'Watch Condition';
            DataClassification = ToBeClassified;
        }
        field(22; "Paper Available"; Boolean)
        {
            Caption = 'Paper Available';
            DataClassification = ToBeClassified;
        }
        field(23; "Box Available"; Boolean)
        {
            Caption = 'Box Available';
            DataClassification = ToBeClassified;
        }
        field(24; "Offer Type"; Text[250])
        {
            Caption = 'Offer Type';
            DataClassification = ToBeClassified;
        }
        field(25; Taxation; Text[30])
        {
            Caption = 'Taxation';
            DataClassification = ToBeClassified;
        }
        field(26; "Final Offer Price"; Decimal)
        {
            Caption = 'Final Offer Price';
            DataClassification = ToBeClassified;
        }
        field(27; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
            DataClassification = ToBeClassified;
        }
        field(28; BIC; Code[50])
        {
            Caption = 'BIC';
            DataClassification = ToBeClassified;
        }
        field(29; "PO Number"; Code[50])
        {
            Caption = 'PO Number';
            DataClassification = ToBeClassified;
        }
        field(30; CurrencyCode; Code[30])
        {
            Caption = 'Currency Code';
            DataClassification = ToBeClassified;
        }
        field(31; CreatePOinBV; Boolean)
        {
            Caption = 'Create PO in BV';
            DataClassification = ToBeClassified;
        }
        field(32; SRid; Code[30])
        {
            Caption = 'SRid';
            DataClassification = ToBeClassified;
        }
        field(33; VendorNo; Code[30])
        {
            Caption = 'Vendor No.';
            DataClassification = ToBeClassified;
        }
        field(34; BillToAddress; Text[50])
        {
            Caption = 'Bill-to Address';
            DataClassification = ToBeClassified;
        }
        field(35; BillToName; Text[50])
        {
            Caption = 'Bill-to Name';
            DataClassification = ToBeClassified;
        }
        field(36; BillToCity; Text[30])
        {
            Caption = 'Bill-to City';
            DataClassification = ToBeClassified;
        }
        field(37; BillToPostCode; Code[10])
        {
            Caption = 'Bill-to Post Code';
            DataClassification = ToBeClassified;
        }
        field(38; BillToCountryCode; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            DataClassification = ToBeClassified;
        }
        field(39; BillToCounty; Text[30])
        {
            Caption = 'Bill-to County';
            DataClassification = ToBeClassified;
        }
        field(40; PickupDate; Date)
        {
            Caption = 'Pickup Date';
            DataClassification = ToBeClassified;
        }
        field(41; "Tracking Number"; Text[30])
        {
            Caption = 'Tracking Number';
            FieldClass = FlowField;
            CalcFormula = lookup("Purchase Header"."Tracking Number" where("Document Type" = const(Order), "No." = field("PO Number")));
            Editable = false;
        }
        field(42; CXTSalesPrice; Decimal)
        {
            Caption = 'CXT Sales Price';
            DataClassification = ToBeClassified;
        }
        field(43; Gender; Text[30])
        {
            // Quelle: SKU ITBO-1223
            Caption = 'Gender';
            DataClassification = ToBeClassified;
        }
        field(44; LanguageCode; Text[30])
        {
            // Quelle: SKU ITBO-1223
            Caption = 'Language Code';
            DataClassification = ToBeClassified;
        }
        field(45; NuveiAccountCode; Text[50])
        {
            Caption = 'Nuvei Account Code';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Entry No")
        {
            Clustered = true;
        }
    }
}
