attribute vec4 Position;
attribute vec2 TexCoord1;
attribute vec2 TexCoord2;

uniform vec2 Weights1[71];
uniform vec2 Weights2[71];
uniform vec2 InterpMarkers[68];

varying vec2 TexCoordVarying1;
varying vec2 TexCoordVarying2;

highp float tps(highp vec2 pos1, highp vec2 pos2)
{
    highp vec2 diff = pos1-pos2;
    highp float r2 = dot(diff, diff);
    return r2*log(r2);
}

highp vec2 calcTexOffset1(highp vec2 tex1)
{
    highp vec2 result = vec2(0, 0);
    for(int i = 0; i < 68; i++)
    {
        result += tps(InterpMarkers[i], tex1)*Weights1[i];
    }
    result += Weights1[68];
    result += Weights1[69]*tex1.x;
    result += Weights1[70]*tex1.y;
    return result;
}

highp vec2 calcTexOffset2(highp vec2 tex2)
{
    vec2 result = vec2(0, 0);
    for(int i = 0; i < 68; i++)
    {
        result += tps(InterpMarkers[i], tex2)*Weights2[i];
    }
    result += Weights2[68];
    result += Weights2[69]*tex2.x;
    result += Weights2[70]*tex2.y;
    return result;
}

void main()
{
    gl_Position = Position;
    TexCoordVarying1 = calcTexOffset1(TexCoord1.xy);
    TexCoordVarying2 = calcTexOffset2(TexCoord2.xy);
}
