page 60338 "CXW Workshop Lines"
{
    Caption = 'Workshop Lines';
    PageType = List;
    SourceTable = "CXW Workshop Line";
    Editable = true;
    InsertAllowed = false;
    // Only lines with status New or Error, and only with permission set "CXW Workshop Delete" (see table OnDelete).
    DeleteAllowed = true;
    ModifyAllowed = true;
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                // Key and item fields link the line to its purchase line; changing them would rename or detach it.
                field("CXW Document Type"; Rec."CXW Document Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the purchase document type this workshop line belongs to.';
                }
                field("CXW Document No."; Rec."CXW Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the purchase document number this workshop line belongs to.';
                }
                field("CXW Line No."; Rec."CXW Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the purchase line number this workshop line belongs to.';
                }
                field("CXW Item No."; Rec."CXW Item No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the item that was sent to the workshop.';
                }
                field("CXW Manufacturer Serial No."; Rec."CXW Manufacturer Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the manufacturer serial number captured when the item was sent to the workshop.';
                }
                field("CXW Serial No."; Rec."CXW Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Business Central serial number of the watch, as assigned in the item tracking of the purchase line when the line was sent to the workshop.';
                }
                field("CXW Status"; Rec."CXW Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current workshop review status.';
                }
                field("CXW isAuthentic"; Rec."CXW isAuthentic")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the workshop confirmed the item as genuine.';
                }
                field("CXW Dial Color"; Rec."CXW Dial Color")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the item attribute "Zifferblatt Farbe 1" (ID 22). It is prefilled from the item when the line is sent to the workshop, may be corrected by the workshop, and is written back to the same attribute when the line is processed.';
                }
                field("CXW Case Diameter"; Rec."CXW Case Diameter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the item attribute "Gehäuse Größe" (ID 18). It is prefilled from the item when the line is sent to the workshop, may be corrected by the workshop, and is written back to the same attribute when the line is processed.';
                }
                field("CXW Bracelet Material"; Rec."CXW Bracelet Material")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the item attribute "Armband Material" (ID 23). It is prefilled from the item when the line is sent to the workshop, may be corrected by the workshop, and is written back to the same attribute when the line is processed.';
                }
                field("CXW Case Material"; Rec."CXW Case Material")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the item attribute "Gehäuse Material" (ID 16). It is prefilled from the item when the line is sent to the workshop, may be corrected by the workshop, and is written back to the same attribute when the line is processed.';
                }
                field("CXW Movement"; Rec."CXW Movement")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the item attribute "Werk" (ID 15). It is prefilled from the item when the line is sent to the workshop, may be corrected by the workshop, and is written back to the same attribute when the line is processed.';
                }
                field("CXW Gender"; Rec."CXW Gender")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the item attribute "Geschlecht" (ID 24). It is prefilled from the item when the line is sent to the workshop, may be corrected by the workshop, and is written back to the same attribute when the line is processed.';
                }
                field("CXW Crystal"; Rec."CXW Crystal")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the item attribute "Glas" (ID 20). It is prefilled from the item when the line is sent to the workshop, may be corrected by the workshop, and is written back to the same attribute when the line is processed.';
                }
                field("CXW Features"; Rec."CXW Features")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an additional value reported by the workshop. No item attribute is assigned to this field yet, so it is neither prefilled nor written back to the item.';
                }
                field("CXW Attribute 9"; Rec."CXW Attribute 9")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an additional value reported by the workshop. No item attribute is assigned to this field yet, so it is neither prefilled nor written back to the item.';
                }
                field("CXW Attribute 10"; Rec."CXW Attribute 10")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an additional value reported by the workshop. No item attribute is assigned to this field yet, so it is neither prefilled nor written back to the item.';
                }
                field("CXW Created At"; Rec."CXW Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this workshop line was created.';
                }
                field("CXW Checked At"; Rec."CXW Checked At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the workshop set the status to "WS checked".';
                }
                field("CXW Last Error"; Rec."CXW Last Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last error encountered while processing this workshop line.';
                }
                field("CXW Vendor No."; Rec."CXW Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor of the purchase order, as sent to the workshop.';
                }
                field("CXW Vendor Name"; Rec."CXW Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the vendor of the purchase order, as sent to the workshop.';
                }
                field("CXW Vendor Order No."; Rec."CXW Vendor Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor order number of the purchase order, as sent to the workshop.';
                }
                field("CXW Variant Code"; Rec."CXW Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the variant of the purchase order line, as sent to the workshop.';
                }
                field("CXW Description"; Rec."CXW Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the purchase order line, as sent to the workshop.';
                }
                field("CXW Quantity"; Rec."CXW Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity of the purchase order line, as sent to the workshop.';
                }
                field("CXW Unit Price"; Rec."CXW Unit Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the direct unit cost of the purchase order line, as sent to the workshop.';
                }
                field("CXW Currency Code"; Rec."CXW Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the purchase order (local currency code if the order has none), as sent to the workshop.';
                }
                field("CXW Used Goods"; Rec."CXW Used Goods")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the purchase order line is used goods, as sent to the workshop.';
                }
                field("CXW Brand"; Rec."CXW Brand")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the brand of the watch from the item attributes, as sent to the workshop.';
                }
                field("CXW Model"; Rec."CXW Model")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the model of the watch from the item attributes, as sent to the workshop.';
                }
                field("CXW Sub Model"; Rec."CXW Sub Model")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sub model of the watch from the item attributes, as sent to the workshop.';
                }
                field("CXW Reference"; Rec."CXW Reference")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reference of the watch from the item attributes, as sent to the workshop.';
                }
                field("CXW Year"; Rec."CXW Year")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the year of the watch from the item attributes, as sent to the workshop.';
                }
                field("CXW Condition"; Rec."CXW Condition")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the condition of the watch from the item attributes, as sent to the workshop.';
                }
                field("CXW Box"; Rec."CXW Box")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the box information of the watch from the item attributes, as sent to the workshop.';
                }
                field("CXW Certificate"; Rec."CXW Certificate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the certificate information of the watch from the item attributes, as sent to the workshop.';
                }
            }
        }
    }
}
