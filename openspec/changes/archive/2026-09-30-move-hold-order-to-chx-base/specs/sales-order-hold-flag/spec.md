## REMOVED Requirements

### Requirement: Sales header has a hold order flag
**Reason**: The hold order flag belongs to the general Chronext base functionality, not to the webshop extension.
**Migration**: The flag is provided by CHX.Base as field "CXB Hold Order" on "Sales Header" with the same behavior (spec `sales-order-hold-flag` in the CHX.Base repository). Values of "CXW Hold Order" are not migrated.

### Requirement: Hold order flag is visible on the sales order
**Reason**: Moved to CHX.Base together with the field.
**Migration**: CHX.Base shows "Hold Order" on the page "Sales Order" (PageExtension "CXB Sales Order Ext."). PageExtension 60334 "CXW Sales Order" in CHX.Webshop keeps only the action "On Demand Lines".

### Requirement: Hold order flag can only be changed on open orders
**Reason**: Moved to CHX.Base together with the field.
**Migration**: The status check lives in the `OnValidate` trigger of "CXB Hold Order" in CHX.Base, unchanged in behavior.

### Requirement: Hold order flag is visible and filterable in the sales order list
**Reason**: Moved to CHX.Base together with the field.
**Migration**: CHX.Base shows the column on the page "Sales Order List" (PageExtension "CXB Sales Order List Ext."). PageExtension 60337 "CXW Sales Order List" is deleted from CHX.Webshop.

### Requirement: Hold order flag does not block any process
**Reason**: Moved to CHX.Base together with the field.
**Migration**: The same requirement applies to "CXB Hold Order" in CHX.Base.
