codeunit 51000 "SL Export Gateway Sales Price"
{
    [TryFunction]
    procedure WriteBackAndArchive(SalesPriceChecking: Record "SL Sales Price Checking"; var SalesPrice: Record "Sales Price")
    begin
        if not SalesPrice.Get(
             SalesPriceChecking."Item No.", SalesPrice."Sales Type"::"All Customers", '',
             SalesPriceChecking."Starting Date", SalesPriceChecking."Currency Code",
             SalesPriceChecking."Variant Code", '', 0)
        then begin
            SalesPrice.Init();
            SalesPrice."Item No." := SalesPriceChecking."Item No.";
            SalesPrice.Validate("Sales Type", SalesPrice."Sales Type"::"All Customers");
            SalesPrice."Sales Code" := '';
            SalesPrice."Starting Date" := SalesPriceChecking."Starting Date";
            SalesPrice."Variant Code" := SalesPriceChecking."Variant Code";
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

    local procedure UpdateSalesPriceFields(var vSalesPrice: Record "Sales Price"; pSalesPriceChecking: Record "SL Sales Price Checking")
    begin
        vSalesPrice.Validate("Currency Code", pSalesPriceChecking."Currency Code");
        vSalesPrice.Validate("Country/Region Code", '');
        vSalesPrice.Validate("Unit Price", pSalesPriceChecking."Stock Price");
        vSalesPrice."Strike-Price incl. VAT" := pSalesPriceChecking."Strike Price";
        vSalesPrice."Recom. Retail Price incl. VAT" := pSalesPriceChecking."Recom. Retail Price";
        vSalesPrice."Reason Code" := pSalesPriceChecking."Reason Code";
        vSalesPrice.Comment := pSalesPriceChecking.Comment;
        vSalesPrice.Remark := pSalesPriceChecking.Remark;
    end;

    local procedure ArchiveCheckingLine(pSalesPriceChecking: Record "SL Sales Price Checking")
    var
        l_recSalesPriceArchive: Record "SL Sales Price Archive";
        l_intNextVersionNo: Integer;
    begin
        l_recSalesPriceArchive.Reset();
        l_recSalesPriceArchive.LockTable();
        l_recSalesPriceArchive.SetRange("Item No.", pSalesPriceChecking."Item No.");
        l_recSalesPriceArchive.SetRange("Variant Code", pSalesPriceChecking."Variant Code");
        l_recSalesPriceArchive.SetRange("Currency Code", pSalesPriceChecking."Currency Code");
        l_recSalesPriceArchive.SetRange("Country Code", '');
        if l_recSalesPriceArchive.FindLast() then
            l_intNextVersionNo := l_recSalesPriceArchive."Version No." + 1
        else
            l_intNextVersionNo := 1;

        l_recSalesPriceArchive.Init();
        l_recSalesPriceArchive.TransferFields(pSalesPriceChecking, false);
        l_recSalesPriceArchive."Country Code" := '';
        l_recSalesPriceArchive."Version No." := l_intNextVersionNo;
        l_recSalesPriceArchive.Insert(true);
    end;

    procedure CreateExternalInterfaceFile(SalesPrice: Record "Sales Price"): Boolean
    var
        OutboundFile: Record "SL Sales Price Outbound File";
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
        OutboundFile.Status := OutboundFile.Status::New;
        OutboundFile.Filename :=
            CopyStr(
                StrSubstNo('SalesPrice_%1_%2.json', SalesPrice."Item No.", SalesPrice."Currency Code"),
                1, MaxStrLen(OutboundFile.Filename));
        OutboundFile.TargetFile.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(JsonText);
        OutboundFile.Insert(true);

        exit(SendToApiInterface(OutboundFile, JsonText));
    end;

    local procedure SendToApiInterface(var vOutboundFile: Record "SL Sales Price Outbound File"; pJsonText: Text): Boolean
    var
        GenSPSetup: Record "SL General Sales Price Setup";
        ApiInterfaceSetup: Record "SL API Interface Setup";
        Base64Convert: Codeunit "Base64 Convert";
        HttpClientObj: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpContentObj: HttpContent;
        HttpHeadersObj: HttpHeaders;
        ResponseText: Text;
        SendOk: Boolean;
    begin
        if not GenSPSetup.Get() then
            exit(false);
        if not GenSPSetup."Price Export Active" then
            exit(false);
        if GenSPSetup."API Interface Code" = '' then
            exit(false);

        if not ApiInterfaceSetup.Get(GenSPSetup."API Interface Code") then
            Error(ApiInterfaceNotFoundErr, GenSPSetup."API Interface Code");
        ApiInterfaceSetup.TestField(Active, true);
        ApiInterfaceSetup.TestField("Source Table No.", Database::"Sales Price");
        ApiInterfaceSetup.TestField("Endpoint URL");

        HttpContentObj.WriteFrom(pJsonText);
        HttpContentObj.GetHeaders(HttpHeadersObj);
        HttpHeadersObj.Remove('Content-Type');
        HttpHeadersObj.Add('Content-Type', 'application/json');

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(ApiInterfaceSetup."Endpoint URL");
        HttpRequest.Content := HttpContentObj;

        case ApiInterfaceSetup."Auth Type" of
            ApiInterfaceSetup."Auth Type"::ApiKeyHeader:
                begin
                    HttpRequest.GetHeaders(HttpHeadersObj);
                    HttpHeadersObj.Add('Authorization', ApiInterfaceSetup.GetApiKey());
                end;
            ApiInterfaceSetup."Auth Type"::BasicAuth:
                begin
                    HttpRequest.GetHeaders(HttpHeadersObj);
                    HttpHeadersObj.Add('Authorization', 'Basic ' + Base64Convert.ToBase64(ApiInterfaceSetup.GetApiKey()));
                end;
        end;

        HttpClientObj.Timeout := 30000;
        SendOk := HttpClientObj.Send(HttpRequest, HttpResponse);

        if SendOk and HttpResponse.IsSuccessStatusCode() then begin
            vOutboundFile.Status := vOutboundFile.Status::Processed;
            vOutboundFile."Response Message" := '';
            vOutboundFile.Modify();
            exit(true);
        end;

        if SendOk then begin
            HttpResponse.Content().ReadAs(ResponseText);
            ResponseText := StrSubstNo('HTTP %1: %2', HttpResponse.HttpStatusCode(), ResponseText);
        end else
            ResponseText := 'The request could not be sent (network error).';

        vOutboundFile.Status := vOutboundFile.Status::Error;
        vOutboundFile."Response Message" := CopyStr(ResponseText, 1, MaxStrLen(vOutboundFile."Response Message"));
        vOutboundFile.Modify();
        exit(false);
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
}
