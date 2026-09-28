enumextension 60300 "CXW Data Export Statuses" extends "Data Export Statuses"
{
    // Sales price entries wait in this status instead of "Waiting to Process", because ChronextBC's
    // "Data Export Mgt." picks up every "Waiting to Process" entry regardless of its destination code.
    value(60300; "CXW Pending")
    {
        Caption = 'Pending (Sales Price)';
    }
}
