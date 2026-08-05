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
        field(3; "Stock Price"; Decimal)
        {
            Caption = 'Stock Price';
            DataClassification = ToBeClassified;
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
                if (not xRec."Accept New Setup") and Rec."Accept New Setup" and (not Rec.Validated) then
                    Error('Please click Validate button.');

                if Rec."Accept New Setup" then begin
                    Rec."Remark Backup" := Rec.Remark;
                    Rec.Remark := '';
                end else
                    Rec."Remark Backup" := '';

                if xRec."Accept New Setup" and (not Rec."Accept New Setup") then
                    Rec.Validated := false;
            end;
        }

        field(15; "Reason Code"; Enum "SL Sales Price Reason Code")
        {
            Caption = 'Reason Code';
            DataClassification = ToBeClassified;
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
        field(24; "Currencies Processed"; Boolean)
        {
            Caption = 'Currencies Processed';
            DataClassification = ToBeClassified;
        }
        field(25; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = ToBeClassified;
        }
        field(26; "Export Status"; Enum "SL Sales Price Export Status")
        {
            Caption = 'Export Status';
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
        key(PK; "Item No.", "Currency Code")
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
