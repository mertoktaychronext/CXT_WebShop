namespace CHX.Webshop.Test;

using System.Reflection;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// The assignable permission sets of the app must together cover every object of the app.
/// A new table, page, report or codeunit that is not added to a permission set works for the developer
/// (SUPER), but fails for users and in the job queue with "You do not have the following permissions".
///
/// CHX.Webshop has no single "All" permission set: there is one set per module (sales prices, SellWatch,
/// workshop, on demand, realtime inventory) plus two API sets. Every object must therefore be covered by at
/// least one of these sets. Upgrade codeunits are skipped: the system runs them during the
/// upgrade, users never need to execute them. (CodeUnit Metadata has no subtype for install codeunits;
/// the app has none. A new install codeunit must be added to a permission set or excluded here.)
///
/// The tests read the app's objects from AllObj and the permissions from Metadata Permission.
/// No Microsoft test libraries are needed, so they also run in online sandboxes.
/// </summary>
codeunit 50404 "CXW Test Permissions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        AppIdTok: Label '5df32934-5708-418c-ba16-44b30feb51f4', Locked = true;
        // Role IDs = permission set names in upper case.
        SalesPriceAllTok: Label 'CXWCHRONWSALL', Locked = true;
        OnDemandAllTok: Label 'CXW ON DEMAND ALL', Locked = true;
        RealtimeInventoryTok: Label 'CXW REAL. INVENTORY', Locked = true;
        SellWatchAllTok: Label 'CXW SWCHRONWSALL', Locked = true;
        SellWatchApiTok: Label 'CXW SELL WATCH API', Locked = true;
        WorkshopApiTok: Label 'CXW WORKSHOP API', Locked = true;
        WorkshopAllTok: Label 'CXW WORKSHOP ALL', Locked = true;
        WorkshopDeleteTok: Label 'CXW WORKSHOP DELETE', Locked = true;
        MissingObjectTok: Label '%1 %2 (%3)', Locked = true;
        MissingPermissionSetMsg: Label 'Permission set %1 must exist.', Locked = true;
        NotAssignableMsg: Label 'Permission set %1 must be assignable.', Locked = true;
        MissingExecuteMsg: Label 'No permission set of CHX.Webshop has execute permission for: %1', Locked = true;
        MissingTableDataMsg: Label 'No permission set of CHX.Webshop has full table data permission (RIMD) for: %1', Locked = true;

    [Test]
    procedure PermissionSetsExistAndAreAssignable()
    var
        RoleId: Text;
    begin
        // [GIVEN] The installed app
        // [WHEN] Looking up each of its permission sets
        // [THEN] It exists and can be assigned to users
        foreach RoleId in GetRoleIds() do
            CheckPermissionSetIsAssignable(CopyStr(RoleId, 1, 20));
    end;

    [Test]
    procedure EveryObjectIsExecutableWithPermissionSets()
    var
        AllObj: Record AllObj;
        MissingObjects: Text;
    begin
        // [GIVEN] All tables, pages, reports, codeunits, queries and XMLports of the app
        FilterAppObjects(AllObj);
        AllObj.SetFilter("Object Type", '%1|%2|%3|%4|%5|%6',
            AllObj."Object Type"::Table, AllObj."Object Type"::Page, AllObj."Object Type"::Report,
            AllObj."Object Type"::Codeunit, AllObj."Object Type"::Query, AllObj."Object Type"::XMLport);
        // Guard: if the filter on the app finds nothing, the test would pass without checking anything.
        LibraryAssert.RecordIsNotEmpty(AllObj);

        // [WHEN] Checking each object (except upgrade codeunits) against the permission sets
        AllObj.FindSet();
        repeat
            if not IsUpgradeCodeunit(AllObj) then
                if not HasExecutePermission(AllObj."Object Type", AllObj."Object ID") then
                    AddMissingObject(MissingObjects, AllObj);
        until AllObj.Next() = 0;

        // [THEN] Every object has execute permission in at least one permission set
        LibraryAssert.AreEqual('', MissingObjects, StrSubstNo(MissingExecuteMsg, MissingObjects));
    end;

    [Test]
    procedure EveryPersistentTableHasFullTableDataPermission()
    var
        AllObj: Record AllObj;
        MissingObjects: Text;
    begin
        // [GIVEN] All tables of the app that store data (TableType = Temporary is skipped)
        FilterAppObjects(AllObj);
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        if not AllObj.FindSet() then
            exit; // app without own tables

        // [WHEN] Checking each persistent table against the permission sets
        repeat
            if not IsTemporaryTable(AllObj."Object ID") then
                if not HasFullTableDataPermission(AllObj."Object ID") then
                    AddMissingObject(MissingObjects, AllObj);
        until AllObj.Next() = 0;

        // [THEN] Every persistent table has read, insert, modify and delete permission in at least one permission set
        LibraryAssert.AreEqual('', MissingObjects, StrSubstNo(MissingTableDataMsg, MissingObjects));
    end;

    [Test]
    procedure OnlyWorkshopDeleteMayDeleteWorkshopLinesDirectly()
    var
        MetadataPermission: Record "Metadata Permission";
        MetadataPermissionSetRel: Record "Metadata Permission Set Rel.";
    begin
        // Spec workshop-line-delete: Requirement "Löschen nur mit eigenem Berechtigungssatz"
        // [GIVEN] The permission sets "CXW Workshop All" and "CXW Workshop Delete"
        // [WHEN] Reading their delete permission on the workshop line table
        // [THEN] "CXW Workshop All" may only delete indirectly (cascade from the purchase line via the codeunit)
        LibraryAssert.IsTrue(GetWorkshopLinePermission(MetadataPermission, WorkshopAllTok), 'CXW Workshop All must grant permissions on the workshop line.');
        LibraryAssert.AreEqual(MetadataPermission."Delete Permission"::Indirect, MetadataPermission."Delete Permission", 'Delete permission of CXW Workshop All');

        // [THEN] "CXW Workshop Delete" may delete directly and includes "CXW Workshop All"
        LibraryAssert.IsTrue(GetWorkshopLinePermission(MetadataPermission, WorkshopDeleteTok), 'CXW Workshop Delete must grant permissions on the workshop line.');
        LibraryAssert.AreEqual(MetadataPermission."Delete Permission"::Yes, MetadataPermission."Delete Permission", 'Delete permission of CXW Workshop Delete');
        LibraryAssert.IsTrue(
            MetadataPermissionSetRel.Get(GetAppId(), WorkshopDeleteTok, GetAppId(), WorkshopAllTok),
            'CXW Workshop Delete must include CXW Workshop All.');
    end;

    local procedure GetRoleIds() RoleIds: List of [Text]
    begin
        RoleIds.Add(SalesPriceAllTok);
        RoleIds.Add(OnDemandAllTok);
        RoleIds.Add(RealtimeInventoryTok);
        RoleIds.Add(SellWatchAllTok);
        RoleIds.Add(SellWatchApiTok);
        RoleIds.Add(WorkshopApiTok);
        RoleIds.Add(WorkshopAllTok);
        RoleIds.Add(WorkshopDeleteTok);
    end;

    local procedure GetWorkshopLinePermission(var MetadataPermission: Record "Metadata Permission"; RoleId: Text): Boolean
    begin
        MetadataPermission.SetRange("App ID", GetAppId());
        MetadataPermission.SetRange("Role ID", RoleId);
        MetadataPermission.SetRange("Object Type", MetadataPermission."Object Type"::"Table Data");
        MetadataPermission.SetRange("Object ID", Database::"CXW Workshop Line");
        exit(MetadataPermission.FindFirst());
    end;

    local procedure CheckPermissionSetIsAssignable(RoleId: Code[20])
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
    begin
        LibraryAssert.IsTrue(MetadataPermissionSet.Get(GetAppId(), RoleId), StrSubstNo(MissingPermissionSetMsg, RoleId));
        LibraryAssert.IsTrue(MetadataPermissionSet.Assignable, StrSubstNo(NotAssignableMsg, RoleId));
    end;

    local procedure FilterAppObjects(var AllObj: Record AllObj)
    var
        AppModuleInfo: ModuleInfo;
    begin
        NavApp.GetModuleInfo(GetAppId(), AppModuleInfo);
        AllObj.SetRange("App Package ID", AppModuleInfo.PackageId);
    end;

    local procedure IsUpgradeCodeunit(AllObj: Record AllObj): Boolean
    var
        CodeUnitMetadata: Record "CodeUnit Metadata";
    begin
        if AllObj."Object Type" <> AllObj."Object Type"::Codeunit then
            exit(false);
        if not CodeUnitMetadata.Get(AllObj."Object ID") then
            exit(false);
        exit(CodeUnitMetadata.SubType = CodeUnitMetadata.SubType::Upgrade);
    end;

    local procedure HasExecutePermission(ObjectType: Option; ObjectId: Integer): Boolean
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        // AllObj and Metadata Permission use the same option values for these object types.
        FilterPermissions(MetadataPermission, ObjectType, ObjectId);
        MetadataPermission.SetRange("Execute Permission", MetadataPermission."Execute Permission"::Yes);
        exit(not MetadataPermission.IsEmpty());
    end;

    local procedure HasFullTableDataPermission(TableId: Integer): Boolean
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        FilterPermissions(MetadataPermission, MetadataPermission."Object Type"::"Table Data", TableId);
        MetadataPermission.SetRange("Read Permission", MetadataPermission."Read Permission"::Yes);
        MetadataPermission.SetRange("Insert Permission", MetadataPermission."Insert Permission"::Yes);
        MetadataPermission.SetRange("Modify Permission", MetadataPermission."Modify Permission"::Yes);
        MetadataPermission.SetRange("Delete Permission", MetadataPermission."Delete Permission"::Yes);
        exit(not MetadataPermission.IsEmpty());
    end;

    local procedure FilterPermissions(var MetadataPermission: Record "Metadata Permission"; ObjectType: Integer; ObjectId: Integer)
    begin
        MetadataPermission.SetRange("App ID", GetAppId());
        MetadataPermission.SetFilter("Role ID", '%1|%2|%3|%4|%5|%6|%7|%8',
            SalesPriceAllTok, OnDemandAllTok, RealtimeInventoryTok, SellWatchAllTok, SellWatchApiTok, WorkshopApiTok, WorkshopAllTok, WorkshopDeleteTok);
        MetadataPermission.SetRange("Object Type", ObjectType);
        MetadataPermission.SetRange("Object ID", ObjectId);
    end;

    local procedure IsTemporaryTable(TableId: Integer): Boolean
    var
        TableRecordRef: RecordRef;
        IsTemporary: Boolean;
    begin
        TableRecordRef.Open(TableId);
        IsTemporary := TableRecordRef.IsTemporary();
        TableRecordRef.Close();
        exit(IsTemporary);
    end;

    local procedure AddMissingObject(var MissingObjects: Text; AllObj: Record AllObj)
    begin
        if MissingObjects <> '' then
            MissingObjects += ', ';
        MissingObjects += StrSubstNo(MissingObjectTok, AllObj."Object Type", AllObj."Object ID", AllObj."Object Name");
    end;

    local procedure GetAppId() AppId: Guid
    begin
        Evaluate(AppId, AppIdTok);
    end;
}
