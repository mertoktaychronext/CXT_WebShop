codeunit 60346 "CXW On Demand Link Mgt"
{
    procedure IsOnDemandItem(ItemNo: Code[20]): Boolean
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        if ItemNo = '' then
            exit(false);

        ItemAttribute.SetRange(Name, ReplenishmentAttributeNameLbl);
        if not ItemAttribute.FindFirst() then
            exit(false);

        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.SetRange(Value, ReplenishmentYesValueLbl);
        if not ItemAttributeValue.FindFirst() then
            exit(false);

        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", ItemNo);
        ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttribute.ID);
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", ItemAttributeValue.ID);
        exit(ItemAttributeValueMapping.FindFirst());
    end;

    procedure IsOnDemandSalesLine(SalesLine: Record "Sales Line"): Boolean
    begin
        if SalesLine.IsTemporary() then
            exit(false);

        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            exit(false);

        if SalesLine.Type <> SalesLine.Type::Item then
            exit(false);

        if SalesLine."No." = '' then
            exit(false);

        if SalesLine."Outstanding Quantity" <= 0 then
            exit(false);

        exit(IsOnDemandItem(SalesLine."No."));
    end;

    procedure SalesLineNeedsOnDemandAssignment(SalesLine: Record "Sales Line"): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        if not IsOnDemandSalesLine(SalesLine) then
            exit(false);

        if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit(false);

        if SalesHeader.Status = SalesHeader.Status::Released then
            exit(false);

        exit(not HasReservation(SalesLine));
    end;

    procedure HasReservation(SalesLine: Record "Sales Line"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", Database::"Sales Line");
        ReservationEntry.SetRange("Source Subtype", 1);
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        exit(ReservationEntry.FindFirst());
    end;

    procedure GetPurchaseStatusText(SalesLine: Record "Sales Line"): Text[50]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        if (SalesLine."CXW Purchase Order No." = '') or (SalesLine."CXW Purchase Line No." = 0) then
            exit('');

        if not PurchaseLine.Get(PurchaseLine."Document Type"::Order, SalesLine."CXW Purchase Order No.", SalesLine."CXW Purchase Line No.") then
            exit(PurchaseLineMissingLbl);

        if PurchaseLine."Quantity Received" >= PurchaseLine.Quantity then
            exit(ReceivedLbl);

        if PurchaseLine."Quantity Received" > 0 then
            exit(PartiallyReceivedLbl);

        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.") then
            exit(PurchaseOrderMissingLbl);

        case PurchaseHeader.Status of
            PurchaseHeader.Status::Released:
                exit(ReleasedLbl);
            else
                exit(OpenLbl);
        end;
    end;

    procedure LookupPurchaseLineForSalesLine(SalesLine: Record "Sales Line"; var PurchaseLine: Record "Purchase Line"): Boolean
    var
        PurchaseLineLookup: Page "CXW On Demand Purch. Lookup";
        PurchaseLineFilter: Record "Purchase Line";
    begin
        PurchaseLineFilter.SetRange("Document Type", PurchaseLineFilter."Document Type"::Order);
        PurchaseLineFilter.SetRange(Type, PurchaseLineFilter.Type::Item);
        PurchaseLineFilter.SetRange("No.", SalesLine."No.");
        PurchaseLineFilter.SetFilter("Outstanding Quantity", '>0');

        PurchaseLineLookup.LookupMode(true);
        PurchaseLineLookup.SetTableView(PurchaseLineFilter);
        if PurchaseLineLookup.RunModal() <> Action::LookupOK then
            exit(false);

        PurchaseLineLookup.GetRecord(PurchaseLine);
        exit(true);
    end;

    procedure LinkSalesLineToPurchaseLine(var SalesLine: Record "Sales Line"; var PurchaseLine: Record "Purchase Line")
    begin
        TestSalesLineForLinking(SalesLine);
        TestPurchaseLineForLinking(PurchaseLine);

        if SalesLine."No." <> PurchaseLine."No." then
            Error(ItemMismatchErr, SalesLine."Document No.", SalesLine."Line No.", SalesLine."No.", PurchaseLine."Document No.", PurchaseLine."Line No.", PurchaseLine."No.");

        if (SalesLine."CXW Purchase Order No." = PurchaseLine."Document No.") and
           (SalesLine."CXW Purchase Line No." = PurchaseLine."Line No.")
        then
            exit;

        if (SalesLine."CXW Purchase Order No." <> '') and (SalesLine."CXW Purchase Line No." <> 0) then
            ClearPurchaseLinkInternal(SalesLine, true);

        if (PurchaseLine."CXW Sales Order No." <> '') and (PurchaseLine."CXW Sales Line No." <> 0) then
            ClearSalesLinkInternal(PurchaseLine, true);

        SalesLine."CXW Purchase Order No." := PurchaseLine."Document No.";
        SalesLine."CXW Purchase Line No." := PurchaseLine."Line No.";
        SalesLine.Modify(true);

        PurchaseLine."CXW Sales Order No." := SalesLine."Document No.";
        PurchaseLine."CXW Sales Line No." := SalesLine."Line No.";
        PurchaseLine.Modify(true);
    end;

    procedure ResetSalesLineLink(var SalesLine: Record "Sales Line")
    begin
        ClearPurchaseLinkInternal(SalesLine, true);
    end;

    procedure CreatePurchaseOrderForSalesLines(var TempSalesLines: Record "Sales Line" temporary; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if VendorNo = '' then
            Error(VendorRequiredErr);

        if not TempSalesLines.FindSet() then
            Error(NoSalesLinesSelectedErr);

        CreatePurchaseHeader(PurchaseHeader, VendorNo);

        repeat
            CreatePurchaseLineForSalesLine(TempSalesLines, PurchaseHeader);
        until TempSalesLines.Next() = 0;

        exit(PurchaseHeader."No.");
    end;

    procedure ClearLinkedPurchaseForDeletedSalesLine(SalesLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if (SalesLine."CXW Purchase Order No." = '') or (SalesLine."CXW Purchase Line No." = 0) then
            exit;

        if not PurchaseLine.Get(PurchaseLine."Document Type"::Order, SalesLine."CXW Purchase Order No.", SalesLine."CXW Purchase Line No.") then
            exit;

        PurchaseLine."CXW Sales Order No." := '';
        PurchaseLine."CXW Sales Line No." := 0;
        PurchaseLine.Modify(true);
    end;

    procedure ClearLinkedSalesForDeletedPurchaseLine(PurchaseLine: Record "Purchase Line")
    var
        SalesLine: Record "Sales Line";
    begin
        if (PurchaseLine."CXW Sales Order No." = '') or (PurchaseLine."CXW Sales Line No." = 0) then
            exit;

        if not SalesLine.Get(SalesLine."Document Type"::Order, PurchaseLine."CXW Sales Order No.", PurchaseLine."CXW Sales Line No.") then
            exit;

        SalesLine."CXW Purchase Order No." := '';
        SalesLine."CXW Purchase Line No." := 0;
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := '';
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLineForSalesLine(TempSalesLine: Record "Sales Line" temporary; PurchaseHeader: Record "Purchase Header")
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        SalesLine.Get(TempSalesLine."Document Type", TempSalesLine."Document No.", TempSalesLine."Line No.");
        TestSalesLineForLinking(SalesLine);

        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := GetNextPurchaseLineNo(PurchaseHeader);
        PurchaseLine.Insert(true);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate("No.", SalesLine."No.");
        if SalesLine."Location Code" <> '' then
            PurchaseLine.Validate("Location Code", SalesLine."Location Code");
        PurchaseLine.Validate(Quantity, SalesLine."Outstanding Quantity");
        PurchaseLine.Modify(true);

        LinkSalesLineToPurchaseLine(SalesLine, PurchaseLine);
    end;

    local procedure GetNextPurchaseLineNo(PurchaseHeader: Record "Purchase Header"): Integer
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindLast() then
            exit(PurchaseLine."Line No." + 10000);

        exit(10000);
    end;

    local procedure TestSalesLineForLinking(SalesLine: Record "Sales Line")
    begin
        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            Error(SalesOrderOnlyErr);

        if SalesLine.Type <> SalesLine.Type::Item then
            Error(ItemSalesLineOnlyErr);

        if not IsOnDemandItem(SalesLine."No.") then
            Error(NotOnDemandItemErr, SalesLine."No.");
    end;

    local procedure TestPurchaseLineForLinking(PurchaseLine: Record "Purchase Line")
    begin
        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Order then
            Error(PurchaseOrderOnlyErr);

        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            Error(ItemPurchaseLineOnlyErr);
    end;

    local procedure ClearPurchaseLinkInternal(SalesLine: Record "Sales Line"; UpdatePurchaseLine: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        SalesLineToModify: Record "Sales Line";
    begin
        if not SalesLineToModify.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then
            exit;

        if UpdatePurchaseLine and
           (SalesLineToModify."CXW Purchase Order No." <> '') and
           (SalesLineToModify."CXW Purchase Line No." <> 0) and
           PurchaseLine.Get(PurchaseLine."Document Type"::Order, SalesLineToModify."CXW Purchase Order No.", SalesLineToModify."CXW Purchase Line No.")
        then begin
            PurchaseLine."CXW Sales Order No." := '';
            PurchaseLine."CXW Sales Line No." := 0;
            PurchaseLine.Modify(true);
        end;

        if (SalesLineToModify."CXW Purchase Order No." = '') and (SalesLineToModify."CXW Purchase Line No." = 0) then
            exit;

        SalesLineToModify."CXW Purchase Order No." := '';
        SalesLineToModify."CXW Purchase Line No." := 0;
        SalesLineToModify.Modify(true);
    end;

    local procedure ClearSalesLinkInternal(PurchaseLine: Record "Purchase Line"; UpdateSalesLine: Boolean)
    var
        PurchaseLineToModify: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        if not PurchaseLineToModify.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.") then
            exit;

        if UpdateSalesLine and
           (PurchaseLineToModify."CXW Sales Order No." <> '') and
           (PurchaseLineToModify."CXW Sales Line No." <> 0) and
           SalesLine.Get(SalesLine."Document Type"::Order, PurchaseLineToModify."CXW Sales Order No.", PurchaseLineToModify."CXW Sales Line No.")
        then begin
            SalesLine."CXW Purchase Order No." := '';
            SalesLine."CXW Purchase Line No." := 0;
            SalesLine.Modify(true);
        end;

        if (PurchaseLineToModify."CXW Sales Order No." = '') and (PurchaseLineToModify."CXW Sales Line No." = 0) then
            exit;

        PurchaseLineToModify."CXW Sales Order No." := '';
        PurchaseLineToModify."CXW Sales Line No." := 0;
        PurchaseLineToModify.Modify(true);
    end;

    var
        ReplenishmentAttributeNameLbl: Label 'Wiederbeschaffbarkeit', Locked = true;
        ReplenishmentYesValueLbl: Label 'ja', Locked = true;
        PurchaseLineMissingLbl: Label 'Linked purchase line missing';
        PurchaseOrderMissingLbl: Label 'Linked purchase order missing';
        ReceivedLbl: Label 'Received';
        PartiallyReceivedLbl: Label 'Partially Received';
        ReleasedLbl: Label 'Released';
        OpenLbl: Label 'Open';
        VendorRequiredErr: Label 'Please select a vendor before creating a purchase order.';
        NoSalesLinesSelectedErr: Label 'Please select at least one sales line.';
        SalesOrderOnlyErr: Label 'Only sales order lines can be linked.';
        ItemSalesLineOnlyErr: Label 'Only item sales lines can be linked.';
        PurchaseOrderOnlyErr: Label 'Only purchase order lines can be linked.';
        ItemPurchaseLineOnlyErr: Label 'Only item purchase lines can be linked.';
        NotOnDemandItemErr: Label 'Item %1 is not an on-demand item.', Comment = '%1 = item number';
        ItemMismatchErr: Label 'Sales line %1/%2 (%3) cannot be linked to purchase line %4/%5 (%6) because the item numbers differ.', Comment = '%1 = sales order no.; %2 = sales line no.; %3 = sales item no.; %4 = purchase order no.; %5 = purchase line no.; %6 = purchase item no.';
}
