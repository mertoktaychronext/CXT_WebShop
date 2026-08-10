table 60301 "CXW Watch Online Approval"
{
    Caption = 'Watch Online Approval';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "CXW Entry No"; Integer)
        {
            Caption = 'Entry No';
            AutoIncrement = true;
            DataClassification = ToBeClassified;
        }
        field(2; "CXW Item No"; Code[20])
        {
            Caption = 'Item No';
            DataClassification = ToBeClassified;
        }
        field(3; "CXW Variant Code"; Code[20])
        {
            Caption = 'Variant Code';
            DataClassification = ToBeClassified;
        }
        field(4; "CXW Inbound Posted date"; Date)
        {
            Caption = 'Inbound Posted Date';
            DataClassification = ToBeClassified;
        }
        field(5; "CXW Posted By"; Code[50])
        {
            Caption = 'Posted By';
            DataClassification = ToBeClassified;
        }
        field(6; "CXW Check Online"; Boolean)
        {
            Caption = 'Check Online';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                if "CXW Check Online" then
                    "CXW First Online Date" := Today;
            end;
        }
        field(7; "CXW First Online Date"; Date)
        {
            Caption = 'First Online Date';
            DataClassification = ToBeClassified;
        }
        field(8; "CXW Remark"; Text[200])
        {
            Caption = 'Remark';
            DataClassification = ToBeClassified;
        }
        field(9; "CXW Posting Time"; Time)
        {
            Caption = 'Posting Time';
            DataClassification = ToBeClassified;
        }
        field(10; "CXW Online Check Time"; Time)
        {
            Caption = 'Online Check Time';
            DataClassification = ToBeClassified;
        }
        field(11; "CXW Serial No."; Code[20])
        {
            Caption = 'Serial No.';
            DataClassification = ToBeClassified;
        }
        field(12; "CXW PO number"; Code[20])
        {
            Caption = 'PO Number';
            DataClassification = ToBeClassified;
        }
        field(13; "CXW URL"; Text[250])
        {
            Caption = 'URL';
            DataClassification = ToBeClassified;
        }
        field(14; "CXW C2C"; Boolean)
        {
            Caption = 'C2C';
            DataClassification = ToBeClassified;
        }
        field(15; "CXW SRid"; Code[50])
        {
            Caption = 'SRid';
            FieldClass = FlowField;
            CalcFormula = lookup("Purchase Header"."Vendor Order No." where("No." = field("CXW PO number")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "CXW Entry No")
        {
            Clustered = true;
        }
    }

    // Hinweis: Die im Quellsystem bereits als C/AL-Blockkommentar {...} deaktivierte Ausgabe ueber
    // Table 5275378 "Ext Interface Outbound File" wurde nicht uebernommen, da dieses Objekt laut Nutzer
    // nicht mehr benoetigt wird.
    //
    // Hinweis: Der Quellcode enthielt zusaetzlich bereits auskommentierte Fehlerauswertung der JSON-Antwort
    // (errors.images / errors.deliveryTime / errors.prices) sowie eine alternative Implementierung ueber
    // Codeunit "HttpRequest" (5105... Bereich) und TempBlob. Beides war im Quellsystem bereits inaktiv und
    // wurde daher nicht in AL uebersetzt (die alten DotNet-Variablentypen existieren in AL ohnehin nicht mehr).
    //
    // Hinweis: Die DotNet-Event-Deklarationen (PropertyChanged/PropertyChanging/ListChanged/AddingNew/CollectionChanged)
    // auf den ehemaligen Newtonsoft-JObject/JArray-Variablen waren leere technische Stubs des alten DotNet-Interops
    // und wurden ersatzlos entfernt, da AL keine DotNet-Variablen mehr unterstuetzt.

    local procedure ReadJSONFile()
    begin
    end;

    procedure CreateJsonObjectCheckOnline(WOA: Record "CXW Watch Online Approval"): Text
    var
        JObject: JsonObject;
        JsonText: Text;
    begin
        JObject.Add('EntryNo', WOA."CXW Entry No");
        JObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure CreateEntryInexternalFile(var WOA: Record "CXW Watch Online Approval")
    var
        ApiInterfaceSetup: Record "CXW API Interface Setup";
        HttpClientObj: HttpClient;
        HttpRequestMsg: HttpRequestMessage;
        HttpResponseMsg: HttpResponseMessage;
        HttpHeadersObj: HttpHeaders;
        ResponseJObject: JsonObject;
        JToken: JsonToken;
        RequestUrl: Text;
        RequestLogText: Text;
        ResponseText: Text;
        EntryNoValue: Text;
        OnlineStatuscode: Code[10];
        HttpStatusCode: Integer;
    begin
        // API-Key und Endpoint liegen in "SL API Interface Setup" (Code 'WOA'), Key in Isolated Storage -
        // kein Klartext-Secret mehr im Quellcode (vorher hartcodierter X-API-KEY, siehe Dev-Abschluss-Finding).
        if not ApiInterfaceSetup.Get('WOA') then
            exit;
        if not ApiInterfaceSetup."CXW Active" then
            exit;
        if ApiInterfaceSetup.GetApiKey() = '' then
            exit;

        RequestUrl := ApiInterfaceSetup."CXW Endpoint URL" + '/' + WOA."CXW Item No" + '/' + WOA."CXW Variant Code" + '/check';
        RequestLogText := BuildRedactedRequestText('GET', RequestUrl);

        HttpRequestMsg.Method := 'GET';
        HttpRequestMsg.SetRequestUri(RequestUrl);
        HttpRequestMsg.GetHeaders(HttpHeadersObj);
        HttpHeadersObj.Add('X-API-KEY', ApiInterfaceSetup.GetApiKey());

        if not HttpClientObj.Send(HttpRequestMsg, HttpResponseMsg) then begin
            LogHttpCall(WOA, RequestUrl, false, 0, NoResponseReceivedErr, RequestLogText, '');
            LogHttpCallFailureTelemetry(WOA, RequestUrl, 0);
            exit;
        end;

        HttpStatusCode := HttpResponseMsg.HttpStatusCode();
        HttpResponseMsg.Content().ReadAs(ResponseText);

        if not HttpResponseMsg.IsSuccessStatusCode() then begin
            LogHttpCall(WOA, RequestUrl, false, HttpStatusCode, StrSubstNo(NonSuccessStatusErr, HttpStatusCode), RequestLogText, ResponseText);
            LogHttpCallFailureTelemetry(WOA, RequestUrl, HttpStatusCode);
            exit;
        end;

        LogHttpCall(WOA, RequestUrl, true, HttpStatusCode, '', RequestLogText, ResponseText);

        ResponseJObject.ReadFrom(ResponseText);

        if ResponseJObject.Get('EntryNo', JToken) then
            EntryNoValue := JToken.AsValue().AsText();
        if ResponseJObject.Get('shouldBeOnline', JToken) then
            OnlineStatuscode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(OnlineStatuscode));

        if OnlineStatuscode = 'TRUE' then begin
            WOA."CXW Check Online" := true;
            if WOA."CXW First Online Date" = 0D then
                WOA."CXW First Online Date" := Today;
            WOA.Modify();
        end else
            WOA."CXW Remark" := 'Watch is offline';
        WOA.Modify();
    end;

    local procedure BuildRedactedRequestText(pMethod: Text; pUrl: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(pMethod + ' ' + pUrl + TypeHelper.LFSeparator() + 'X-API-KEY: ' + ApiKeyRedactedTxt);
    end;

    local procedure LogHttpCall(pWOA: Record "CXW Watch Online Approval"; pEndpointUrl: Text; pSuccess: Boolean; pHttpStatusCode: Integer; pErrorMessage: Text; pRequestText: Text; pResponseText: Text)
    var
        HttpCallLog: Record "CXW SW Http Call Log";
        OutStr: OutStream;
    begin
        HttpCallLog.Init();
        HttpCallLog."CXW Source Entry No" := pWOA."CXW Entry No";
        HttpCallLog."CXW Endpoint URL" := CopyStr(pEndpointUrl, 1, MaxStrLen(HttpCallLog."CXW Endpoint URL"));
        HttpCallLog."CXW Success" := pSuccess;
        HttpCallLog."CXW HTTP Status Code" := pHttpStatusCode;
        HttpCallLog."CXW Error Message" := CopyStr(pErrorMessage, 1, MaxStrLen(HttpCallLog."CXW Error Message"));
        HttpCallLog."CXW Request".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(pRequestText);
        HttpCallLog."CXW Response".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(pResponseText);
        HttpCallLog.Insert(true);
    end;

    local procedure LogHttpCallFailureTelemetry(pWOA: Record "CXW Watch Online Approval"; pEndpointUrl: Text; pHttpStatusCode: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('Endpoint', pEndpointUrl);
        CustomDimensions.Add('HttpStatusCode', Format(pHttpStatusCode));
        CustomDimensions.Add('WatchOnlineApprovalEntryNo', Format(pWOA."CXW Entry No"));
        Session.LogMessage('SW-0101', HttpCallFailedTelemetryTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    var
        ApiKeyRedactedTxt: Label '***redacted***', Locked = true;
        NoResponseReceivedErr: Label 'No response received (network error).';
        NonSuccessStatusErr: Label 'Non-success HTTP status: %1', Comment = '%1 = HTTP status code';
        HttpCallFailedTelemetryTxt: Label 'SellWatch online-check HTTP call failed', Locked = true;
}
