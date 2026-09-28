codeunit 60329 "CXW Export Gateway Sales Price"
{
    procedure WriteBackAndArchive(SalesPriceChecking: Record "CXW Sales Price Checking"; var SalesPrice: Record "Sales Price")
    var
        GenSPSetup: Record "CXW General Sales Price Setup";
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

        // Only the price of the archive country (DE) is archived; all countries are kept in "CXW Sales Price Export".
        GenSPSetup.Get();
        GenSPSetup.TestField("CXW Archive Country Code");
        if SalesPriceChecking."CXW Country Code" = GenSPSetup."CXW Archive Country Code" then
            ArchiveCheckingLine(SalesPriceChecking);
    end;

    local procedure UpdateSalesPriceFields(var vSalesPrice: Record "Sales Price"; pSalesPriceChecking: Record "CXW Sales Price Checking")
    begin
        vSalesPrice.Validate("Currency Code", pSalesPriceChecking."CXW Currency Code");
        vSalesPrice.Validate("Unit Price", pSalesPriceChecking."CXW Stock Price");
        vSalesPrice."CXW Unit Price (LCY)" :=
            ResolveUnitPriceLCY(pSalesPriceChecking."CXW Currency Code", pSalesPriceChecking."CXW Exchange Rate Amount", vSalesPrice."Unit Price");
        vSalesPrice."CXW Strike-Price incl. VAT" := pSalesPriceChecking."CXW Strike Price";
        vSalesPrice."CXW Rec. Retail Price incl VAT" := pSalesPriceChecking."CXW Recom. Retail Price";
        vSalesPrice."CXW Reason Code" := pSalesPriceChecking."CXW Reason Code";
        vSalesPrice."CXW Comment" := pSalesPriceChecking."CXW Comment";
        vSalesPrice."CXW Remark" := pSalesPriceChecking."CXW Remark";
    end;

    local procedure ResolveUnitPriceLCY(pCurrencyCode: Code[10]; pExchangeRateAmount: Decimal; pUnitPrice: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        ExchangeRateDate: Date;
        ExchangeRateAmt: Decimal;
    begin
        if pCurrencyCode = '' then
            exit(pUnitPrice);

        if pExchangeRateAmount <> 0 then
            exit(pUnitPrice / pExchangeRateAmount);

        CurrExchRate.SetRange("Currency Code", pCurrencyCode);
        if not CurrExchRate.FindLast() then
            exit(0);

        CurrExchRate.GetLastestExchangeRate(pCurrencyCode, ExchangeRateDate, ExchangeRateAmt);
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

    procedure QueueExport(SalesPriceChecking: Record "CXW Sales Price Checking"; SalesPrice: Record "Sales Price")
    var
        SalesPriceExport: Record "CXW Sales Price Export";
        DataExportEntry: Record "Data Export Entry";
    begin
        SalesPriceExport.Init();
        SalesPriceExport."CXW Item No." := SalesPriceChecking."CXW Item No.";
        SalesPriceExport."CXW Country Code" := SalesPriceChecking."CXW Country Code";
        SalesPriceExport."CXW Currency Code" := SalesPriceChecking."CXW Currency Code";
        SalesPriceExport."CXW Starting Date" := SalesPriceChecking."CXW Starting Date";
        SalesPriceExport."CXW Starting Time" := SalesPriceChecking."CXW Starting Time";
        SalesPriceExport."CXW Ending Date" := SalesPriceChecking."CXW Ending Date";
        SalesPriceExport."CXW Ending Time" := SalesPriceChecking."CXW Ending Time";
        SalesPriceExport."CXW Unit Price" := SalesPriceChecking."CXW Stock Price";
        SalesPriceExport."CXW Unit Price (LCY)" :=
            ResolveUnitPriceLCY(SalesPriceChecking."CXW Currency Code", SalesPriceChecking."CXW Exchange Rate Amount", SalesPriceChecking."CXW Stock Price");
        SalesPriceExport."CXW Non Stock Price" := SalesPriceChecking."CXW Non Stock Price";
        SalesPriceExport."CXW Strike Price" := SalesPriceChecking."CXW Strike Price";
        SalesPriceExport."CXW Recom. Retail Price" := SalesPriceChecking."CXW Recom. Retail Price";
        SalesPriceExport."CXW Exchange Rate Amount" := SalesPriceChecking."CXW Exchange Rate Amount";
        SalesPriceExport."CXW Exchange Rate Date" := SalesPriceChecking."CXW Exchange Rate Date";
        SalesPriceExport."CXW Reason Code" := SalesPriceChecking."CXW Reason Code";
        SalesPriceExport."CXW Comment" := SalesPriceChecking."CXW Comment";
        SalesPriceExport."CXW Remark" := SalesPriceChecking."CXW Remark";
        SalesPriceExport."CXW Last Modified UserID" := SalesPriceChecking."CXW Last Modified UserID";
        SalesPriceExport."CXW Last Modified Date" := SalesPriceChecking."CXW Last Modified Date";
        SalesPriceExport."CXW Sales Price SystemId" := SalesPrice.SystemId;
        SalesPriceExport.Insert(true);

        DataExportEntry.Init();
        DataExportEntry."Destination Code" := SalesPriceDestinationCodeLbl;
        DataExportEntry."Payload Format" := DataExportEntry."Payload Format"::JSON;
        DataExportEntry.FileName :=
            CopyStr(
                StrSubstNo('SalesPrice_%1_%2_%3.json', SalesPriceExport."CXW Item No.", SalesPriceExport."CXW Currency Code", SalesPriceExport."CXW Country Code"),
                1, MaxStrLen(DataExportEntry.FileName));
        DataExportEntry."Source Record ID" := SalesPriceExport.RecordId();
        DataExportEntry.Insert(true);
        // OnInsert always sets "Waiting to Process", which ChronextBC's "Data Export Mgt." would pick up -
        // overwritten in the same transaction so that status is never committed.
        DataExportEntry.Status := DataExportEntry.Status::"CXW Pending";
        DataExportEntry.Modify(true);

        SalesPriceExport."CXW Data Export Entry No." := DataExportEntry."Entry No.";
        SalesPriceExport.Modify(true);
    end;

    procedure GetDestinationCode(): Code[20]
    begin
        exit(SalesPriceDestinationCodeLbl);
    end;

    procedure ExportEntry(var DataExportEntry: Record "Data Export Entry")
    var
        JsonText: Text;
        PayloadInStream: InStream;
    begin
        DataExportEntry.TestField("Destination Code", SalesPriceDestinationCodeLbl);

        // The payload is built once; retries send exactly the same content.
        DataExportEntry.CalcFields(Payload);
        if not DataExportEntry.Payload.HasValue() then begin
            DataExportEntry.SetPayload(BuildPayload(DataExportEntry));
            DataExportEntry.Modify(true);
            DataExportEntry.CalcFields(Payload);
        end;

        DataExportEntry.CreatePayloadInStream(PayloadInStream);
        PayloadInStream.Read(JsonText);

        SendToApiInterface(DataExportEntry, JsonText);
    end;

    local procedure BuildPayload(DataExportEntry: Record "Data Export Entry"): Text
    var
        SalesPriceExport: Record "CXW Sales Price Export";
        SalesPrice: Record "Sales Price";
        Item: Record Item;
        SourceRecRef: RecordRef;
    begin
        if (DataExportEntry."Source Record ID".TableNo() <> Database::"CXW Sales Price Export") or
           not SourceRecRef.Get(DataExportEntry."Source Record ID")
        then
            Error(ExportRecordNotFoundErr, DataExportEntry."Entry No.");
        SourceRecRef.SetTable(SalesPriceExport);

        if not SalesPrice.GetBySystemId(SalesPriceExport."CXW Sales Price SystemId") then
            Error(SalesPriceNotFoundErr, SalesPriceExport."CXW Item No.", SalesPriceExport."CXW Country Code");
        if not Item.Get(SalesPriceExport."CXW Item No.") then
            Error(ItemNotFoundErr, SalesPriceExport."CXW Item No.");

        exit(BuildSalesPriceJson(SalesPriceExport, SalesPrice, Item));
    end;

    local procedure BuildSalesPriceJson(pSalesPriceExport: Record "CXW Sales Price Export"; pSalesPrice: Record "Sales Price"; pItem: Record Item): Text
    var
        JsonObj: JsonObject;
        JsonText: Text;
    begin
        // Fixed key set and order agreed with the receiver (NAV "CHNX Sales Price Entity" format without
        // variant, promotion and DiVA fields).
        JsonObj.Add('itemNo', pSalesPriceExport."CXW Item No.");
        JsonObj.Add('salesType', Format(pSalesPrice."Sales Type".AsInteger()));
        JsonObj.Add('salesCode', pSalesPrice."Sales Code");
        JsonObj.Add('startingDate', FormatDate(pSalesPriceExport."CXW Starting Date"));
        JsonObj.Add('currencyCode', pSalesPriceExport."CXW Currency Code");
        JsonObj.Add('countryRegionCode', pSalesPriceExport."CXW Country Code");
        JsonObj.Add('unitOfMeasureCode', pSalesPrice."Unit of Measure Code");
        JsonObj.Add('minimumQuantity', pSalesPrice."Minimum Quantity");
        JsonObj.Add('unitPrice', pSalesPriceExport."CXW Unit Price");
        JsonObj.Add('priceIncludesVat', pSalesPrice."Price Includes VAT");
        JsonObj.Add('allowInvoiceDisc', pSalesPrice."Allow Invoice Disc.");
        JsonObj.Add('vatBusPostingGrPrice', pSalesPrice."VAT Bus. Posting Gr. (Price)");
        JsonObj.Add('endingDate', FormatDate(pSalesPriceExport."CXW Ending Date"));
        JsonObj.Add('allowLineDisc', pSalesPrice."Allow Line Disc.");
        JsonObj.Add('id', Format(pSalesPriceExport."CXW Sales Price SystemId"));
        JsonObj.Add('remark', pSalesPriceExport."CXW Remark");
        JsonObj.Add('nonStockPrice', pSalesPriceExport."CXW Non Stock Price");
        JsonObj.Add('lastModifiedUserID', pSalesPriceExport."CXW Last Modified UserID");
        JsonObj.Add('lastModifiedDate', FormatDateTime(pSalesPriceExport."CXW Last Modified Date"));
        JsonObj.Add('reasonCode', GetReasonCodeName(pSalesPriceExport."CXW Reason Code"));
        JsonObj.Add('comment', pSalesPriceExport."CXW Comment");
        JsonObj.Add('strikePriceInclVat', pSalesPriceExport."CXW Strike Price");
        JsonObj.Add('recomRetailPriceInclVat', pSalesPriceExport."CXW Recom. Retail Price");
        JsonObj.Add('unitPriceLcy', pSalesPriceExport."CXW Unit Price (LCY)");
        JsonObj.Add('startingTime', FormatTime(pSalesPriceExport."CXW Starting Time"));
        JsonObj.Add('endingTime', FormatTime(pSalesPriceExport."CXW Ending Time"));
        JsonObj.Add('profit',
            CalcProfitPercent(
                pSalesPriceExport."CXW Unit Price (LCY)", pSalesPrice."VAT Bus. Posting Gr. (Price)",
                pItem."VAT Prod. Posting Group", pItem."Unit Cost"));
        JsonObj.Add('unitCost', pItem."Unit Cost");
        JsonObj.Add('vatProdPostingGroup', pItem."VAT Prod. Posting Group");
        JsonObj.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure CalcProfitPercent(pUnitPriceLcy: Decimal; pVatBusPostingGr: Code[20]; pVatProdPostingGr: Code[20]; pUnitCost: Decimal): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VatPct: Decimal;
        NetPriceLcy: Decimal;
    begin
        if VATPostingSetup.Get(pVatBusPostingGr, pVatProdPostingGr) then
            VatPct := VATPostingSetup."VAT %";

        NetPriceLcy := pUnitPriceLcy / (1 + VatPct / 100);
        if NetPriceLcy = 0 then
            exit(0);
        exit(Round((NetPriceLcy - pUnitCost) / NetPriceLcy * 100, 0.01));
    end;

    local procedure GetReasonCodeName(pReasonCode: Enum "CXW Sales Price Reason Code"): Text
    begin
        // The enum value name, not the (translated) caption - independent of the session language.
        exit(pReasonCode.Names().Get(pReasonCode.Ordinals().IndexOf(pReasonCode.AsInteger())));
    end;

    local procedure FormatDate(pDate: Date): Text
    begin
        if pDate = 0D then
            exit('');
        exit(Format(pDate, 0, 9));
    end;

    local procedure FormatTime(pTime: Time): Text
    begin
        if pTime = 0T then
            exit('');
        exit(Format(pTime, 0, 9));
    end;

    local procedure FormatDateTime(pDateTime: DateTime): Text
    begin
        if pDateTime = 0DT then
            exit('');
        exit(Format(pDateTime, 0, 9));
    end;

    local procedure SendToApiInterface(var DataExportEntry: Record "Data Export Entry"; pJsonText: Text)
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
        SendBody: Boolean;
        SendOk: Boolean;
    begin
        GenSPSetup.Get();
        GenSPSetup.TestField("CXW Price Export Active", true);
        GenSPSetup.TestField("CXW API Interface Code");

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

        if SendOk and HttpResponse.IsSuccessStatusCode() then begin
            HttpResponse.Content().ReadAs(ResponseText);
            SetAttemptResult(DataExportEntry, true, '');
            LogHttpCall(DataExportEntry."Entry No.", ApiInterfaceSetup."CXW Endpoint URL", true, HttpResponse.HttpStatusCode(), '', RequestLogText, ResponseText);
            exit;
        end;

        if SendOk then begin
            HttpResponse.Content().ReadAs(ResponseText);
            FormattedErrorTxt := StrSubstNo('HTTP %1: %2', HttpResponse.HttpStatusCode(), ResponseText);
            SetAttemptResult(DataExportEntry, false, FormattedErrorTxt);
            LogHttpCall(DataExportEntry."Entry No.", ApiInterfaceSetup."CXW Endpoint URL", false, HttpResponse.HttpStatusCode(), FormattedErrorTxt, RequestLogText, ResponseText);
        end else begin
            SetAttemptResult(DataExportEntry, false, NetworkErrorTxt);
            LogHttpCall(DataExportEntry."Entry No.", ApiInterfaceSetup."CXW Endpoint URL", false, 0, NetworkErrorTxt, RequestLogText, '');
        end;
    end;

    procedure SetAttemptResult(var DataExportEntry: Record "Data Export Entry"; pSuccess: Boolean; pErrorMessage: Text)
    begin
        DataExportEntry."Attempt Count" += 1;
        DataExportEntry."Last Attempt At" := CurrentDateTime;
        if pSuccess then begin
            DataExportEntry.Status := DataExportEntry.Status::Processed;
            DataExportEntry."Processed At" := CurrentDateTime;
            DataExportEntry."Error Message" := '';
        end else begin
            DataExportEntry.Status := DataExportEntry.Status::Error;
            DataExportEntry."Error Message" := CopyStr(pErrorMessage, 1, MaxStrLen(DataExportEntry."Error Message"));
        end;
        DataExportEntry.Modify(true);
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

    var
        ApiInterfaceNotFoundErr: Label 'API interface %1 (selected on the general sales price setup) no longer exists.', Comment = '%1 = API interface code';
        ExportRecordNotFoundErr: Label 'The sales price export record of data export entry %1 no longer exists.', Comment = '%1 = data export entry no.';
        SalesPriceNotFoundErr: Label 'The sales price of item %1 for country %2 no longer exists.', Comment = '%1 = item no., %2 = country code';
        ItemNotFoundErr: Label 'Item %1 no longer exists.', Comment = '%1 = item no.';
        AuthRedactedTxt: Label '***redacted***', Locked = true;
        NetworkErrorTxt: Label 'The request could not be sent (network error).';
        // Reserved: must not exist as "Data Export API Setup" code, so ChronextBC's "Export Data" cannot resend these entries without SigV4.
        SalesPriceDestinationCodeLbl: Label 'SALESPRICE', Locked = true;
}
