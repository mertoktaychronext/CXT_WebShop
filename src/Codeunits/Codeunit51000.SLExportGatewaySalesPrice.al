codeunit 51000 "SL Export Gateway Sales Price"
{
    procedure CreateExternalInterfaceFile(SalesPrice: Record "Sales Price")
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
}
