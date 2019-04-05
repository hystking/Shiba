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
float _WindAmount;
float _WindFrequency;
float _WindSpeed;

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


GeoToFragData VertexOutput(float3 localPosition, half3 localNormal, float furFactor, float3 furDirection)
{
    GeoToFragData o;
    o.localPosition = localPosition;
    o.worldPosition = UnityObjectToClipPos(
        localPosition
        + furDirection * furFactor * _FurLength
    );
    o.furFactor = furFactor;
    o.localNormal = localNormal;
    o.worldNormal = UnityObjectToWorldNormal(localNormal);
    return o;
}

float3 calcFurDirection(float3 localPosition, float3 localNormal, float3 polyNormal) {
    float3 noise = snoise_grad(localPosition * _WindFrequency + _Time.z * float3(0, 1, 0) * _WindSpeed);
    float3 furDirection = normalize(localNormal + float3(0, -1, 0) * _FurGravity + noise * _WindAmount);
    float furDot = dot(polyNormal, furDirection);
    return lerp(reflect(furDirection, polyNormal), furDirection, furDot * 0.5 + 0.5);
}

[maxvertexcount(72)]
void geo(triangle AppData input[3], uint pid : SV_PrimitiveID, inout TriangleStream<GeoToFragData> outStream)
{
    float3 polyNormal = normalize(cross(
        input[1].position - input[0].position,
        input[2].position - input[0].position
    ));
    float3 furDirection0 = calcFurDirection(input[0].position, input[0].normal, polyNormal);
    float3 furDirection1 = calcFurDirection(input[1].position, input[1].normal, polyNormal);
    float3 furDirection2 = calcFurDirection(input[2].position, input[2].normal, polyNormal);
    outStream.Append(VertexOutput(input[0].position, input[0].normal, 0, furDirection0));
    outStream.Append(VertexOutput(input[1].position, input[1].normal, 0, furDirection1));
    outStream.Append(VertexOutput(input[2].position, input[2].normal, 0, furDirection2));
    outStream.RestartStrip();

    for(int i = 0; i < _FurLayers; i++) {
        outStream.Append(VertexOutput(input[0].position, input[0].normal, i / (_FurLayers - 1), furDirection0));
        outStream.Append(VertexOutput(input[1].position, input[1].normal, i / (_FurLayers - 1), furDirection1));
        outStream.Append(VertexOutput(input[2].position, input[2].normal, i / (_FurLayers - 1), furDirection2));
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
    fd.albedo = half4(albedo, alpha);
    fd.specular = half4(0, 0, 0, 0);
    fd.normal = half4(i.worldNormal * 0.5 + 0.5, 1);
    fd.emission = _EmissionAmount * half4(albedo, 0);
    return fd;
}