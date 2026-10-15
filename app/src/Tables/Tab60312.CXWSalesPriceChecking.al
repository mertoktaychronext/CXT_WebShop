table 60312 "CXW Sales Price Checking"
{
    Caption = 'Sales Price Checking';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "CXW Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
            NotBlank = true;
            TableRelation = Item;
        }
        field(3; "CXW Stock Price"; Decimal)
        {
            Caption = 'Stock Price';
            DataClassification = ToBeClassified;
        }
        field(4; "CXW Non Stock Price"; Decimal)
        {
            Caption = 'Non Stock Price';
            DataClassification = ToBeClassified;
        }
        field(5; "CXW Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = ToBeClassified;
            TableRelation = Currency;
        }
        field(6; "CXW Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;
        }
        field(7; "CXW Starting Time"; Time)
        {
            Caption = 'Starting Time';
            DataClassification = ToBeClassified;
        }
        field(8; "CXW Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = ToBeClassified;
        }
        field(9; "CXW Ending Time"; Time)
        {
            Caption = 'Ending Time';
            DataClassification = ToBeClassified;
        }
        field(10; "CXW Remark"; Text[150])
        {
            Caption = 'Remark';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(11; "CXW Last Modified UserID"; Code[50])
        {
            Caption = 'Last Modified UserID';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(12; "CXW Last Modified Date"; DateTime)
        {
            Caption = 'Last Modified Date';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(13; "CXW Accept New Setup"; Boolean)
        {
            Caption = 'Accept New Setup';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                if (not xRec."CXW Accept New Setup") and Rec."CXW Accept New Setup" and (not Rec."CXW Validated") then
                    Error(PleaseValidateErr);

                if Rec."CXW Accept New Setup" then begin
                    Rec."CXW Remark Backup" := Rec."CXW Remark";
                    Rec."CXW Remark" := '';
                end else
                    Rec."CXW Remark Backup" := '';

                if xRec."CXW Accept New Setup" and (not Rec."CXW Accept New Setup") then
                    Rec."CXW Validated" := false;
            end;
        }

        field(15; "CXW Reason Code"; Enum "CXW Sales Price Reason Code")
        {
            Caption = 'Reason Code';
            DataClassification = ToBeClassified;
        }
        field(16; "CXW Comment"; Text[250])
        {
            Caption = 'Comment';
            DataClassification = ToBeClassified;
        }
        field(17; "CXW Exchange Rate Amount"; Decimal)
        {
            Caption = 'Exchange Rate Amount';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(18; "CXW Exchange Rate Date"; Date)
        {
            Caption = 'Exchange Rate Date';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(19; "CXW Remark Backup"; Text[150])
        {
            Caption = 'Remark Backup';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(20; "CXW Strike Price"; Decimal)
        {
            Caption = 'Strike Price';
            DataClassification = ToBeClassified;
        }
        field(21; "CXW Recom. Retail Price"; Decimal)
        {
            Caption = 'Recom. Retail Price';
            DataClassification = ToBeClassified;
        }
        field(22; "CXW Validated"; Boolean)
        {
            Caption = 'Validated';
            DataClassification = ToBeClassified;
        }
        field(23; "CXW Old Stock Price"; Decimal)
        {
            Caption = 'Old Stock Price';
            DataClassification = ToBeClassified;
        }
        field(24; "CXW Countries Processed"; Boolean)
        {
            Caption = 'Countries Processed';
            DataClassification = ToBeClassified;
        }
        field(25; "CXW Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = ToBeClassified;
        }
        field(26; "CXW Export Status"; Enum "CXW Sales Price Export Status")
        {
            Caption = 'Export Status';
            DataClassification = ToBeClassified;
        }
        field(27; "CXW Country Code"; Code[10])
        {
            Caption = 'Country Code';
            DataClassification = ToBeClassified;
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                Country.Get("CXW Country Code");
                Country.TestField("CXW Sales Price Activated", true);
                "CXW Currency Code" := Country."CXW Sales Price Currency Code";
            end;

        }
        field(28; "CXW Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
            DataClassification = ToBeClassified;
            InitValue = true;
        }
        field(50000; "CXW Version No."; Integer)
        {
            Caption = 'Version No.';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "CXW Item No.", "CXW Currency Code", "CXW Country Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        "CXW Last Modified Date" := CurrentDateTime;
        "CXW Last Modified UserID" := UserId;
    end;

    trigger OnModify()
    begin
        "CXW Last Modified Date" := CurrentDateTime;
        "CXW Last Modified UserID" := UserId;

        if Rec."CXW Currency Code" <> xRec."CXW Currency Code" then begin
            Rec."CXW Validated" := false;
            Rec."CXW Accept New Setup" := false;
            Rec."CXW Remark" := '';
        end;
    end;

    trigger OnRename()
    begin
        "CXW Last Modified Date" := CurrentDateTime;
        "CXW Last Modified UserID" := UserId;
    end;

    var
        PleaseValidateErr: Label 'Please click Validate button.';
        Country: Record "Country/Region";
}
