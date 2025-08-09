//
//  Shaders.metal
//  Cheesery iOS
//
//  Created by Menno Spijker on 09/08/2025.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 uv       [[attribute(1)]];
};

struct InstanceData {
    float2 position;
    float  scale;
    float  rotation;
    float4 color;
};

struct VSOut {
    float4 position [[position]];
    float2 uv;
    float4 color;
};

vertex VSOut vs_main(
    const device VertexIn*      verts   [[buffer(0)]],
    constant float2&            viewport[[buffer(1)]],
    const device InstanceData*  insts   [[buffer(2)]],
    uint vid [[vertex_id]],
    uint iid [[instance_id]]
) {
    VertexIn v = verts[vid];
    InstanceData inst = insts[iid];

    // rotate & scale quad in pixel space
    float2 p = v.position * inst.scale * 42.0; // 42 px base size; tweak if you want
    float s = sin(inst.rotation);
    float c = cos(inst.rotation);
    float2 pr = float2(
        p.x * c - p.y * s,
        p.x * s + p.y * c
    );

    // move to instance center (pixels) then to NDC
    float2 pixel = inst.position + pr;
    float2 ndc = float2(
        (pixel.x / viewport.x) * 2.0 - 1.0,
        (pixel.y / viewport.y) * 2.0 - 1.0
    );

    VSOut o;
    // Metal's y is +up; UIKit coord is +down, so flip
    o.position = float4(ndc.x, -ndc.y, 0, 1);
    o.uv = v.uv;
    o.color = inst.color;
    return o;
}

fragment float4 fs_main(VSOut in [[stage_in]],
                        texture2d<float> tex [[texture(0)]])
{
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 c = tex.sample(s, in.uv);
    return float4(c.rgb, c.a) * in.color;
}
