table 51009 "Watch Online Approval"
{
    Caption = 'Watch Online Approval';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No"; Integer)
        {
            Caption = 'Entry No';
            AutoIncrement = true;
            DataClassification = ToBeClassified;
        }
        field(2; "Item No"; Code[20])
        {
            Caption = 'Item No';
            DataClassification = ToBeClassified;
        }
        field(3; "Variant Code"; Code[20])
        {
            Caption = 'Variant Code';
            DataClassification = ToBeClassified;
        }
        field(4; "Inbound Posted date"; Date)
        {
            Caption = 'Inbound Posted Date';
            DataClassification = ToBeClassified;
        }
        field(5; "Posted By"; Code[50])
        {
            Caption = 'Posted By';
            DataClassification = ToBeClassified;
        }
        field(6; "Check Online"; Boolean)
        {
            Caption = 'Check Online';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                // 1:1 aus Quellsystem uebernommen - Modify() innerhalb der OnValidate-Trigger auf dem eigenen Record ist ein
                // C/AL-Altmuster; funktioniert in AL, ist aber als Antipattern zu betrachten (TODO: bei Gelegenheit pruefen/bereinigen).
                if "Check Online" then
                    "First Online Date" := Today;
                Modify();
            end;
        }
        field(7; "First Online Date"; Date)
        {
            Caption = 'First Online Date';
            DataClassification = ToBeClassified;
        }
        field(8; Remark; Text[200])
        {
            Caption = 'Remark';
            DataClassification = ToBeClassified;
        }
        field(9; "Posting Time"; Time)
        {
            Caption = 'Posting Time';
            DataClassification = ToBeClassified;
        }
        field(10; "Online Check Time"; Time)
        {
            Caption = 'Online Check Time';
            DataClassification = ToBeClassified;
        }
        field(11; "Serial No."; Code[20])
        {
            Caption = 'Serial No.';
            DataClassification = ToBeClassified;
        }
        field(12; "PO number"; Code[20])
        {
            Caption = 'PO Number';
            DataClassification = ToBeClassified;
        }
        field(13; URL; Text[250])
        {
            Caption = 'URL';
            DataClassification = ToBeClassified;
        }
        field(14; C2C; Boolean)
        {
            Caption = 'C2C';
            DataClassification = ToBeClassified;
        }
        field(15; SRid; Code[50])
        {
            Caption = 'SRid';
            FieldClass = FlowField;
            CalcFormula = lookup("Purchase Header"."Vendor Order No." where("No." = field("PO number")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No")
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

    procedure CreateJsonObjectCheckOnline(WOA: Record "Watch Online Approval"): Text
    var
        JObject: JsonObject;
        JsonText: Text;
    begin
        JObject.Add('EntryNo', WOA."Entry No");
        JObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure CreateEntryInexternalFile(var WOA: Record "Watch Online Approval")
    var
        ApiInterfaceSetup: Record "SL API Interface Setup";
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
        if not ApiInterfaceSetup.Active then
            exit;
        if ApiInterfaceSetup.GetApiKey() = '' then
            exit;

        RequestUrl := ApiInterfaceSetup."Endpoint URL" + '/' + WOA."Item No" + '/' + WOA."Variant Code" + '/check';
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
            WOA."Check Online" := true;
            if WOA."First Online Date" = 0D then
                WOA."First Online Date" := Today;
            WOA.Modify();
        end else
            WOA.Remark := 'Watch is offline';
        WOA.Modify();
    end;

    local procedure BuildRedactedRequestText(pMethod: Text; pUrl: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(pMethod + ' ' + pUrl + TypeHelper.LFSeparator() + 'X-API-KEY: ' + ApiKeyRedactedTxt);
    end;

    local procedure LogHttpCall(pWOA: Record "Watch Online Approval"; pEndpointUrl: Text; pSuccess: Boolean; pHttpStatusCode: Integer; pErrorMessage: Text; pRequestText: Text; pResponseText: Text)
    var
        HttpCallLog: Record "SW Http Call Log";
        OutStr: OutStream;
    begin
        HttpCallLog.Init();
        HttpCallLog."Source Entry No" := pWOA."Entry No";
        HttpCallLog."Endpoint URL" := CopyStr(pEndpointUrl, 1, MaxStrLen(HttpCallLog."Endpoint URL"));
        HttpCallLog.Success := pSuccess;
        HttpCallLog."HTTP Status Code" := pHttpStatusCode;
        HttpCallLog."Error Message" := CopyStr(pErrorMessage, 1, MaxStrLen(HttpCallLog."Error Message"));
        HttpCallLog.Request.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(pRequestText);
        HttpCallLog.Response.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(pResponseText);
        HttpCallLog.Insert(true);
    end;

    local procedure LogHttpCallFailureTelemetry(pWOA: Record "Watch Online Approval"; pEndpointUrl: Text; pHttpStatusCode: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('Endpoint', pEndpointUrl);
        CustomDimensions.Add('HttpStatusCode', Format(pHttpStatusCode));
        CustomDimensions.Add('WatchOnlineApprovalEntryNo', Format(pWOA."Entry No"));
        Session.LogMessage('SW-0101', HttpCallFailedTelemetryTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    var
        ApiKeyRedactedTxt: Label '***redacted***', Locked = true;
        NoResponseReceivedErr: Label 'No response received (network error).';
        NonSuccessStatusErr: Label 'Non-success HTTP status: %1', Comment = '%1 = HTTP status code';
        HttpCallFailedTelemetryTxt: Label 'SellWatch online-check HTTP call failed', Locked = true;
}
