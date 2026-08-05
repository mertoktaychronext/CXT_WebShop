enum 51004 "SL API Auth Type"
{
    Extensible = true;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; ApiKeyHeader)
    {
        Caption = 'API Key (Header)';
    }
    value(2; BasicAuth)
    {
        Caption = 'Basic Authentication';
    }
}
