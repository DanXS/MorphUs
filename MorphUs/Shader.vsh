attribute vec4 Position;
attribute vec2 TexCoord1;
attribute vec2 TexCoord2;

uniform vec2 Weights1[84];
uniform vec2 Weights2[84];
uniform vec2 InterpMarkers[81];

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
    for(int i = 0; i < 81; i++)
    {
        result += tps(InterpMarkers[i], tex1)*Weights1[i];
    }
    result += Weights1[81];
    result += Weights1[82]*tex1.x;
    result += Weights1[83]*tex1.y;
    return result;
}

highp vec2 calcTexOffset2(highp vec2 tex2)
{
    vec2 result = vec2(0, 0);
    for(int i = 0; i < 81; i++)
    {
        result += tps(InterpMarkers[i], tex2)*Weights2[i];
    }
    result += Weights2[81];
    result += Weights2[82]*tex2.x;
    result += Weights2[83]*tex2.y;
    return result;
}

void main()
{
    gl_Position = Position;
    TexCoordVarying1 = calcTexOffset1(TexCoord1.xy);
    TexCoordVarying2 = calcTexOffset2(TexCoord2.xy);
}