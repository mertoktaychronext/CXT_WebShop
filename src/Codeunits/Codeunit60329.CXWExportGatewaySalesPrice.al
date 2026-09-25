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
        vSalesPrice."CXW Unit Price (LCY)" := ResolveUnitPriceLCY(pSalesPriceChecking, vSalesPrice."Unit Price");
        vSalesPrice."CXW Strike-Price incl. VAT" := pSalesPriceChecking."CXW Strike Price";
        vSalesPrice."CXW Rec. Retail Price incl VAT" := pSalesPriceChecking."CXW Recom. Retail Price";
        vSalesPrice."CXW Reason Code" := pSalesPriceChecking."CXW Reason Code";
        vSalesPrice."CXW Comment" := pSalesPriceChecking."CXW Comment";
        vSalesPrice."CXW Remark" := pSalesPriceChecking."CXW Remark";
    end;

    local procedure ResolveUnitPriceLCY(pSalesPriceChecking: Record "CXW Sales Price Checking"; pUnitPrice: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        ExchangeRateDate: Date;
        ExchangeRateAmt: Decimal;
    begin
        if pSalesPriceChecking."CXW Currency Code" = '' then
            exit(pUnitPrice);

        if pSalesPriceChecking."CXW Exchange Rate Amount" <> 0 then
            exit(pUnitPrice / pSalesPriceChecking."CXW Exchange Rate Amount");

        CurrExchRate.SetRange("Currency Code", pSalesPriceChecking."CXW Currency Code");
        if not CurrExchRate.FindLast() then
            exit(0);

        CurrExchRate.GetLastestExchangeRate(pSalesPriceChecking."CXW Currency Code", ExchangeRateDate, ExchangeRateAmt);
        if ExchangeRateAmt = 0 then
            exit(0);
        exit(pUnitPrice * ExchangeRateAmt);
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
        l_recSalesPriceArchive.SetRange("CXW Country Code", pSalesPriceChecking."CXW Country Code");
        if l_recSalesPriceArchive.FindLast() then
            l_intNextVersionNo := l_recSalesPriceArchive."CXW Version No." + 1
        else
            l_intNextVersionNo := 1;

        l_recSalesPriceArchive.Init();
        l_recSalesPriceArchive.TransferFields(pSalesPriceChecking, true);
        l_recSalesPriceArchive."CXW Version No." := l_intNextVersionNo;
        l_recSalesPriceArchive.Insert(true);
    end;

    procedure CreateExternalInterfaceFile(SalesPrice: Record "Sales Price"; pCountryCode: Code[10]): Boolean
    var
        DataExportEntry: Record "Data Export Entry";
        RecRef: RecordRef;
        FldRef: FieldRef;
        JsonObj: JsonObject;
        JsonText: Text;
        FileName: Text[250];
        Index: Integer;
        ExportItemNo: Code[20];
    begin
        GetExportItemNo(SalesPrice."Item No.", ExportItemNo);
        RecRef.GetTable(SalesPrice);
        for Index := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(Index);
            if FldRef.Name <> 'Item No.' then
                AddFieldToJson(JsonObj, FldRef.Name, FldRef.Value);
        end;
        JsonObj.Add('Item No.', ExportItemNo);
        // "Sales Price" has no country in its key - the country of the checking line is sent alongside.
        JsonObj.Add('CXW Country Code', pCountryCode);
        JsonObj.WriteTo(JsonText);

        FileName :=
            CopyStr(
                StrSubstNo('SalesPrice_%1_%2_%3.json', ExportItemNo, SalesPrice."Currency Code", pCountryCode),
                1, MaxStrLen(DataExportEntry.FileName));

        exit(SendToApiInterface(JsonText, FileName, SalesPrice.RecordId()));
    end;

    local procedure GetExportItemNo(ItemNo: Code[20]; var ExportItemNo: Code[20])
    var
        Item: Record Item;
    begin
        ExportItemNo := ItemNo;
        if not Item.Get(ItemNo) then
            exit;

        if Item."Old Item No." <> '' then
            ExportItemNo := Item."Old Item No.";
    end;

    local procedure SendToApiInterface(pJsonText: Text; pFileName: Text[250]; pSourceRecordId: RecordId): Boolean
    var
        GenSPSetup: Record "CXW General Sales Price Setup";
        ApiInterfaceSetup: Record "CXW API Interface Setup";
        Base64Convert: Codeunit "Base64 Convert";
        UriObj: Codeunit Uri;
        HttpClientObj: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContentObj: HttpContent;
        HttpHeadersObj: HttpHeaders;
        RequestLogText: Text;
        ResponseText: Text;
        FormattedErrorTxt: Text;
        AuthorizationHeader: Text;
        AmzDate: Text;
        SessionTokenValue: Text;
        ApiKeyValue: Text;
        HttpMethodTxt: Text;
        SoapActionValue: Text;
        DataExportEntryNo: BigInteger;
        SendBody: Boolean;
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

        HttpMethodTxt := Format(ApiInterfaceSetup."CXW Http Method");
        SoapActionValue := SanitizeHeaderText(ApiInterfaceSetup."CXW SOAP Action");

        // GET/DELETE requests carry no request body - many servers reject a body on these methods.
        SendBody :=
            (ApiInterfaceSetup."CXW Http Method" <> ApiInterfaceSetup."CXW Http Method"::GET) and
            (ApiInterfaceSetup."CXW Http Method" <> ApiInterfaceSetup."CXW Http Method"::DELETE);

        if SendBody then begin
            HttpContentObj.WriteFrom(pJsonText);
            HttpContentObj.GetHeaders(HttpHeadersObj);
            HttpHeadersObj.Remove('Content-Type');
            HttpHeadersObj.Add('Content-Type', 'application/json');
            HttpRequest.Content := HttpContentObj;
        end;

        HttpRequest.Method := HttpMethodTxt;
        HttpRequest.SetRequestUri(ApiInterfaceSetup."CXW Endpoint URL");

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
            ApiInterfaceSetup."CXW Auth Type"::AWSSigV4:
                begin
                    UriObj.Init(ApiInterfaceSetup."CXW Endpoint URL");
                    BuildSigV4Headers(
                        ApiInterfaceSetup, HttpMethodTxt, UriObj.GetAbsolutePath(), UriObj.GetHost(), SendBody, pJsonText,
                        AuthorizationHeader, AmzDate);
                    HttpRequest.GetHeaders(HttpHeadersObj);
                    // AWS SigV4's Authorization value (Credential=.../.../.../aws4_request) contains
                    // unquoted slashes, which fail .NET's strict Authorization-header format validation
                    // used by Add() - TryAddWithoutValidation() skips that check.
                    HttpHeadersObj.TryAddWithoutValidation('Authorization', AuthorizationHeader);
                    HttpHeadersObj.Add('X-Amz-Date', AmzDate);
                    SessionTokenValue := SanitizeHeaderText(ApiInterfaceSetup.GetAwsSessionToken());
                    if SessionTokenValue <> '' then
                        HttpHeadersObj.Add('X-Amz-Security-Token', SessionTokenValue);
                    ApiKeyValue := SanitizeHeaderText(ApiInterfaceSetup.GetApiKey());
                    if ApiKeyValue <> '' then
                        HttpHeadersObj.Add('X-API-Key', ApiKeyValue);
                end;
        end;

        if SoapActionValue <> '' then begin
            HttpRequest.GetHeaders(HttpHeadersObj);
            HttpHeadersObj.Add('SOAPAction', SoapActionValue);
        end;

        RequestLogText :=
            BuildRedactedRequestText(
                HttpMethodTxt, ApiInterfaceSetup."CXW Endpoint URL", ApiInterfaceSetup."CXW Auth Type", SessionTokenValue <> '',
                ApiKeyValue <> '', SoapActionValue, SendBody, pJsonText);

        HttpClientObj.Timeout := 30000;
        SendOk := HttpClientObj.Send(HttpRequest, HttpResponse);

        // The Data Export Entry is only created after the call, directly with its final status - an entry
        // left in "Waiting to Process" would be picked up and resent by ChronextBC's "Data Export Mgt.".
        if SendOk and HttpResponse.IsSuccessStatusCode() then begin
            HttpResponse.Content().ReadAs(ResponseText);
            DataExportEntryNo := CreateDataExportEntry(pJsonText, pFileName, pSourceRecordId, true, '');
            LogHttpCall(DataExportEntryNo, ApiInterfaceSetup."CXW Endpoint URL", true, HttpResponse.HttpStatusCode(), '', RequestLogText, ResponseText);
            exit(true);
        end;

        if SendOk then begin
            HttpResponse.Content().ReadAs(ResponseText);
            FormattedErrorTxt := StrSubstNo('HTTP %1: %2', HttpResponse.HttpStatusCode(), ResponseText);
            DataExportEntryNo := CreateDataExportEntry(pJsonText, pFileName, pSourceRecordId, false, FormattedErrorTxt);
            LogHttpCall(DataExportEntryNo, ApiInterfaceSetup."CXW Endpoint URL", false, HttpResponse.HttpStatusCode(), FormattedErrorTxt, RequestLogText, ResponseText);
        end else begin
            DataExportEntryNo := CreateDataExportEntry(pJsonText, pFileName, pSourceRecordId, false, NetworkErrorTxt);
            LogHttpCall(DataExportEntryNo, ApiInterfaceSetup."CXW Endpoint URL", false, 0, NetworkErrorTxt, RequestLogText, '');
        end;

        exit(false);
    end;

    local procedure CreateDataExportEntry(pJsonText: Text; pFileName: Text[250]; pSourceRecordId: RecordId; pSuccess: Boolean; pErrorMessage: Text): BigInteger
    var
        DataExportEntry: Record "Data Export Entry";
    begin
        DataExportEntry.Init();
        DataExportEntry."Destination Code" := SalesPriceDestinationCodeLbl;
        DataExportEntry."Payload Format" := DataExportEntry."Payload Format"::JSON;
        DataExportEntry.FileName := pFileName;
        DataExportEntry."Source Record ID" := pSourceRecordId;
        DataExportEntry.Insert(true);
        DataExportEntry.SetPayload(pJsonText);
        // OnInsert of "Data Export Entry" sets "Created At" and always "Waiting to Process" - overwritten here with the final status.
        if pSuccess then begin
            DataExportEntry.Status := DataExportEntry.Status::Processed;
            DataExportEntry."Processed At" := CurrentDateTime;
        end else begin
            DataExportEntry.Status := DataExportEntry.Status::Error;
            DataExportEntry."Error Message" := CopyStr(pErrorMessage, 1, MaxStrLen(DataExportEntry."Error Message"));
        end;
        DataExportEntry."Attempt Count" := 1;
        DataExportEntry."Last Attempt At" := CurrentDateTime;
        DataExportEntry.Modify(true);
        exit(DataExportEntry."Entry No.");
    end;

    local procedure BuildSigV4Headers(pApiInterfaceSetup: Record "CXW API Interface Setup"; pMethod: Text; pUrlPath: Text; pHost: Text; pHasBody: Boolean; pPayload: Text; var vAuthorizationHeader: Text; var vAmzDate: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        LF: Text;
        UtcDateTime: DateTime;
        DateStamp: Text;
        AccessKeyId: Text;
        Region: Text;
        Service: Text;
        SecretAccessKey: Text;
        SessionToken: Text;
        CanonicalUri: Text;
        CanonicalHeaders: Text;
        SignedHeadersList: Text;
        PayloadHash: Text;
        CanonicalRequest: Text;
        CredentialScope: Text;
        StringToSign: Text;
        SigningKey: Text;
        Signature: Text;
    begin
        LF := TypeHelper.LFSeparator();
        UtcDateTime := TypeHelper.GetCurrUTCDateTime();
        vAmzDate := Format(UtcDateTime, 0, '<Year4><Month,2><Day,2>T<Hours24,2><Minutes,2><Seconds,2>Z');
        DateStamp := CopyStr(vAmzDate, 1, 8);

        AccessKeyId := SanitizeHeaderText(pApiInterfaceSetup."CXW AWS Access Key ID");
        Region := SanitizeHeaderText(pApiInterfaceSetup."CXW AWS Region");
        Service := SanitizeHeaderText(pApiInterfaceSetup."CXW AWS Service");
        SecretAccessKey := SanitizeHeaderText(pApiInterfaceSetup.GetAwsSecretAccessKey());
        SessionToken := SanitizeHeaderText(pApiInterfaceSetup.GetAwsSessionToken());

        if pUrlPath = '' then
            CanonicalUri := '/'
        else
            CanonicalUri := pUrlPath;

        CanonicalHeaders := '';
        SignedHeadersList := '';
        if pHasBody then begin
            CanonicalHeaders += 'content-type:application/json' + LF;
            SignedHeadersList += 'content-type;';
        end;
        CanonicalHeaders += 'host:' + pHost + LF + 'x-amz-date:' + vAmzDate + LF;
        SignedHeadersList += 'host;x-amz-date';
        if SessionToken <> '' then begin
            CanonicalHeaders += 'x-amz-security-token:' + SessionToken + LF;
            SignedHeadersList += ';x-amz-security-token';
        end;

        if pHasBody then
            PayloadHash := Sha256HexLower(pPayload)
        else
            PayloadHash := Sha256HexLower('');

        CanonicalRequest := pMethod + LF + CanonicalUri + LF + LF + CanonicalHeaders + LF + SignedHeadersList + LF + PayloadHash;

        CredentialScope := DateStamp + '/' + Region + '/' + Service + '/aws4_request';

        StringToSign := 'AWS4-HMAC-SHA256' + LF + vAmzDate + LF + CredentialScope + LF + Sha256HexLower(CanonicalRequest);

        SigningKey := DeriveSigningKey(SecretAccessKey, DateStamp, Region, Service);
        Signature := HmacSignatureHexLower(SigningKey, StringToSign);

        vAuthorizationHeader :=
            'AWS4-HMAC-SHA256 Credential=' + AccessKeyId + '/' + CredentialScope +
            ', SignedHeaders=' + SignedHeadersList + ', Signature=' + Signature;
    end;

    local procedure SanitizeHeaderText(pText: Text): Text
    var
        TextBuilderObj: TextBuilder;
        Ch: Char;
    begin
        // Strips anything outside printable ASCII (0x20-0x7E) - not just leading/trailing (Trim()),
        // but also embedded characters such as smart dashes, non-breaking spaces, or stray line
        // breaks picked up from copy-pasting credentials out of Word/Outlook/PDF. .NET's
        // HttpHeaders.Add() rejects such characters outright ("Invalid HTTP header").
        foreach Ch in pText do
            if (Ch >= ' ') and (Ch <= '~') then
                TextBuilderObj.Append(Ch);
        exit(TextBuilderObj.ToText());
    end;

    local procedure HexEncode(pInStream: InStream): Text
    var
        TextBuilderObj: TextBuilder;
        ByteValue: Byte;
    begin
        while not pInStream.EOS do begin
            pInStream.Read(ByteValue);
            TextBuilderObj.Append(CopyStr('0123456789abcdef', (ByteValue div 16) + 1, 1));
            TextBuilderObj.Append(CopyStr('0123456789abcdef', (ByteValue mod 16) + 1, 1));
        end;
        exit(TextBuilderObj.ToText());
    end;

    local procedure Sha256HexLower(pText: Text): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        exit(LowerCase(CryptographyManagement.GenerateHash(pText, HashAlgorithmType::SHA256)));
    end;

    local procedure HmacChainStep(pBase64Key: Text; pMessage: Text): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512;
    begin
        exit(CryptographyManagement.GenerateBase64KeyedHashAsBase64String(pMessage, pBase64Key, HashAlgorithmType::HMACSHA256));
    end;

    local procedure DeriveSigningKey(pSecretAccessKey: Text; pDateStamp: Text; pRegion: Text; pService: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        SeedKey: Text;
        DateKey: Text;
        RegionKey: Text;
        ServiceKey: Text;
        SigningKey: Text;
    begin
        SeedKey := Base64Convert.ToBase64('AWS4' + pSecretAccessKey);
        DateKey := HmacChainStep(SeedKey, pDateStamp);
        RegionKey := HmacChainStep(DateKey, pRegion);
        ServiceKey := HmacChainStep(RegionKey, pService);
        SigningKey := HmacChainStep(ServiceKey, 'aws4_request');
        exit(SigningKey);
    end;

    local procedure HmacSignatureHexLower(pBase64Key: Text; pMessage: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlobObj: Codeunit "Temp Blob";
        SignatureBase64: Text;
        OutStr: OutStream;
        InStr: InStream;
    begin
        SignatureBase64 := HmacChainStep(pBase64Key, pMessage);
        TempBlobObj.CreateOutStream(OutStr);
        Base64Convert.FromBase64(SignatureBase64, OutStr);
        TempBlobObj.CreateInStream(InStr);
        exit(HexEncode(InStr));
    end;

    local procedure BuildRedactedRequestText(pMethod: Text; pUrl: Text; pAuthType: Enum "CXW API Auth Type"; pHasSessionToken: Boolean; pHasApiKey: Boolean; pSoapAction: Text; pHasBody: Boolean; pJsonBody: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        RequestText: Text;
    begin
        RequestText := pMethod + ' ' + pUrl;
        if pHasBody then
            RequestText += TypeHelper.LFSeparator() + 'Content-Type: application/json';
        if pSoapAction <> '' then
            RequestText += TypeHelper.LFSeparator() + 'SOAPAction: ' + pSoapAction;
        if pAuthType <> pAuthType::None then
            RequestText += TypeHelper.LFSeparator() + 'Authorization: ' + AuthRedactedTxt;
        if pHasSessionToken then
            RequestText += TypeHelper.LFSeparator() + 'X-Amz-Security-Token: ' + AuthRedactedTxt;
        if pHasApiKey then
            RequestText += TypeHelper.LFSeparator() + 'X-API-Key: ' + AuthRedactedTxt;
        RequestText += TypeHelper.LFSeparator() + TypeHelper.LFSeparator() + pJsonBody;
        exit(RequestText);
    end;

    local procedure LogHttpCall(pDataExportEntryNo: BigInteger; pEndpointUrl: Text; pSuccess: Boolean; pHttpStatusCode: Integer; pErrorMessage: Text; pRequestText: Text; pResponseText: Text)
    var
        HttpCallLog: Record "CXW Http Call Log";
        OutStr: OutStream;
    begin
        HttpCallLog.Init();
        HttpCallLog."CXW Source Table No." := Database::"Data Export Entry";
        HttpCallLog."CXW Source Entry No" := pDataExportEntryNo;
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
        // Reserved: must not exist as "Data Export API Setup" code, so ChronextBC's "Export Data" cannot resend these entries without SigV4.
        SalesPriceDestinationCodeLbl: Label 'SALESPRICE', Locked = true;
}
