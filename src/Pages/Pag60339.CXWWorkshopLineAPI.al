page 60339 "CXW Workshop Line API"
{
    PageType = API;
    SourceTable = "CXW Workshop Line";
    APIPublisher = 'chronext';
    APIGroup = 'CXTServices';
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
                field(genuine; Rec."CXW isAuthentic") { }
                field(dialColor; Rec."CXW Dial Color") { }
                field(caseDiameter; Rec."CXW Case Diameter") { }
                field(braceletMaterial; Rec."CXW Bracelet Material") { }
                field(caseMaterial; Rec."CXW Case Material") { }
                field(movement; Rec."CXW Movement") { }
                field(gender; Rec."CXW Gender") { }
                field(crystal; Rec."CXW Crystal") { }
                field(features; Rec."CXW Features") { }
                field(attribute9; Rec."CXW Attribute 9") { }
                field(attribute10; Rec."CXW Attribute 10") { }
                field(tenant; TenantName)
                {
                    Editable = false;
                }
                field(vendorOrderNo; Rec."CXW Vendor Order No.")
                {
                    Editable = false;
                }
                field(vendorNo; Rec."CXW Vendor No.")
                {
                    Editable = false;
                }
                field(vendorName; Rec."CXW Vendor Name")
                {
                    Editable = false;
                }
                field(variantCode; Rec."CXW Variant Code")
                {
                    Editable = false;
                }
                field(description; Rec."CXW Description")
                {
                    Editable = false;
                }
                field(brand; Rec."CXW Brand")
                {
                    Editable = false;
                }
                field(model; Rec."CXW Model")
                {
                    Editable = false;
                }
                field(subModel; Rec."CXW Sub Model")
                {
                    Editable = false;
                }
                field(ref; Rec."CXW Reference")
                {
                    Editable = false;
                }
                field(year; Rec."CXW Year")
                {
                    Editable = false;
                }
                field(box; Rec."CXW Box")
                {
                    Editable = false;
                }
                field(certificate; Rec."CXW Certificate")
                {
                    Editable = false;
                }
                field(condition; Rec."CXW Condition")
                {
                    Editable = false;
                }
                field(quantity; Rec."CXW Quantity")
                {
                    Editable = false;
                }
                field(unitPrice; Rec."CXW Unit Price")
                {
                    Editable = false;
                }
                field(seller_currency; Rec."CXW Currency Code")
                {
                    Editable = false;
                }
                field(usedGoods; Rec."CXW Used Goods")
                {
                    Editable = false;
                }
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
        CheckPurchaseDataUnchanged();
        exit(true);
    end;

    trigger OnOpenPage()
    var
        PurchasesSetup: Record "Purchases & Payables Setup";
    begin
        // Read at runtime, not stored on the line, so a corrected value applies to all lines.
        if PurchasesSetup.Get() then
            TenantName := PurchasesSetup."CXW Workshop Tenant";
    end;

    local procedure CheckPurchaseDataUnchanged()
    begin
        if Rec."CXW Vendor Order No." <> xRec."CXW Vendor Order No." then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Vendor Order No."));
        if Rec."CXW Vendor No." <> xRec."CXW Vendor No." then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Vendor No."));
        if Rec."CXW Vendor Name" <> xRec."CXW Vendor Name" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Vendor Name"));
        if Rec."CXW Variant Code" <> xRec."CXW Variant Code" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Variant Code"));
        if Rec."CXW Description" <> xRec."CXW Description" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Description"));
        if Rec."CXW Quantity" <> xRec."CXW Quantity" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Quantity"));
        if Rec."CXW Unit Price" <> xRec."CXW Unit Price" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Unit Price"));
        if Rec."CXW Currency Code" <> xRec."CXW Currency Code" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Currency Code"));
        if Rec."CXW Used Goods" <> xRec."CXW Used Goods" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Used Goods"));
        if Rec."CXW Brand" <> xRec."CXW Brand" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Brand"));
        if Rec."CXW Model" <> xRec."CXW Model" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Model"));
        if Rec."CXW Sub Model" <> xRec."CXW Sub Model" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Sub Model"));
        if Rec."CXW Reference" <> xRec."CXW Reference" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Reference"));
        if Rec."CXW Year" <> xRec."CXW Year" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Year"));
        if Rec."CXW Condition" <> xRec."CXW Condition" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Condition"));
        if Rec."CXW Box" <> xRec."CXW Box" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Box"));
        if Rec."CXW Certificate" <> xRec."CXW Certificate" then
            Error(FieldNotEditableErr, Rec.FieldCaption("CXW Certificate"));
    end;

    var
        TenantName: Text;
        FieldNotEditableErr: Label '%1 cannot be changed through this API.', Comment = '%1 = field caption';
}
