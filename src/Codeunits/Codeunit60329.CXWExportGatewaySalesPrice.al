codeunit 60329 "CXW Export Gateway Sales Price"
{
    [TryFunction]
    procedure WriteBackAndArchive(SalesPriceChecking: Record "CXW Sales Price Checking"; var SalesPrice: Record "Sales Price")
    begin
        if not SalesPrice.Get(
             SalesPriceChecking."CXW Item No.", SalesPrice."Sales Type"::"All Customers", '',
             SalesPriceChecking."CXW Starting Date", SalesPriceChecking."CXW Currency Code",
             '', '', 0)
        then begin
            SalesPrice.Init();
            SalesPrice."Item No." := SalesPriceChecking."CXW Item No.";
            SalesPrice.Validate("Sales Type", SalesPrice."Sales Type"::"All Customers");
            SalesPrice."Sales Code" := '';
            SalesPrice."Starting Date" := SalesPriceChecking."CXW Starting Date";
            SalesPrice."Variant Code" := '';
            SalesPrice."Unit of Measure Code" := '';
            SalesPrice."Minimum Quantity" := 0;
            UpdateSalesPriceFields(SalesPrice, SalesPriceChecking);
            SalesPrice.Insert(true);
        end else begin
            UpdateSalesPriceFields(SalesPrice, SalesPriceChecking);
            SalesPrice.Modify(true);
        end;

        ArchiveCheckingLine(SalesPriceChecking);
    end;

    local procedure UpdateSalesPriceFields(var vSalesPrice: Record "Sales Price"; pSalesPriceChecking: Record "CXW Sales Price Checking")
    begin
        vSalesPrice.Validate("Currency Code", pSalesPriceChecking."CXW Currency Code");
        vSalesPrice.Validate("Unit Price", pSalesPriceChecking."CXW Stock Price");
        vSalesPrice."CXW Strike-Price incl. VAT" := pSalesPriceChecking."CXW Strike Price";
        vSalesPrice."CXW Rec. Retail Price incl VAT" := pSalesPriceChecking."CXW Recom. Retail Price";
        vSalesPrice."CXW Reason Code" := pSalesPriceChecking."CXW Reason Code";
        vSalesPrice."CXW Comment" := pSalesPriceChecking."CXW Comment";
        vSalesPrice."CXW Remark" := pSalesPriceChecking."CXW Remark";
    end;

    local procedure ArchiveCheckingLine(pSalesPriceChecking: Record "CXW Sales Price Checking")
    var
        l_recSalesPriceArchive: Record "CXW Sales Price Archive";
        l_intNextVersionNo: Integer;
    begin
        l_recSalesPriceArchive.Reset();
        l_recSalesPriceArchive.LockTable();
        l_recSalesPriceArchive.SetRange("CXW Item No.", pSalesPriceChecking."CXW Item No.");
        l_recSalesPriceArchive.SetRange("CXW Currency Code", pSalesPriceChecking."CXW Currency Code");
        if l_recSalesPriceArchive.FindLast() then
            l_intNextVersionNo := l_recSalesPriceArchive."CXW Version No." + 1
        else
            l_intNextVersionNo := 1;

        l_recSalesPriceArchive.Init();
        l_recSalesPriceArchive.TransferFields(pSalesPriceChecking, true);
        l_recSalesPriceArchive."CXW Version No." := l_intNextVersionNo;
        l_recSalesPriceArchive.Insert(true);
    end;

    procedure CreateExternalInterfaceFile(SalesPrice: Record "Sales Price"): Boolean
    var
        OutboundFile: Record "CXW Sales Price Outbound File";
        RecRef: RecordRef;
        FldRef: FieldRef;
        JsonObj: JsonObject;
        JsonText: Text;
        OutStr: OutStream;
        Index: Integer;
    begin
        RecRef.GetTable(SalesPrice);
        for Index := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(Index);
            AddFieldToJson(JsonObj, FldRef.Name, FldRef.Value);
        end;
        JsonObj.WriteTo(JsonText);

        OutboundFile.Init();
        OutboundFile."CXW Status" := OutboundFile."CXW Status"::New;
        OutboundFile."CXW Filename" :=
            CopyStr(
                StrSubstNo('SalesPrice_%1_%2.json', SalesPrice."Item No.", SalesPrice."Currency Code"),
                1, MaxStrLen(OutboundFile."CXW Filename"));
        OutboundFile."CXW TargetFile".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(JsonText);
        OutboundFile.Insert(true);

        exit(SendToApiInterface(OutboundFile, JsonText));
    end;

    local procedure SendToApiInterface(var vOutboundFile: Record "CXW Sales Price Outbound File"; pJsonText: Text): Boolean
    var
        GenSPSetup: Record "CXW General Sales Price Setup";
        ApiInterfaceSetup: Record "CXW API Interface Setup";
        Base64Convert: Codeunit "Base64 Convert";
        HttpClientObj: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContentObj: HttpContent;
        HttpHeadersObj: HttpHeaders;
        RequestLogText: Text;
        ResponseText: Text;
        FormattedErrorTxt: Text;
        SendOk: Boolean;
    begin
        if not GenSPSetup.Get() then
            exit(false);
        if not GenSPSetup."CXW Price Export Active" then
            exit(false);
        if GenSPSetup."CXW API Interface Code" = '' then
            exit(false);

        if not ApiInterfaceSetup.Get(GenSPSetup."CXW API Interface Code") then
            Error(ApiInterfaceNotFoundErr, GenSPSetup."CXW API Interface Code");
        ApiInterfaceSetup.TestField("CXW Active", true);
        ApiInterfaceSetup.TestField("CXW Source Table No.", Database::"Sales Price");
        ApiInterfaceSetup.TestField("CXW Endpoint URL");

        HttpContentObj.WriteFrom(pJsonText);
        HttpContentObj.GetHeaders(HttpHeadersObj);
        HttpHeadersObj.Remove('Content-Type');
        HttpHeadersObj.Add('Content-Type', 'application/json');

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(ApiInterfaceSetup."CXW Endpoint URL");
        HttpRequest.Content := HttpContentObj;

        case ApiInterfaceSetup."CXW Auth Type" of
            ApiInterfaceSetup."CXW Auth Type"::ApiKeyHeader:
                begin
                    HttpRequest.GetHeaders(HttpHeadersObj);
                    HttpHeadersObj.Add('Authorization', ApiInterfaceSetup.GetApiKey());
                end;
            ApiInterfaceSetup."CXW Auth Type"::BasicAuth:
                begin
                    HttpRequest.GetHeaders(HttpHeadersObj);
                    HttpHeadersObj.Add('Authorization', 'Basic ' + Base64Convert.ToBase64(ApiInterfaceSetup.GetApiKey()));
                end;
        end;

        RequestLogText := BuildRedactedRequestText('POST', ApiInterfaceSetup."CXW Endpoint URL", ApiInterfaceSetup."CXW Auth Type", pJsonText);

        HttpClientObj.Timeout := 30000;
        SendOk := HttpClientObj.Send(HttpRequest, HttpResponse);

        if SendOk and HttpResponse.IsSuccessStatusCode() then begin
            HttpResponse.Content().ReadAs(ResponseText);
            LogHttpCall(vOutboundFile, ApiInterfaceSetup."CXW Endpoint URL", true, HttpResponse.HttpStatusCode(), '', RequestLogText, ResponseText);
            vOutboundFile."CXW Status" := vOutboundFile."CXW Status"::Processed;
            vOutboundFile."CXW Response Message" := '';
            vOutboundFile.Modify();
            exit(true);
        end;

        if SendOk then begin
            HttpResponse.Content().ReadAs(ResponseText);
            FormattedErrorTxt := StrSubstNo('HTTP %1: %2', HttpResponse.HttpStatusCode(), ResponseText);
            LogHttpCall(vOutboundFile, ApiInterfaceSetup."CXW Endpoint URL", false, HttpResponse.HttpStatusCode(), FormattedErrorTxt, RequestLogText, ResponseText);
            ResponseText := FormattedErrorTxt;
        end else begin
            LogHttpCall(vOutboundFile, ApiInterfaceSetup."CXW Endpoint URL", false, 0, NetworkErrorTxt, RequestLogText, '');
            ResponseText := NetworkErrorTxt;
        end;

        vOutboundFile."CXW Status" := vOutboundFile."CXW Status"::Error;
        vOutboundFile."CXW Response Message" := CopyStr(ResponseText, 1, MaxStrLen(vOutboundFile."CXW Response Message"));
        vOutboundFile.Modify();
        exit(false);
    end;

    local procedure BuildRedactedRequestText(pMethod: Text; pUrl: Text; pAuthType: Enum "CXW API Auth Type"; pJsonBody: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        RequestText: Text;
    begin
        RequestText := pMethod + ' ' + pUrl + TypeHelper.LFSeparator() + 'Content-Type: application/json';
        if pAuthType <> pAuthType::None then
            RequestText += TypeHelper.LFSeparator() + 'Authorization: ' + AuthRedactedTxt;
        RequestText += TypeHelper.LFSeparator() + TypeHelper.LFSeparator() + pJsonBody;
        exit(RequestText);
    end;

    local procedure LogHttpCall(pOutboundFile: Record "CXW Sales Price Outbound File"; pEndpointUrl: Text; pSuccess: Boolean; pHttpStatusCode: Integer; pErrorMessage: Text; pRequestText: Text; pResponseText: Text)
    var
        HttpCallLog: Record "CXW Http Call Log";
        OutStr: OutStream;
    begin
        HttpCallLog.Init();
        HttpCallLog."CXW Source Table No." := Database::"CXW Sales Price Outbound File";
        HttpCallLog."CXW Source Entry No" := pOutboundFile."CXW Entry No.";
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

    local procedure AddFieldToJson(var vJsonObj: JsonObject; pFieldName: Text; pFieldValue: Variant)
    var
        BoolValue: Boolean;
        IntValue: Integer;
        BigIntValue: BigInteger;
        DecValue: Decimal;
    begin
        case true of
            pFieldValue.IsBoolean():
                begin
                    BoolValue := pFieldValue;
                    vJsonObj.Add(pFieldName, BoolValue);
                end;
            pFieldValue.IsInteger():
                begin
                    IntValue := pFieldValue;
                    vJsonObj.Add(pFieldName, IntValue);
                end;
            pFieldValue.IsBigInteger():
                begin
                    BigIntValue := pFieldValue;
                    vJsonObj.Add(pFieldName, BigIntValue);
                end;
            pFieldValue.IsDecimal():
                begin
                    DecValue := pFieldValue;
                    vJsonObj.Add(pFieldName, DecValue);
                end;
            else
                vJsonObj.Add(pFieldName, Format(pFieldValue, 0, 9));
        end;
    end;

    var
        ApiInterfaceNotFoundErr: Label 'API interface %1 (selected on the general sales price setup) no longer exists.', Comment = '%1 = API interface code';
        AuthRedactedTxt: Label '***redacted***', Locked = true;
        NetworkErrorTxt: Label 'The request could not be sent (network error).';
}
