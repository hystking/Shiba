float4 _ShibaColor;
float4 _WhiteColor;
float _ShibaThreshild;
float _WhiteThreshild;
float _NoiseAmount;
float _NoiseFrequency;
float _FurAmount;
float _FurDecay;
float _FurLength;
float _FurShade;
float _FurFrequency;
float _FurLayers;
float _FurGravity;
float _WindAmount;
float _WindFrequency;
float _WindSpeed;
float _FurHardness;

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
    float3 worldNormal : NORMAL;
    half3 ambient : TEXCOORD4;
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


GeoToFragData VertexOutput(float3 localPosition, half3 localNormal, float furFactor, float3 furDrift)
{
    GeoToFragData o;
    o.localPosition = localPosition;
    o.worldPosition = UnityObjectToClipPos(
        localPosition
        + localNormal * furFactor * _FurLength
        + furDrift * pow(furFactor, _FurHardness) * _FurLength
    );
    o.furFactor = furFactor;
    o.localNormal = localNormal;
    o.worldNormal = UnityObjectToWorldNormal(localNormal);
    o.ambient = ShadeSHPerVertex(o.worldNormal, 0);
    return o;
}

float3 calcFurDrift(float3 localPosition, float3 localNormal, float3 gravityDirection) {
    float3 noise = snoise_grad(localPosition * _WindFrequency + _Time.z * float3(0, 1, 0) * _WindSpeed);
    float3 furDirection = normalize(localNormal + gravityDirection * _FurGravity + noise * _WindAmount);
    float furDot = dot(localNormal, furDirection);
    return lerp(normalize(furDirection - (furDot - 0.1f) * localNormal), furDirection, clamp(furDot, 0, 1)) - localNormal;
}

[maxvertexcount(60)]
void geo(triangle AppData input[3], uint pid : SV_PrimitiveID, inout TriangleStream<GeoToFragData> outStream)
{
    float3 gravityDirection = mul( unity_WorldToObject, float4( 0, -1, 0, 0 ) ).xyz;
    float3 furDrift0 = calcFurDrift(input[0].position, input[0].normal, gravityDirection);
    float3 furDrift1 = calcFurDrift(input[1].position, input[1].normal, gravityDirection);
    float3 furDrift2 = calcFurDrift(input[2].position, input[2].normal, gravityDirection);
    outStream.Append(VertexOutput(input[0].position, input[0].normal, 0, furDrift0));
    outStream.Append(VertexOutput(input[1].position, input[1].normal, 0, furDrift1));
    outStream.Append(VertexOutput(input[2].position, input[2].normal, 0, furDrift2));
    outStream.RestartStrip();

    for(int i = 1; i <= _FurLayers; i++) {
        outStream.Append(VertexOutput(input[0].position, input[0].normal, i / _FurLayers, furDrift0));
        outStream.Append(VertexOutput(input[1].position, input[1].normal, i / _FurLayers, furDrift1));
        outStream.Append(VertexOutput(input[2].position, input[2].normal, i / _FurLayers, furDrift2));
    }

    outStream.RestartStrip();
}


FragData frag (GeoToFragData i) : SV_Target {
    FragData fd;
    float noise = snoise(i.localPosition * _NoiseFrequency);
    float mix = smoothstep(_ShibaThreshild, _WhiteThreshild, (dot(normalize(float3(0, -1, 0)), i.localNormal) + 1) * 0.5 + noise * _NoiseAmount);
    float3 albedo = lerp(_ShibaColor, _WhiteColor, mix) * (1 - (1 - i.furFactor) * _FurShade);
    float noise2 = abs(snoise(i.localPosition * _FurFrequency));
    float furLower = (0.5 - _FurAmount) * 2;
    float alpha = i.furFactor > 0 ? i.furFactor * (1 - furLower) * _FurDecay + furLower : -1;
    clip(noise2 - alpha);
    fd.albedo = half4(albedo, 1);
    fd.specular = half4(0, 0, 0, 0);
    fd.normal = half4(i.worldNormal * 0.5 + 0.5, 1);
    fd.emission = half4(ShadeSHPerPixel(i.worldNormal, i.ambient, i.worldPosition) * albedo, 0);
    return fd;
}