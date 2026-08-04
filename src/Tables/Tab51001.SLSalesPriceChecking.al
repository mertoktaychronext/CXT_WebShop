// Migriert aus NAV Table 50007 "Sales Price Checking" (1:1, Objekt-ID umnummeriert
// wegen app.json idRanges 51000-51049, Feld-IDs unverändert übernommen).
table 51001 "SL Sales Price Checking"
{
    Caption = 'Sales Price Checking';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[20])
        {
            Caption = 'Variant Code';
            DataClassification = ToBeClassified;
            NotBlank = true;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(3; "Stock Price"; Decimal)
        {
            Caption = 'Stock Price';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                // Im NAV-Quellcode war der komplette Trigger-Inhalt bereits mit "{ }" auskommentiert
                // (toter Code) und wurde daher unverändert deaktiviert übernommen:
                // if Rec."Stock Price" <> xRec."Stock Price" then begin
                //     Rec.Validated := false;
                //     Rec."Accept New Setup" := false;
                //     Rec."Non Stock Price" := 0;
                //     Rec.Remark := '';
                // end;
            end;
        }
        field(4; "Non Stock Price"; Decimal)
        {
            Caption = 'Non Stock Price';
            DataClassification = ToBeClassified;
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = ToBeClassified;
            TableRelation = Currency;
        }
        field(6; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;
        }
        field(7; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            DataClassification = ToBeClassified;
        }
        field(8; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = ToBeClassified;
        }
        field(9; "Ending Time"; Time)
        {
            Caption = 'Ending Time';
            DataClassification = ToBeClassified;
        }
        field(10; Remark; Text[150])
        {
            Caption = 'Remark';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(11; "Last Modified UserID"; Code[50])
        {
            Caption = 'Last Modified UserID';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(12; "Last Modified Date"; DateTime)
        {
            Caption = 'Last Modified Date';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(13; "Accept New Setup"; Boolean)
        {
            Caption = 'Accept New Setup';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                if (not xRec."Accept New Setup") and Rec."Accept New Setup" and (not Rec.Validated) then begin
                    Message('Please click Validate button.');
                    Error('');
                end;

                if Rec."Accept New Setup" then begin
                    Rec."Remark Backup" := Rec.Remark;
                    Rec.Remark := '';
                end else
                    Rec."Remark Backup" := '';

                if xRec."Accept New Setup" and (not Rec."Accept New Setup") then
                    Rec.Validated := false;
            end;
        }
        field(14; "Country Code"; Code[10])
        {
            Caption = 'Country Code';
            DataClassification = ToBeClassified;
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                Country.Get("Country Code");
                Country.TestField("Sales Price Activated", true);
                "Currency Code" := Country."Sales Price Currency Code";
            end;
        }
        field(15; "Reason Code"; Enum "SL Sales Price Reason Code")
        {
            Caption = 'Reason Code';
            DataClassification = ToBeClassified;
            // war Code[10] mit TableRelation="System Value Line"."System Code" WHERE (System Value No.=CONST(55001)).
            // Tabelle "System Value Line" wurde laut Kundenvorgabe NICHT migriert, sondern durch dieses
            // Enum mit den bekannten 3 Werten ersetzt.
        }
        field(16; Comment; Text[250])
        {
            Caption = 'Comment';
            DataClassification = ToBeClassified;
        }
        field(17; "Exchange Rate Amount"; Decimal)
        {
            Caption = 'Exchange Rate Amount';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(18; "Exchange Rate Date"; Date)
        {
            Caption = 'Exchange Rate Date';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(19; "Remark Backup"; Text[150])
        {
            Caption = 'Remark Backup';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(20; "Strike Price"; Decimal)
        {
            Caption = 'Strike Price';
            DataClassification = ToBeClassified;
        }
        field(21; "Recom. Retail Price"; Decimal)
        {
            Caption = 'Recom. Retail Price';
            DataClassification = ToBeClassified;
        }
        field(22; Validated; Boolean)
        {
            Caption = 'Validated';
            DataClassification = ToBeClassified;
        }
        field(23; "Old Stock Price"; Decimal)
        {
            Caption = 'Old Stock Price';
            DataClassification = ToBeClassified;
        }
        field(24; "DE Price Processed"; Boolean)
        {
            Caption = 'DE Price Processed';
            DataClassification = ToBeClassified;
        }
        field(25; "Approved By"; Code[20])
        {
            Caption = 'Approved By';
            DataClassification = ToBeClassified;
        }
        field(50000; "Version No."; Integer)
        {
            Caption = 'Version No.';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Item No.", "Variant Code", "Currency Code", "Country Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        "Last Modified Date" := CurrentDateTime;
        "Last Modified UserID" := UserId;
    end;

    trigger OnModify()
    begin
        "Last Modified Date" := CurrentDateTime;
        "Last Modified UserID" := UserId;

        if Rec."Country Code" <> xRec."Country Code" then begin
            Rec.Validated := false;
            Rec."Accept New Setup" := false;
            Rec.Remark := '';
        end;

        if Rec."Currency Code" <> xRec."Currency Code" then begin
            Rec.Validated := false;
            Rec."Accept New Setup" := false;
            Rec.Remark := '';
        end;
    end;

    trigger OnRename()
    begin
        "Last Modified Date" := CurrentDateTime;
        "Last Modified UserID" := UserId;
    end;

    var
        Country: Record "Country/Region";
}
