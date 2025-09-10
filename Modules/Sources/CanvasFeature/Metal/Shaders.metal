#include <metal_stdlib>
#include <metal_math>
using namespace metal;

struct MTLTextureViewVertexOut {
  float4 position [[ position ]];
  float2 uv;
};

vertex MTLTextureViewVertexOut vertexFunc(uint vid [[vertex_id]]) {
  MTLTextureViewVertexOut out;
  
  const float2 vertices[] = {
    float2(-1.0f, 1.0f),
    float2(-1.0f, -1.0f),
    float2(1.0f, 1.0f),
    float2(1.0f, -1.0f)
  };
  
  out.position = float4(vertices[vid], 0.0, 1.0);
  float2 uv = vertices[vid];
  uv.y = -uv.y;
  out.uv = fma(uv, 0.5f, 0.5f);
  
  return out;
}

fragment half4 fragmentFunc(MTLTextureViewVertexOut in [[stage_in]],
                            texture2d<half, access::sample> image [[texture(0)]])
{
  constexpr sampler s(coord::normalized,
                      address::clamp_to_zero,
                      filter::linear);
  return image.sample(s, in.uv);
}


fragment half4 fragmentDrawingFunc(MTLTextureViewVertexOut in [[stage_in]],
                            texture2d<half, access::sample> image [[texture(0)]],
                            texture2d<half, access::sample> drawing [[texture(1)]])
{
  constexpr sampler s(coord::normalized,
                      address::clamp_to_zero,
                      filter::linear);

  half4 imagelColor = image.sample(s, in.uv);
  half4 drawColor = drawing.sample(s, in.uv);
  return mix(imagelColor, drawColor, 1 * drawColor.a);
}

fragment half4 fragmentBlurringFunc(MTLTextureViewVertexOut in [[stage_in]],
                            texture2d<half, access::sample> image [[texture(0)]],
                            texture2d<half, access::sample> blur [[texture(1)]],
                            texture2d<half, access::sample> drawing [[texture(2)]])
{
  constexpr sampler s(coord::normalized,
                      address::clamp_to_zero,
                      filter::linear);

  half4 imagelColor = image.sample(s, in.uv);
  half4 blurColor = blur.sample(s, in.uv);
  half4 drawColor = drawing.sample(s, in.uv);

  return mix(imagelColor, blurColor, 1 * drawColor.a);
}

fragment half4 fragmentErasingFunc(MTLTextureViewVertexOut in [[stage_in]],
                            texture2d<half, access::sample> clear [[texture(0)]],
                            texture2d<half, access::sample> image [[texture(1)]],
                            texture2d<half, access::sample> drawing [[texture(2)]])
{
  constexpr sampler s(coord::normalized,
                      address::clamp_to_zero,
                      filter::linear);

  half4 clearColor = clear.sample(s, in.uv);
  half4 imageColor = image.sample(s, in.uv);
  half4 drawColor = drawing.sample(s, in.uv);

  return mix(imageColor, clearColor, 1 * drawColor.a);
}
