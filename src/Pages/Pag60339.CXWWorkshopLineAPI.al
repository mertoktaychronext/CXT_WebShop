page 60339 "CXW Workshop Line API"
{
    PageType = API;
    SourceTable = "CXW Workshop Line";
    APIPublisher = 'saliniLife';
    APIGroup = 'workshop';
    APIVersion = 'v1.0';
    EntityName = 'workshopLine';
    EntitySetName = 'workshopLines';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(documentType; Rec."CXW Document Type")
                {
                    Editable = false;
                }
                field(documentNo; Rec."CXW Document No.")
                {
                    Editable = false;
                }
                field(lineNo; Rec."CXW Line No.")
                {
                    Editable = false;
                }
                field(itemNo; Rec."CXW Item No.")
                {
                    Editable = false;
                }
                field(manufacturerSerialNo; Rec."CXW Manufacturer Serial No.")
                {
                    Editable = false;
                }
                field(status; Rec."CXW Status") { }
                field(genuine; Rec."CXW Genuine") { }
                field(attribute1; Rec."CXW Dial Color") { }
                field(attribute2; Rec."CXW Case Diameter") { }
                field(attribute3; Rec."CXW Bracelet Material") { }
                field(attribute4; Rec."CXW Case Material") { }
                field(attribute5; Rec."CXW Movement") { }
                field(attribute6; Rec."CXW Gender") { }
                field(attribute7; Rec."CXW Crystal") { }
                field(attribute8; Rec."CXW Features") { }
                field(attribute9; Rec."CXW Attribute 9") { }
                field(attribute10; Rec."CXW Attribute 10") { }
                field(systemId; Rec.SystemId)
                {
                    Editable = false;
                }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
        if Rec."CXW Document Type" <> xRec."CXW Document Type" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Document Type"));
        if Rec."CXW Document No." <> xRec."CXW Document No." then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Document No."));
        if Rec."CXW Line No." <> xRec."CXW Line No." then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Line No."));
        if Rec."CXW Item No." <> xRec."CXW Item No." then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Item No."));
        if Rec."CXW Manufacturer Serial No." <> xRec."CXW Manufacturer Serial No." then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Manufacturer Serial No."));
        exit(true);
    end;

    var
        FieldNotEditableErr: Label '%1 cannot be changed through this API.', Comment = '%1 = field caption';
}
