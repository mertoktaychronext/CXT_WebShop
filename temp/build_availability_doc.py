from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(r"C:\VSCODE\CHX.Webshop")
OUT = ROOT / "docs" / "Availability_and_Delivery_Time_Changes_2026-08-24.docx"


def set_font(run, name="Calibri", size=11, bold=False, color=None):
    run.font.name = name
    run._element.rPr.rFonts.set(qn("w:ascii"), name)
    run._element.rPr.rFonts.set(qn("w:hAnsi"), name)
    run.font.size = Pt(size)
    run.font.bold = bold
    if color:
        run.font.color.rgb = RGBColor.from_string(color)


def set_paragraph_format(paragraph, before=0, after=6, line=1.1):
    fmt = paragraph.paragraph_format
    fmt.space_before = Pt(before)
    fmt.space_after = Pt(after)
    fmt.line_spacing = line


def style_doc(doc: Document):
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.right_margin = Inches(1)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)

    normal = doc.styles["Normal"]
    normal.font.name = "Calibri"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
    normal.font.size = Pt(11)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.1

    for style_name, size, color, before, after in [
        ("Heading 1", 16, "2E74B5", 16, 8),
        ("Heading 2", 13, "2E74B5", 12, 6),
        ("Heading 3", 12, "1F4D78", 8, 4),
    ]:
        style = doc.styles[style_name]
        style.font.name = "Calibri"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor.from_string(color)
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.line_spacing = 1.1


def add_title(doc: Document):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    set_paragraph_format(p, before=0, after=3, line=1.0)
    r = p.add_run("Documentation: Availability Change Logging and Delivery Time Logic")
    set_font(r, size=20, bold=False, color="000000")

    p = doc.add_paragraph()
    set_paragraph_format(p, before=0, after=12, line=1.0)
    r = p.add_run("Project: CHX.Webshop\nDate: August 24, 2026")
    set_font(r, size=10, color="555555")


def add_bullet(paragraph, text):
    paragraph.style = "List Bullet"
    set_paragraph_format(paragraph, before=0, after=4, line=1.15)
    run = paragraph.add_run(text)
    set_font(run)


def add_table_borders(table):
    tbl = table._tbl
    tbl_pr = tbl.tblPr
    borders = OxmlElement("w:tblBorders")
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "4")
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), "D9D9D9")
        borders.append(el)
    tbl_pr.append(borders)


def build_table(doc: Document):
    p = doc.add_paragraph("Implemented Components", style="Heading 2")
    set_paragraph_format(p, before=12, after=6)

    table = doc.add_table(rows=1, cols=3)
    table.autofit = False
    widths = [Inches(2.2), Inches(2.1), Inches(2.2)]
    headers = ["Area", "Object", "Purpose"]
    for cell, width, text in zip(table.rows[0].cells, widths, headers):
        cell.width = width
        para = cell.paragraphs[0]
        para.alignment = WD_ALIGN_PARAGRAPH.LEFT
        set_paragraph_format(para, before=0, after=0, line=1.0)
        run = para.add_run(text)
        set_font(run, bold=True)
        shd = OxmlElement("w:shd")
        shd.set(qn("w:fill"), "F2F4F7")
        cell._tc.get_or_add_tcPr().append(shd)

    rows = [
        ("Logging table", 'Table 60346 "CXW Availability Change Entry"', "Stores article, variant, location, insert timestamp, export status, and export timestamp."),
        ("List page", 'Page 60347 "CXWAvailabilityChange Entries"', "Provides a non-editable review page for queued availability changes."),
        ("Event handling", 'Codeunit 60348 "CXW Availability Change Mgt"', "Queues changed items from item ledger entries, sales order insert/delete, and selected reservation deletions."),
        ("Availability logic", 'Codeunit 60349 "CXW Availability Calculation"', "Calculates article availability in base quantities and delivery date / day output."),
        ("Test action", 'PageExtension 60331 "CXW Item Card"', "Adds an Item Card action to calculate and display delivery date for manual verification."),
        ("Input dialog", 'Page 60348 "CXW Availability Check Dialog"', "Collects country, zone, and bin values for the Item Card test action."),
        ("Permissions", 'PermissionSet 60301 "CXW Workshop All"', "Grants access to the new table, pages, codeunits, and supporting standard records."),
    ]
    for area, obj, purpose in rows:
        cells = table.add_row().cells
        for idx, text in enumerate((area, obj, purpose)):
            cells[idx].width = widths[idx]
            para = cells[idx].paragraphs[0]
            set_paragraph_format(para, before=0, after=0, line=1.0)
            run = para.add_run(text)
            set_font(run)

    add_table_borders(table)


def main():
    doc = Document()
    style_doc(doc)
    add_title(doc)

    p = doc.add_paragraph("Scope", style="Heading 1")
    set_paragraph_format(p, before=0, after=8)
    p = doc.add_paragraph()
    set_paragraph_format(p)
    r = p.add_run(
        "This document summarizes the implementation work completed on August 24, 2026 for availability change tracking, article availability calculation, delivery-time calculation, and manual validation tooling in CHX.Webshop."
    )
    set_font(r)

    p = doc.add_paragraph("Summary of Changes", style="Heading 1")
    set_paragraph_format(p, before=16, after=8)
    bullets = [
        "Created a dedicated entry table to queue articles whose webshop availability must be recalculated or exported.",
        "Added a list page for reviewing logged availability changes.",
        "Implemented event subscribers for physical stock movements, sales order insertions and deletions, and relevant reservation deletions.",
        "Added a central availability calculation codeunit that works in base quantities for stock, purchase demand, sales demand, and transfer demand.",
        "Extended the same codeunit with delivery-date logic based on setup values, replenishment eligibility, and additional delivery times on item, country/region, zone, and bin.",
        "Added a manual test action on the Item Card so the delivery date can be calculated and displayed for business validation.",
        "Updated the workshop permission set with all required custom and standard object permissions.",
    ]
    for text in bullets:
        add_bullet(doc.add_paragraph(), text)

    build_table(doc)

    p = doc.add_paragraph("Availability Change Entry", style="Heading 2")
    set_paragraph_format(p, before=12, after=6)
    for text in [
        'Table 60346 "CXW Availability Change Entry" was introduced as a lightweight queue table.',
        'The table contains the fields "CXW Entry No.", "CXW Item No.", "CXW Variant Code", "CXW Location Code", "CXW Inserted At", "CXW Exported", and "CXW Exported At".',
        'The entry number is auto-incremented and the inserted timestamp is assigned automatically in the OnInsert trigger.',
        "A list page was created so users can inspect logged entries without modifying them manually.",
    ]:
        p = doc.add_paragraph()
        set_paragraph_format(p)
        set_font(p.add_run(text))

    p = doc.add_paragraph("Event-Based Logging", style="Heading 2")
    set_paragraph_format(p, before=12, after=6)
    event_bullets = [
        "Item Ledger Entry OnAfterInsertEvent: queues changes for physical stock movements in the configured webshop location.",
        "Sales Line OnAfterInsertEvent: queues item changes for newly created sales order lines in the webshop location.",
        "Sales Line OnAfterDeleteEvent: queues item changes when sales order lines are removed.",
        "Reservation Entry OnAfterDeleteEvent: queues changes only when the deleted reservation is tied to an open sales order line and therefore relevant for availability.",
        "A de-duplication check prevents duplicate non-exported queue entries for the same item, variant, and location.",
        'The webshop location is read from Setup Values table 50116 using Setup Code "AVAILIBILITY" and Category Code "WEBSHOP", with fallback to "HL".',
    ]
    for text in event_bullets:
        add_bullet(doc.add_paragraph(), text)

    p = doc.add_paragraph("Availability Calculation", style="Heading 2")
    set_paragraph_format(p, before=12, after=6)
    calc_text = [
        "The central public function is GetArticleAvailability(ItemNo).",
        "It calculates availability in base quantities with the following formula:",
        "Availability = inventory in location HL + open purchase quantity - open sales quantity + inbound transfer quantity - outbound transfer quantity.",
        "Open purchase quantity is counted only when the article is replenishable and when either the expected receipt date or the promised receipt date is today or in the future.",
        'Replenishability is determined from the standard item attribute structure using attribute name "Wiederbeschaffbarkeit" and value "ja".',
        'Transfers are evaluated as open quantity in base from HL to W and from W to HL, where HL is the configured webshop location and W is the current transfer counterpart used in the implementation.',
    ]
    for text in calc_text:
        p = doc.add_paragraph()
        set_paragraph_format(p)
        set_font(p.add_run(text))

    p = doc.add_paragraph("Delivery Time Logic", style="Heading 2")
    set_paragraph_format(p, before=12, after=6)
    delivery_bullets = [
        "If availability is greater than zero, the base delivery formula is read from Setup Values table 50116 with Category Code STOCK.",
        "If availability is zero or below and the article is replenishable, the system first checks Item.CXB Additional Delivery Time.",
        "If no item-specific delivery formula is available, the base delivery formula is read from Setup Values table 50116 with Category Code DEMAND.",
        "If availability is zero or below and the article is not replenishable, the article is treated as not deliverable.",
        "Country/region additional delivery time is always added when a country/region code is supplied.",
        "When stock is available, bin additional delivery time is applied first if a bin was entered; otherwise zone additional delivery time is applied.",
        "When a bin is provided, zone time is intentionally not evaluated.",
    ]
    for text in delivery_bullets:
        add_bullet(doc.add_paragraph(), text)

    p = doc.add_paragraph("Manual Validation on Item Card", style="Heading 2")
    set_paragraph_format(p, before=12, after=6)
    for text in [
        'A new action "Check Availability Date" was added to the Item Card.',
        "The action opens a standard dialog where users can provide Country/Region Code, Zone Code, and Bin Code.",
        "After confirmation, the action calculates the current availability and the resulting delivery date, then displays the result in a message for quick manual validation.",
        "If the article is not deliverable according to the implemented rules, the message explicitly reports that state.",
    ]:
        p = doc.add_paragraph()
        set_paragraph_format(p)
        set_font(p.add_run(text))

    p = doc.add_paragraph("Technical Notes and Follow-Up", style="Heading 2")
    set_paragraph_format(p, before=12, after=6)
    notes = [
        "The setup-value access currently uses RecordRef against table 50116 so the logic can resolve category-based values dynamically.",
        "The current implementation falls back to HL if the webshop location cannot be resolved from setup values.",
        "The current transfer counterpart used in the availability calculation is location code W.",
        "The changes were implemented without a local AL compile run in this session, so a first compile and in-client validation remain recommended.",
    ]
    for text in notes:
        add_bullet(doc.add_paragraph(), text)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
