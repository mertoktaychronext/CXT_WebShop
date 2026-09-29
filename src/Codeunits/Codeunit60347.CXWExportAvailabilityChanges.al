codeunit 60347 "CXW Export Availability Change"
{
    procedure ExportOpenEntries(var ExportedCount: Integer; var FailedCount: Integer)
    var
        AvailabilityChangeEntry: Record "CXW Availability Change Entry";
    begin
        AvailabilityChangeEntry.SetRange("CXW Exported", false);
        ExportSelectedEntries(AvailabilityChangeEntry, ExportedCount, FailedCount);
    end;

    procedure ExportItem(ItemNo: Code[20]; var ExportedCount: Integer; var FailedCount: Integer)
    var
        AvailabilityChangeEntry: Record "CXW Availability Change Entry";
        AvailabilityDeliveryTime: Record "CXW Availability Delivery Time";
        AvailabilityInventoryTime: Record "CXW Availability Inv. Time";
        AvailabilityChangeMgt: Codeunit "CXW Availability Change Mgt";
        CurrentExportedCount: Integer;
        CurrentFailedCount: Integer;
    begin
        AvailabilityChangeMgt.PrepareItemForExport(ItemNo);

        AvailabilityChangeEntry.SetRange("CXW Item No.", ItemNo);
        AvailabilityChangeEntry.SetRange("CXW Exported", false);
        ExportSelectedEntries(AvailabilityChangeEntry, CurrentExportedCount, CurrentFailedCount);
        ExportedCount += CurrentExportedCount;
        FailedCount += CurrentFailedCount;

        Clear(CurrentExportedCount);
        Clear(CurrentFailedCount);
        AvailabilityDeliveryTime.SetRange("CXW Item No.", ItemNo);
        AvailabilityDeliveryTime.SetRange("CXW Exported", false);
        ExportSelectedDeliveryTimes(AvailabilityDeliveryTime, CurrentExportedCount, CurrentFailedCount);
        ExportedCount += CurrentExportedCount;
        FailedCount += CurrentFailedCount;

        Clear(CurrentExportedCount);
        Clear(CurrentFailedCount);
        AvailabilityInventoryTime.SetRange("CXW Item No.", ItemNo);
        AvailabilityInventoryTime.SetRange("CXW Exported", false);
        ExportSelectedInventoryTimes(AvailabilityInventoryTime, CurrentExportedCount, CurrentFailedCount);
        ExportedCount += CurrentExportedCount;
        FailedCount += CurrentFailedCount;
    end;

    procedure ExportSelectedEntries(var AvailabilityChangeEntry: Record "CXW Availability Change Entry"; var ExportedCount: Integer; var FailedCount: Integer)
    var
        AvailabilityChangeMgt: Codeunit "CXW Availability Change Mgt";
        DataExportApiSetup: Record "Data Export API Setup";
    begin
        LoadDataExportApiSetup(AvailabilityExportSetupCodeLbl, DataExportApiSetup);
        AvailabilityChangeEntry.SetRange("CXW Exported", false);
        if not AvailabilityChangeEntry.FindSet() then
            exit;

        repeat
            AvailabilityChangeMgt.RefreshAvailabilityChangeDetails(AvailabilityChangeEntry);
            AvailabilityChangeMgt.RefreshDeliveryTimes(
                AvailabilityChangeEntry."CXW Item No.",
                AvailabilityChangeEntry."CXW Variant Code");
            if ExportEntry(AvailabilityChangeEntry, DataExportApiSetup) then begin
                AvailabilityChangeEntry."CXW Exported" := true;
                AvailabilityChangeEntry."CXW Exported At" := CurrentDateTime;
                AvailabilityChangeEntry.Modify();
                ExportedCount += 1;
            end else
                FailedCount += 1;
        until AvailabilityChangeEntry.Next() = 0;
    end;

    procedure ExportOpenDeliveryTimes(var ExportedCount: Integer; var FailedCount: Integer)
    var
        AvailabilityDeliveryTime: Record "CXW Availability Delivery Time";
    begin
        AvailabilityDeliveryTime.SetRange("CXW Exported", false);
        ExportSelectedDeliveryTimes(AvailabilityDeliveryTime, ExportedCount, FailedCount);
    end;

    procedure ExportSelectedDeliveryTimes(var AvailabilityDeliveryTime: Record "CXW Availability Delivery Time"; var ExportedCount: Integer; var FailedCount: Integer)
    var
        DataExportApiSetup: Record "Data Export API Setup";
    begin
        LoadDataExportApiSetup(DeliveryTimeExportSetupCodeLbl, DataExportApiSetup);
        AvailabilityDeliveryTime.SetRange("CXW Exported", false);
        if not AvailabilityDeliveryTime.FindSet() then
            exit;

        repeat
            if ExportDeliveryTime(AvailabilityDeliveryTime, DataExportApiSetup) then begin
                AvailabilityDeliveryTime."CXW Exported" := true;
                AvailabilityDeliveryTime."CXW Exported At" := CurrentDateTime;
                AvailabilityDeliveryTime.Modify(true);
                ExportedCount += 1;
            end else
                FailedCount += 1;
        until AvailabilityDeliveryTime.Next() = 0;
    end;

    procedure ExportOpenInventoryTimes(var ExportedCount: Integer; var FailedCount: Integer)
    var
        AvailabilityInventoryTime: Record "CXW Availability Inv. Time";
    begin
        AvailabilityInventoryTime.SetRange("CXW Exported", false);
        ExportSelectedInventoryTimes(AvailabilityInventoryTime, ExportedCount, FailedCount);
    end;

    procedure ExportSelectedInventoryTimes(var AvailabilityInventoryTime: Record "CXW Availability Inv. Time"; var ExportedCount: Integer; var FailedCount: Integer)
    var
        DataExportApiSetup: Record "Data Export API Setup";
    begin
        LoadDataExportApiSetup(InventoryTimeExportSetupCodeLbl, DataExportApiSetup);
        AvailabilityInventoryTime.SetRange("CXW Exported", false);
        if not AvailabilityInventoryTime.FindSet() then
            exit;

        repeat
            if ExportInventoryTime(AvailabilityInventoryTime, DataExportApiSetup) then begin
                AvailabilityInventoryTime."CXW Exported" := true;
                AvailabilityInventoryTime."CXW Exported At" := CurrentDateTime;
                AvailabilityInventoryTime.Modify(true);
                ExportedCount += 1;
            end else
                FailedCount += 1;
        until AvailabilityInventoryTime.Next() = 0;
    end;

    local procedure LoadDataExportApiSetup(SetupCode: Code[50]; var DataExportApiSetup: Record "Data Export API Setup")
    begin
        if not DataExportApiSetup.Get(SetupCode) then
            Error(ApiInterfaceNotFoundErr, SetupCode);

        DataExportApiSetup.TestField(Active, true);
        DataExportApiSetup.TestField("API URL");
        DataExportApiSetup.TestField(Method);

        if DataExportApiSetup.AuthorizationType = DataExportApiSetup.AuthorizationType::ApiKey then begin
            DataExportApiSetup.TestField(UserName);
            DataExportApiSetup.TestField(Password);
        end;
    end;

    local procedure ExportDeliveryTime(AvailabilityDeliveryTime: Record "CXW Availability Delivery Time"; DataExportApiSetup: Record "Data Export API Setup"): Boolean
    var
        Base64Convert: Codeunit "Base64 Convert";
        HttpClientObj: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContentObj: HttpContent;
        HttpHeadersObj: HttpHeaders;
        JsonText: Text;
        RequestLogText: Text;
        ResponseText: Text;
        ErrorMessage: Text;
        HttpMethodTxt: Text;
        SendBody: Boolean;
    begin
        BuildDeliveryTimeJson(AvailabilityDeliveryTime, JsonText);

        HttpMethodTxt := UpperCase(DataExportApiSetup.Method);
        SendBody := HttpMethodTxt <> 'GET';
        if SendBody then begin
            HttpContentObj.WriteFrom(JsonText);
            HttpContentObj.GetHeaders(HttpHeadersObj);
            HttpHeadersObj.Remove('Content-Type');
            HttpHeadersObj.Add('Content-Type', 'application/json');
            HttpRequest.Content := HttpContentObj;
        end;

        HttpRequest.Method := HttpMethodTxt;
        HttpRequest.SetRequestUri(DataExportApiSetup."API URL");
        AddAuthenticationHeaders(HttpRequest, DataExportApiSetup, Base64Convert);

        RequestLogText := BuildRedactedRequestText(HttpMethodTxt, DataExportApiSetup."API URL", DataExportApiSetup.AuthorizationType, DataExportApiSetup.UserName, SendBody, JsonText);
        HttpClientObj.Timeout := 30000;
        if not HttpClientObj.Send(HttpRequest, HttpResponse) then begin
            LogDeliveryTimeHttpCall(AvailabilityDeliveryTime, DataExportApiSetup."API URL", false, 0, NetworkErrorTxt, RequestLogText, '');
            exit(false);
        end;

        HttpResponse.Content().ReadAs(ResponseText);
        if HttpResponse.IsSuccessStatusCode() then begin
            LogDeliveryTimeHttpCall(AvailabilityDeliveryTime, DataExportApiSetup."API URL", true, HttpResponse.HttpStatusCode(), '', RequestLogText, ResponseText);
            CreateProcessedDeliveryTimeDataExportEntry(AvailabilityDeliveryTime, JsonText);
            exit(true);
        end;

        ErrorMessage := StrSubstNo(HttpErrorTxt, HttpResponse.HttpStatusCode(), ResponseText);
        LogDeliveryTimeHttpCall(AvailabilityDeliveryTime, DataExportApiSetup."API URL", false, HttpResponse.HttpStatusCode(), ErrorMessage, RequestLogText, ResponseText);
        exit(false);
    end;

    local procedure BuildDeliveryTimeJson(AvailabilityDeliveryTime: Record "CXW Availability Delivery Time"; var JsonText: Text)
    var
        JsonObj: JsonObject;
    begin
        // The UPDDLT endpoint accepts the delivery-time values only.
        JsonObj.Add('itemNo', AvailabilityDeliveryTime."CXW Item No.");
        JsonObj.Add('variantCode', AvailabilityDeliveryTime."CXW Variant Code");
        JsonObj.Add('countryRegionCode', AvailabilityDeliveryTime."CXW Country/Region Code");
        JsonObj.Add('deliveryTime', AvailabilityDeliveryTime."CXW Delivery Days");
        JsonObj.WriteTo(JsonText);
    end;

    local procedure ExportInventoryTime(AvailabilityInventoryTime: Record "CXW Availability Inv. Time"; DataExportApiSetup: Record "Data Export API Setup"): Boolean
    var
        Base64Convert: Codeunit "Base64 Convert";
        HttpClientObj: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContentObj: HttpContent;
        HttpHeadersObj: HttpHeaders;
        JsonText: Text;
        RequestLogText: Text;
        ResponseText: Text;
        ErrorMessage: Text;
        HttpMethodTxt: Text;
        SendBody: Boolean;
    begin
        BuildInventoryTimeJson(AvailabilityInventoryTime, JsonText);

        HttpMethodTxt := UpperCase(DataExportApiSetup.Method);
        SendBody := HttpMethodTxt <> 'GET';
        if SendBody then begin
            HttpContentObj.WriteFrom(JsonText);
            HttpContentObj.GetHeaders(HttpHeadersObj);
            HttpHeadersObj.Remove('Content-Type');
            HttpHeadersObj.Add('Content-Type', 'application/json');
            HttpRequest.Content := HttpContentObj;
        end;

        HttpRequest.Method := HttpMethodTxt;
        HttpRequest.SetRequestUri(DataExportApiSetup."API URL");
        AddAuthenticationHeaders(HttpRequest, DataExportApiSetup, Base64Convert);

        RequestLogText := BuildRedactedRequestText(HttpMethodTxt, DataExportApiSetup."API URL", DataExportApiSetup.AuthorizationType, DataExportApiSetup.UserName, SendBody, JsonText);
        HttpClientObj.Timeout := 30000;
        if not HttpClientObj.Send(HttpRequest, HttpResponse) then begin
            LogInventoryTimeHttpCall(AvailabilityInventoryTime, DataExportApiSetup."API URL", false, 0, NetworkErrorTxt, RequestLogText, '');
            exit(false);
        end;

        HttpResponse.Content().ReadAs(ResponseText);
        if HttpResponse.IsSuccessStatusCode() then begin
            LogInventoryTimeHttpCall(AvailabilityInventoryTime, DataExportApiSetup."API URL", true, HttpResponse.HttpStatusCode(), '', RequestLogText, ResponseText);
            CreateProcessedInventoryTimeDataExportEntry(AvailabilityInventoryTime, JsonText);
            exit(true);
        end;

        ErrorMessage := StrSubstNo(HttpErrorTxt, HttpResponse.HttpStatusCode(), ResponseText);
        LogInventoryTimeHttpCall(AvailabilityInventoryTime, DataExportApiSetup."API URL", false, HttpResponse.HttpStatusCode(), ErrorMessage, RequestLogText, ResponseText);
        exit(false);
    end;

    local procedure BuildInventoryTimeJson(AvailabilityInventoryTime: Record "CXW Availability Inv. Time"; var JsonText: Text)
    var
        JsonObj: JsonObject;
        ProductKey: Code[20];
        VariantKey: Code[20];
    begin
        GetStockKeys(AvailabilityInventoryTime."CXW Item No.", AvailabilityInventoryTime."CXW Variant Code", ProductKey, VariantKey);
        JsonObj.Add('productKey', ProductKey);
        JsonObj.Add('variantKey', VariantKey);
        JsonObj.Add('countryRegionCode', AvailabilityInventoryTime."CXW Country/Region Code");
        JsonObj.Add('channel', StockChannelLbl);
        JsonObj.Add(AvailabilityInventoryTime."CXW Inventory Type", AvailabilityInventoryTime."CXW Delivery Days");
        JsonObj.Add('_type', AvailabilityInventoryTime."CXW Inventory Type");
        JsonObj.WriteTo(JsonText);
    end;

    local procedure ExportEntry(AvailabilityChangeEntry: Record "CXW Availability Change Entry"; DataExportApiSetup: Record "Data Export API Setup"): Boolean
    var
        Base64Convert: Codeunit "Base64 Convert";
        HttpClientObj: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContentObj: HttpContent;
        HttpHeadersObj: HttpHeaders;
        JsonObj: JsonObject;
        JsonText: Text;
        RequestLogText: Text;
        ResponseText: Text;
        ErrorMessage: Text;
        HttpMethodTxt: Text;
        SendBody: Boolean;
        ProductKey: Code[20];
        VariantKey: Code[20];
    begin
        GetStockKeys(AvailabilityChangeEntry."CXW Item No.", AvailabilityChangeEntry."CXW Variant Code", ProductKey, VariantKey);
        JsonObj.Add('productKey', ProductKey);
        JsonObj.Add('variantKey', VariantKey);
        JsonObj.Add('channel', StockChannelLbl);
        JsonObj.Add('amount_full', AvailabilityChangeEntry."CXW Inventory Quantity");
        if AvailabilityChangeEntry."CXW Diff. Taxation Purchase" then
            JsonObj.Add('_type', 'diff')
        else
            JsonObj.Add('_type', 'full');
        JsonObj.WriteTo(JsonText);

        HttpMethodTxt := UpperCase(DataExportApiSetup.Method);
        // The UPDSTOFILE endpoint receives the changed article in the JSON payload, including for DELETE.
        SendBody := HttpMethodTxt <> 'GET';
        if SendBody then begin
            HttpContentObj.WriteFrom(JsonText);
            HttpContentObj.GetHeaders(HttpHeadersObj);
            HttpHeadersObj.Remove('Content-Type');
            HttpHeadersObj.Add('Content-Type', 'application/json');
            HttpRequest.Content := HttpContentObj;
        end;

        HttpRequest.Method := HttpMethodTxt;
        HttpRequest.SetRequestUri(DataExportApiSetup."API URL");
        AddAuthenticationHeaders(HttpRequest, DataExportApiSetup, Base64Convert);

        RequestLogText := BuildRedactedRequestText(HttpMethodTxt, DataExportApiSetup."API URL", DataExportApiSetup.AuthorizationType, DataExportApiSetup.UserName, SendBody, JsonText);
        HttpClientObj.Timeout := 30000;
        if not HttpClientObj.Send(HttpRequest, HttpResponse) then begin
            LogHttpCall(AvailabilityChangeEntry, DataExportApiSetup."API URL", false, 0, NetworkErrorTxt, RequestLogText, '');
            exit(false);
        end;

        HttpResponse.Content().ReadAs(ResponseText);
        if HttpResponse.IsSuccessStatusCode() then begin
            LogHttpCall(AvailabilityChangeEntry, DataExportApiSetup."API URL", true, HttpResponse.HttpStatusCode(), '', RequestLogText, ResponseText);
            CreateProcessedDataExportEntry(AvailabilityChangeEntry, JsonText);
            exit(true);
        end;

        ErrorMessage := StrSubstNo(HttpErrorTxt, HttpResponse.HttpStatusCode(), ResponseText);
        LogHttpCall(AvailabilityChangeEntry, DataExportApiSetup."API URL", false, HttpResponse.HttpStatusCode(), ErrorMessage, RequestLogText, ResponseText);
        exit(false);
    end;

    local procedure CreateProcessedDataExportEntry(AvailabilityChangeEntry: Record "CXW Availability Change Entry"; JsonText: Text)
    var
        DataExportEntry: Record "Data Export Entry";
        ProductKey: Code[20];
        VariantKey: Code[20];
    begin
        GetStockKeys(AvailabilityChangeEntry."CXW Item No.", AvailabilityChangeEntry."CXW Variant Code", ProductKey, VariantKey);
        DataExportEntry.Init();
        DataExportEntry."Payload Format" := DataExportEntry."Payload Format"::JSON;
        DataExportEntry."Destination Code" := AvailabilityExportSetupCodeLbl;
        DataExportEntry."Source Record ID" := AvailabilityChangeEntry.RecordId();
        DataExportEntry.FileName := CopyStr(
            StrSubstNo(
                'productKey=%1&variantKey=%2&itemLedgerEntryNo=%3',
                ProductKey,
                VariantKey,
                AvailabilityChangeEntry."CXW Item Ledger Entry No."),
            1,
            MaxStrLen(DataExportEntry.FileName));
        DataExportEntry.Insert();
        DataExportEntry.SetPayload(JsonText);
        DataExportEntry.Status := DataExportEntry.Status::Processed;
        DataExportEntry."Processed At" := CurrentDateTime;
        DataExportEntry."Attempt Count" := 1;
        DataExportEntry."Last Attempt At" := CurrentDateTime;
        DataExportEntry.Modify(true);
    end;

    local procedure CreateProcessedDeliveryTimeDataExportEntry(AvailabilityDeliveryTime: Record "CXW Availability Delivery Time"; JsonText: Text)
    var
        DataExportEntry: Record "Data Export Entry";
    begin
        DataExportEntry.Init();
        DataExportEntry."Payload Format" := DataExportEntry."Payload Format"::JSON;
        DataExportEntry."Destination Code" := DeliveryTimeExportSetupCodeLbl;
        DataExportEntry."Source Record ID" := AvailabilityDeliveryTime.RecordId();
        DataExportEntry.FileName := CopyStr(
            StrSubstNo(
                'itemNo=%1&variantCode=%2&countryRegionCode=%3',
                AvailabilityDeliveryTime."CXW Item No.",
                AvailabilityDeliveryTime."CXW Variant Code",
                AvailabilityDeliveryTime."CXW Country/Region Code"),
            1,
            MaxStrLen(DataExportEntry.FileName));
        DataExportEntry.Insert();
        DataExportEntry.SetPayload(JsonText);
        DataExportEntry.Status := DataExportEntry.Status::Processed;
        DataExportEntry."Processed At" := CurrentDateTime;
        DataExportEntry."Attempt Count" := 1;
        DataExportEntry."Last Attempt At" := CurrentDateTime;
        DataExportEntry.Modify(true);
    end;

    local procedure CreateProcessedInventoryTimeDataExportEntry(AvailabilityInventoryTime: Record "CXW Availability Inv. Time"; JsonText: Text)
    var
        DataExportEntry: Record "Data Export Entry";
        ProductKey: Code[20];
        VariantKey: Code[20];
    begin
        GetStockKeys(AvailabilityInventoryTime."CXW Item No.", AvailabilityInventoryTime."CXW Variant Code", ProductKey, VariantKey);
        DataExportEntry.Init();
        DataExportEntry."Payload Format" := DataExportEntry."Payload Format"::JSON;
        DataExportEntry."Destination Code" := InventoryTimeExportSetupCodeLbl;
        DataExportEntry."Source Record ID" := AvailabilityInventoryTime.RecordId();
        DataExportEntry.FileName := CopyStr(
            StrSubstNo(
                'productKey=%1&variantKey=%2&countryRegionCode=%3&type=%4',
                ProductKey,
                VariantKey,
                AvailabilityInventoryTime."CXW Country/Region Code",
                AvailabilityInventoryTime."CXW Inventory Type"),
            1,
            MaxStrLen(DataExportEntry.FileName));
        DataExportEntry.Insert();
        DataExportEntry.SetPayload(JsonText);
        DataExportEntry.Status := DataExportEntry.Status::Processed;
        DataExportEntry."Processed At" := CurrentDateTime;
        DataExportEntry."Attempt Count" := 1;
        DataExportEntry."Last Attempt At" := CurrentDateTime;
        DataExportEntry.Modify(true);
    end;

    local procedure GetStockKeys(ItemNo: Code[20]; VariantCode: Code[20]; var ProductKey: Code[20]; var VariantKey: Code[20])
    var
        Item: Record Item;
    begin
        ProductKey := ItemNo;
        if VariantCode = '' then
            VariantKey := ItemNo
        else
            VariantKey := VariantCode;

        if not Item.Get(ItemNo) then
            exit;

        if Item."Old Item No." <> '' then
            ProductKey := Item."Old Item No.";
        if Item."Old Variant Code" <> '' then
            VariantKey := Item."Old Variant Code";
    end;

    local procedure AddAuthenticationHeaders(var HttpRequest: HttpRequestMessage; DataExportApiSetup: Record "Data Export API Setup"; Base64Convert: Codeunit "Base64 Convert")
    var
        HttpHeadersObj: HttpHeaders;
    begin
        case DataExportApiSetup.AuthorizationType of
            DataExportApiSetup.AuthorizationType::None:
                exit;
            DataExportApiSetup.AuthorizationType::ApiKey:
                begin
                    HttpRequest.GetHeaders(HttpHeadersObj);
                    HttpHeadersObj.Add(DataExportApiSetup.UserName, DataExportApiSetup.Password);
                end;
            DataExportApiSetup.AuthorizationType::Basic:
                begin
                    HttpRequest.GetHeaders(HttpHeadersObj);
                    HttpHeadersObj.Add('Authorization', 'Basic ' + Base64Convert.ToBase64(DataExportApiSetup.UserName + ':' + DataExportApiSetup.Password));
                end;
            DataExportApiSetup.AuthorizationType::"Bearer Token":
                begin
                    HttpRequest.GetHeaders(HttpHeadersObj);
                    HttpHeadersObj.Add('Authorization', 'Bearer ' + DataExportApiSetup.Password);
                end;
            else
                Error(UnsupportedAuthTypeErr, DataExportApiSetup.AuthorizationType);
        end;
    end;

    local procedure BuildRedactedRequestText(HttpMethod: Text; EndpointUrl: Text; AuthorizationType: Enum "Authorization Type"; ApiKeyHeaderName: Text; SendBody: Boolean; JsonText: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        RequestText: Text;
    begin
        RequestText := HttpMethod + ' ' + EndpointUrl;
        if SendBody then
            RequestText += TypeHelper.LFSeparator() + 'Content-Type: application/json';

        case AuthorizationType of
            AuthorizationType::ApiKey:
                RequestText += TypeHelper.LFSeparator() + ApiKeyHeaderName + ': ' + AuthRedactedTxt;
            AuthorizationType::Basic,
            AuthorizationType::"Bearer Token":
                RequestText += TypeHelper.LFSeparator() + 'Authorization: ' + AuthRedactedTxt;
        end;

        if SendBody then
            RequestText += TypeHelper.LFSeparator() + TypeHelper.LFSeparator() + JsonText;
        exit(RequestText);
    end;

    local procedure LogHttpCall(AvailabilityChangeEntry: Record "CXW Availability Change Entry"; EndpointUrl: Text; Success: Boolean; HttpStatusCode: Integer; ErrorMessage: Text; RequestText: Text; ResponseText: Text)
    var
        HttpCallLog: Record "CXW Http Call Log";
        OutStr: OutStream;
    begin
        HttpCallLog.Init();
        HttpCallLog."CXW Source Table No." := Database::"CXW Availability Change Entry";
        HttpCallLog."CXW Source Entry No" := AvailabilityChangeEntry."CXW Entry No.";
        HttpCallLog."CXW Endpoint URL" := CopyStr(EndpointUrl, 1, MaxStrLen(HttpCallLog."CXW Endpoint URL"));
        HttpCallLog."CXW Success" := Success;
        HttpCallLog."CXW HTTP Status Code" := HttpStatusCode;
        HttpCallLog."CXW Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(HttpCallLog."CXW Error Message"));
        HttpCallLog."CXW Request".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(RequestText);
        HttpCallLog."CXW Response".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ResponseText);
        HttpCallLog.Insert(true);
    end;

    local procedure LogDeliveryTimeHttpCall(AvailabilityDeliveryTime: Record "CXW Availability Delivery Time"; EndpointUrl: Text; Success: Boolean; HttpStatusCode: Integer; ErrorMessage: Text; RequestText: Text; ResponseText: Text)
    var
        HttpCallLog: Record "CXW Http Call Log";
        OutStr: OutStream;
    begin
        HttpCallLog.Init();
        HttpCallLog."CXW Source Table No." := Database::"CXW Availability Delivery Time";
        HttpCallLog."CXW Source Entry No" := 0;
        HttpCallLog."CXW Endpoint URL" := CopyStr(EndpointUrl, 1, MaxStrLen(HttpCallLog."CXW Endpoint URL"));
        HttpCallLog."CXW Success" := Success;
        HttpCallLog."CXW HTTP Status Code" := HttpStatusCode;
        HttpCallLog."CXW Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(HttpCallLog."CXW Error Message"));
        HttpCallLog."CXW Request".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(RequestText);
        HttpCallLog."CXW Response".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ResponseText);
        HttpCallLog.Insert(true);
    end;

    local procedure LogInventoryTimeHttpCall(AvailabilityInventoryTime: Record "CXW Availability Inv. Time"; EndpointUrl: Text; Success: Boolean; HttpStatusCode: Integer; ErrorMessage: Text; RequestText: Text; ResponseText: Text)
    var
        HttpCallLog: Record "CXW Http Call Log";
        OutStr: OutStream;
    begin
        HttpCallLog.Init();
        HttpCallLog."CXW Source Table No." := Database::"CXW Availability Inv. Time";
        HttpCallLog."CXW Source Entry No" := 0;
        HttpCallLog."CXW Endpoint URL" := CopyStr(EndpointUrl, 1, MaxStrLen(HttpCallLog."CXW Endpoint URL"));
        HttpCallLog."CXW Success" := Success;
        HttpCallLog."CXW HTTP Status Code" := HttpStatusCode;
        HttpCallLog."CXW Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(HttpCallLog."CXW Error Message"));
        HttpCallLog."CXW Request".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(RequestText);
        HttpCallLog."CXW Response".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ResponseText);
        HttpCallLog.Insert(true);
    end;

    var
        AvailabilityExportSetupCodeLbl: Label 'UPDSTOFILE', Locked = true;
        DeliveryTimeExportSetupCodeLbl: Label 'UPDDLT', Locked = true;
        InventoryTimeExportSetupCodeLbl: Label 'UPDIN', Locked = true;
        StockChannelLbl: Label 'CXT', Locked = true;
        ApiInterfaceNotFoundErr: Label 'Data export API setup %1 for availability exports does not exist.', Comment = '%1 = data export API setup code';
        UnsupportedAuthTypeErr: Label 'Authentication type %1 is not supported for availability exports.', Comment = '%1 = authentication type';
        HttpErrorTxt: Label 'HTTP %1: %2', Comment = '%1 = HTTP status code, %2 = response text';
        NetworkErrorTxt: Label 'The request could not be sent (network error).';
        AuthRedactedTxt: Label '***redacted***', Locked = true;
}
