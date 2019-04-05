float4 _ShibaColor;
float4 _WhiteColor;
float _ShibaThreshild;
float _WhiteThreshild;
float _NoiseAmount;
float _NoiseFrequency;
float _EmissionAmount;
float _FurAmount;
float _FurDecay;
float _FurLength;
float _FurShade;
float _FurFrequency;
float _FurLayers;
float _FurGravity;

struct AppData
{
    float4 position : POSITION;
    float3 normal : NORMAL;
};

struct GeoToFragData
{
    float3 localPosition : LOCAL_POSITION;
    float3 localNormal : LOCAL_NORMAL;
    float4 worldPosition : SV_POSITION;
    float furFactor: FUR_FACTOR;
};

struct FragData
{
    half4 albedo : SV_Target0;
    half4 specular : SV_Target1;
    half4 normal : SV_Target2;
    half4 emission : SV_Target3;
};

AppData vert (AppData v)
{
    AppData o;
    o.position = v.position;
    o.normal = v.normal;
    return o;
}


GeoToFragData VertexOutput(float3 localPosition, half3 localNormal, float furFactor)
{
    GeoToFragData o;
    o.localPosition = localPosition;
    o.worldPosition = UnityObjectToClipPos(
        localPosition
        + normalize(localNormal + float3(0, -1, 0) * _FurGravity) * furFactor * _FurLength);
    o.furFactor = furFactor;
    o.localNormal = localNormal;
    return o;
}

[maxvertexcount(90)]
void geo(triangle AppData input[3], uint pid : SV_PrimitiveID, inout TriangleStream<GeoToFragData> outStream)
{
    outStream.Append(VertexOutput(input[0].position, input[0].normal, 0));
    outStream.Append(VertexOutput(input[1].position, input[1].normal, 0));
    outStream.Append(VertexOutput(input[2].position, input[2].normal, 0));
    outStream.RestartStrip();

    for(int i = 0; i < _FurLayers; i++) {
        outStream.Append(VertexOutput(input[0].position, input[0].normal, i / (_FurLayers - 1)));
        outStream.Append(VertexOutput(input[1].position, input[1].normal, i / (_FurLayers - 1)));
        outStream.Append(VertexOutput(input[2].position, input[2].normal, i / (_FurLayers - 1)));
    }

    outStream.RestartStrip();
}


FragData frag (GeoToFragData i) : SV_Target {
    FragData fd;
    float noise = snoise(i.localPosition * _NoiseFrequency) + snoise(i.localPosition * _NoiseFrequency * 2) * 0.5;
    float mix = smoothstep(_ShibaThreshild, _WhiteThreshild, (dot(normalize(float3(0, -1, 0)), i.localNormal) + 1) * 0.5 + noise * _NoiseAmount);
    float3 albedo = lerp(_ShibaColor, _WhiteColor, mix) * (1 - (1 - i.furFactor) * _FurShade);
    float noise2 = abs(snoise(i.localPosition * _FurFrequency));
    float furLower = (0.5 - _FurAmount) * 2;
    float alpha = i.furFactor > 0 ? i.furFactor * (1 - furLower) * _FurDecay + furLower : -1;
    clip(noise2 - alpha);
    fd.albedo = half4(albedo, alpha);
    fd.specular = half4(0, 0, 0, 0);
    fd.normal = half4(UnityObjectToWorldNormal(i.localNormal) * 0.5 + 0.5, 1);
    fd.emission = _EmissionAmount * half4(albedo, 0);
    return fd;
}