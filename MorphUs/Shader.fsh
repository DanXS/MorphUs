uniform sampler2D SamplerUV1;
uniform sampler2D SamplerUV2;
uniform highp float Alpha;

varying highp vec2 TexCoordVarying1;
varying highp vec2 TexCoordVarying2;

void main()
{
    lowp vec3 rgb1 = texture2D(SamplerUV1, TexCoordVarying1).rgb;
    lowp vec3 rgb2 = texture2D(SamplerUV2, TexCoordVarying2).rgb;
    lowp vec3 rgb = (1.0-Alpha)*rgb1+Alpha*rgb2;
    gl_FragColor = vec4(rgb, 1);
}