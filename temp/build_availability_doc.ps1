$ErrorActionPreference = 'Stop'

$root = 'C:\VSCODE\CHX.Webshop'
$outDir = Join-Path $root 'docs'
$docPath = Join-Path $outDir 'Availability_and_Delivery_Time_Changes_2026-08-24.docx'
$pdfPath = Join-Path $outDir 'Availability_and_Delivery_Time_Changes_2026-08-24.pdf'

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$wdCollapseEnd = 0
$wdStory = 6
$wdMove = 0
$wdFormatDocumentDefault = 16
$wdExportFormatPDF = 17
$wdColorBlue = 12611584
$wdColorGray15 = 14277081
$wdColorBlack = 0

function Set-RangeFont {
    param(
        $Range,
        [string]$Name = 'Calibri',
        [int]$Size = 11,
        [bool]$Bold = $false,
        [int]$Color = 0
    )
    $Range.Font.Name = $Name
    $Range.Font.Size = $Size
    $Range.Font.Bold = [int]$Bold
    $Range.Font.Color = $Color
}

function Add-Paragraph {
    param(
        $Doc,
        [string]$Text,
        [string]$Kind = 'Body',
        [string]$FontName = 'Calibri',
        [int]$FontSize = 11,
        [bool]$Bold = $false,
        [int]$Color = 0
    )
    $range = $Doc.Content
    $range.Collapse($wdCollapseEnd)
    $range.InsertAfter($Text)
    Set-RangeFont -Range $range -Name $FontName -Size $FontSize -Bold $Bold -Color $Color
    switch ($Kind) {
        'Title' {
            $range.ParagraphFormat.SpaceBefore = 0
            $range.ParagraphFormat.SpaceAfter = 3
        }
        'Subtitle' {
            $range.ParagraphFormat.SpaceBefore = 0
            $range.ParagraphFormat.SpaceAfter = 12
        }
        'Heading1' {
            $range.ParagraphFormat.SpaceBefore = 16
            $range.ParagraphFormat.SpaceAfter = 8
        }
        'Heading2' {
            $range.ParagraphFormat.SpaceBefore = 12
            $range.ParagraphFormat.SpaceAfter = 6
        }
        default {
            $range.ParagraphFormat.SpaceBefore = 0
            $range.ParagraphFormat.SpaceAfter = 6
        }
    }
    $range.InsertParagraphAfter() | Out-Null
}

function Add-Bullets {
    param(
        $Doc,
        [string[]]$Items
    )
    foreach ($item in $Items) {
        $range = $Doc.Content
        $range.Collapse($wdCollapseEnd)
        $range.InsertAfter($item)
        Set-RangeFont -Range $range
        $range.ParagraphFormat.SpaceBefore = 0
        $range.ParagraphFormat.SpaceAfter = 4
        $range.ListFormat.ApplyBulletDefault()
        $range.InsertParagraphAfter() | Out-Null
    }
}

function Add-Table {
    param(
        $Doc,
        [object[][]]$Rows
    )
    $range = $Doc.Content
    $range.Collapse($wdCollapseEnd)
    $table = $Doc.Tables.Add($range, $Rows.Count, $Rows[0].Count)
    $table.Rows.Alignment = 0
    $table.Borders.Enable = 1
    $table.Range.Font.Name = 'Calibri'
    $table.Range.Font.Size = 10
    $table.Columns.Item(1).Width = 158
    $table.Columns.Item(2).Width = 155
    $table.Columns.Item(3).Width = 155

    for ($r = 1; $r -le $Rows.Count; $r++) {
        for ($c = 1; $c -le $Rows[$r - 1].Count; $c++) {
            $cellRange = $table.Cell($r, $c).Range
            $cellRange.Text = [string]$Rows[$r - 1][$c - 1]
            $cellRange.ParagraphFormat.SpaceAfter = 0
            if ($r -eq 1) {
                $cellRange.Bold = 1
                $table.Rows.Item(1).Shading.BackgroundPatternColor = $wdColorGray15
            }
        }
    }
    $end = $Doc.Range($table.Range.End, $table.Range.End)
    $end.InsertParagraphAfter() | Out-Null
}

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

try {
    $doc = $word.Documents.Add()

    $section = $doc.Sections.Item(1)
    $section.PageSetup.TopMargin = $word.InchesToPoints(1)
    $section.PageSetup.BottomMargin = $word.InchesToPoints(1)
    $section.PageSetup.LeftMargin = $word.InchesToPoints(1)
    $section.PageSetup.RightMargin = $word.InchesToPoints(1)
    $section.PageSetup.HeaderDistance = $word.InchesToPoints(0.492)
    $section.PageSetup.FooterDistance = $word.InchesToPoints(0.492)

    Add-Paragraph -Doc $doc -Text 'Documentation: Availability Change Logging and Delivery Time Logic' -Kind 'Title' -FontName 'Calibri' -FontSize 20 -Color $wdColorBlack
    Add-Paragraph -Doc $doc -Text "Project: CHX.Webshop`rDate: August 24, 2026" -Kind 'Subtitle' -FontName 'Calibri' -FontSize 10 -Color 10066329

    Add-Paragraph -Doc $doc -Text 'Scope' -Kind 'Heading1' -FontName 'Calibri' -FontSize 16 -Bold $true -Color $wdColorBlue
    Add-Paragraph -Doc $doc -Text 'This document summarizes the implementation work completed on August 24, 2026 for availability change tracking, article availability calculation, delivery-time calculation, and manual validation tooling in CHX.Webshop.'

    Add-Paragraph -Doc $doc -Text 'Summary of Changes' -Kind 'Heading1' -FontName 'Calibri' -FontSize 16 -Bold $true -Color $wdColorBlue
    Add-Bullets -Doc $doc -Items @(
        'Created a dedicated entry table to queue articles whose webshop availability must be recalculated or exported.',
        'Added a list page for reviewing logged availability changes.',
        'Implemented event subscribers for physical stock movements, sales order insertions and deletions, and selected reservation deletions.',
        'Added a central availability calculation codeunit that works in base quantities for stock, purchase demand, sales demand, and transfer demand.',
        'Extended the same codeunit with delivery-date logic based on setup values, replenishment eligibility, and additional delivery times on item, country/region, zone, and bin.',
        'Added a manual test action on the Item Card so the delivery date can be calculated and displayed for business validation.',
        'Updated the workshop permission set with all required custom and standard object permissions.'
    )

    Add-Paragraph -Doc $doc -Text 'Implemented Components' -Kind 'Heading2' -FontName 'Calibri' -FontSize 13 -Bold $true -Color $wdColorBlue
    Add-Table -Doc $doc -Rows @(
        @('Area', 'Object', 'Purpose'),
        @('Logging table', 'Table 60346 "CXW Availability Change Entry"', 'Stores article, variant, location, insert timestamp, export status, and export timestamp.'),
        @('List page', 'Page 60347 "CXWAvailabilityChange Entries"', 'Provides a non-editable review page for queued availability changes.'),
        @('Event handling', 'Codeunit 60348 "CXW Availability Change Mgt"', 'Queues changed items from item ledger entries, sales order insert/delete, and selected reservation deletions.'),
        @('Availability logic', 'Codeunit 60349 "CXW Availability Calculation"', 'Calculates article availability in base quantities and delivery date/day output.'),
        @('Test action', 'PageExtension 60331 "CXW Item Card"', 'Adds an Item Card action to calculate and display the delivery date for manual verification.'),
        @('Input dialog', 'Page 60348 "CXW Availability Check Dialog"', 'Collects country, zone, and bin values for the Item Card test action.'),
        @('Permissions', 'PermissionSet 60301 "CXW Workshop All"', 'Grants access to the new table, pages, codeunits, and supporting standard records.')
    )

    Add-Paragraph -Doc $doc -Text 'Availability Change Entry' -Kind 'Heading2' -FontName 'Calibri' -FontSize 13 -Bold $true -Color $wdColorBlue
    Add-Paragraph -Doc $doc -Text 'Table 60346 "CXW Availability Change Entry" was introduced as a lightweight queue table.'
    Add-Paragraph -Doc $doc -Text 'The table contains the fields "CXW Entry No.", "CXW Item No.", "CXW Variant Code", "CXW Location Code", "CXW Inserted At", "CXW Exported", and "CXW Exported At".'
    Add-Paragraph -Doc $doc -Text 'The entry number is auto-incremented and the inserted timestamp is assigned automatically in the OnInsert trigger.'
    Add-Paragraph -Doc $doc -Text 'A list page was created so users can inspect logged entries without modifying them manually.'

    Add-Paragraph -Doc $doc -Text 'Event-Based Logging' -Kind 'Heading2' -FontName 'Calibri' -FontSize 13 -Bold $true -Color $wdColorBlue
    Add-Bullets -Doc $doc -Items @(
        'Item Ledger Entry OnAfterInsertEvent: queues changes for physical stock movements in the configured webshop location.',
        'Sales Line OnAfterInsertEvent: queues item changes for newly created sales order lines in the webshop location.',
        'Sales Line OnAfterDeleteEvent: queues item changes when sales order lines are removed.',
        'Reservation Entry OnAfterDeleteEvent: queues changes only when the deleted reservation is tied to an open sales order line and therefore relevant for availability.',
        'A de-duplication check prevents duplicate non-exported queue entries for the same item, variant, and location.',
        'The webshop location is read from Setup Values table 50116 using Setup Code "AVAILIBILITY" and Category Code "WEBSHOP", with fallback to "HL".'
    )

    Add-Paragraph -Doc $doc -Text 'Availability Calculation' -Kind 'Heading2' -FontName 'Calibri' -FontSize 13 -Bold $true -Color $wdColorBlue
    Add-Paragraph -Doc $doc -Text 'The central public function is GetArticleAvailability(ItemNo).'
    Add-Paragraph -Doc $doc -Text 'It calculates availability in base quantities with the following formula:'
    Add-Paragraph -Doc $doc -Text 'Availability = inventory in location HL + open purchase quantity - open sales quantity + inbound transfer quantity - outbound transfer quantity.'
    Add-Paragraph -Doc $doc -Text 'Open purchase quantity is counted only when the article is replenishable and when either the expected receipt date or the promised receipt date is today or in the future.'
    Add-Paragraph -Doc $doc -Text 'Replenishability is determined from the standard item attribute structure using attribute name "Wiederbeschaffbarkeit" and value "ja".'
    Add-Paragraph -Doc $doc -Text 'Transfers are evaluated as open quantity in base from HL to W and from W to HL, where HL is the configured webshop location and W is the current transfer counterpart used in the implementation.'

    Add-Paragraph -Doc $doc -Text 'Delivery Time Logic' -Kind 'Heading2' -FontName 'Calibri' -FontSize 13 -Bold $true -Color $wdColorBlue
    Add-Bullets -Doc $doc -Items @(
        'If availability is greater than zero, the base delivery formula is read from Setup Values table 50116 with Category Code STOCK.',
        'If availability is zero or below and the article is replenishable, the system first checks Item.CXB Additional Delivery Time.',
        'If no item-specific delivery formula is available, the base delivery formula is read from Setup Values table 50116 with Category Code DEMAND.',
        'If availability is zero or below and the article is not replenishable, the article is treated as not deliverable.',
        'Country/region additional delivery time is always added when a country/region code is supplied.',
        'When stock is available, bin additional delivery time is applied first if a bin was entered; otherwise zone additional delivery time is applied.',
        'When a bin is provided, zone time is intentionally not evaluated.'
    )

    Add-Paragraph -Doc $doc -Text 'Manual Validation on Item Card' -Kind 'Heading2' -FontName 'Calibri' -FontSize 13 -Bold $true -Color $wdColorBlue
    Add-Paragraph -Doc $doc -Text 'A new action "Check Availability Date" was added to the Item Card.'
    Add-Paragraph -Doc $doc -Text 'The action opens a standard dialog where users can provide Country/Region Code, Zone Code, and Bin Code.'
    Add-Paragraph -Doc $doc -Text 'After confirmation, the action calculates the current availability and the resulting delivery date, then displays the result in a message for quick manual validation.'
    Add-Paragraph -Doc $doc -Text 'If the article is not deliverable according to the implemented rules, the message explicitly reports that state.'

    Add-Paragraph -Doc $doc -Text 'Technical Notes and Follow-Up' -Kind 'Heading2' -FontName 'Calibri' -FontSize 13 -Bold $true -Color $wdColorBlue
    Add-Bullets -Doc $doc -Items @(
        'The setup-value access currently uses RecordRef against table 50116 so the logic can resolve category-based values dynamically.',
        'The current implementation falls back to HL if the webshop location cannot be resolved from setup values.',
        'The current transfer counterpart used in the availability calculation is location code W.',
        'The changes were implemented without a local AL compile run in this session, so a first compile and in-client validation remain recommended.'
    )

    $doc.SaveAs([string]$docPath, [ref]$wdFormatDocumentDefault)
    $doc.ExportAsFixedFormat($pdfPath, $wdExportFormatPDF)
    $doc.Close()
}
finally {
    if ($null -ne $doc) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
    }
    if ($null -ne $word) {
        $word.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    }
}

Write-Output $docPath
