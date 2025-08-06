#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Added for crate rendering
struct CrateData {
    float2 position;
    float rotation;
    float scale;
};

vertex VertexOut bierVertex(uint vertexID [[vertex_id]],
                             constant float4 *vertices [[buffer(0)]]) {
    VertexOut out;
    float4 position = vertices[vertexID];
    
    out.position = float4(position.xy, 0.0, 1.0);
    out.texCoord = position.zw;
    
    return out;
}

fragment float4 bierFragment(VertexOut in [[stage_in]],
                           constant float &time [[buffer(0)]],
                           constant CrateData *crates [[buffer(1)]],
                           constant int &crateCount [[buffer(2)]]) {
    float2 uv = in.texCoord;
    
    // Base beer color - amber/golden
    float3 bierKleur = float3(0.98, 0.69, 0.09);
    
    // Create foam at the top
    float foam = smoothstep(0.75, 0.85, uv.y);
    
    // Create bubbles
    float bubbles = 0.0;
    for (int i = 0; i < 10; i++) {
        // Bubble position (moving upward)
        float speed = 0.2 + float(i) * 0.03;
        float size = 0.003 + float(i) * 0.002;
        float bubbleOffset = float(i) * 12.345;
        
        // X position with some randomness
        float bubbleX = 0.1 + 0.8 * fract(sin(float(i) * 1.23) * 43758.5453);
        // Y position that moves upward
        float bubbleY = fract(uv.y - time * speed + bubbleOffset);
        
        // Create the bubble
        float d = length(float2(uv.x - bubbleX, fract(uv.y - time * speed + bubbleOffset) - 0.5));
        bubbles += smoothstep(size, size * 0.5, d) * 0.5;
    }
    
    // Add a simple wave to the beer surface
    float wave = sin(uv.x * 10.0 + time * 2.0) * 0.01 * smoothstep(0.7, 0.8, uv.y);
    float beerSurface = smoothstep(0.79 + wave, 0.81 + wave, uv.y);
    
    // Combine effects
    float3 color = bierKleur;
    
    // Add bubbles (brighter)
    color = mix(color, float3(0.9, 0.85, 0.6), bubbles * (1.0 - foam) * 0.7);
    
    // Add foam (white)
    color = mix(color, float3(0.95, 0.92, 0.8), foam);
    
    // Make beer darker at the bottom
    color = mix(color, bierKleur * 0.7, (1.0 - uv.y) * 0.4);
    
    // Darker beer at the edges for glass effect
    float edge = smoothstep(0.0, 0.1, uv.x) * smoothstep(1.0, 0.9, uv.x);
    color *= 0.8 + edge * 0.2;
    
    // Draw crates in the beer
    for(int i = 0; i < crateCount && i < 12; i++) {
        float2 cratePos = crates[i].position;
        float rotation = crates[i].rotation;
        float crateScale = crates[i].scale;
        
        // Size of the crate - make it clearly visible
        float2 crateSize = float2(0.25, 0.25) * crateScale;
        
        // Apply rotation to the UV coordinates
        float2 rotatedUV = uv - cratePos;
        float sinR = sin(rotation);
        float cosR = cos(rotation);
        float2 rotUV = float2(
            rotatedUV.x * cosR - rotatedUV.y * sinR,
            rotatedUV.x * sinR + rotatedUV.y * cosR
        );
        
        // Check if the current pixel is within the crate boundaries
        if (abs(rotUV.x) < crateSize.x && abs(rotUV.y) < crateSize.y) {
            // Create a simple crate pattern
            float2 normalizedCrateUV = (rotUV + crateSize) / (crateSize * 2.0);
            
            // Simple wooden crate pattern
            float gridX = step(0.33, normalizedCrateUV.x) - step(0.67, normalizedCrateUV.x);
            gridX += step(0.67, normalizedCrateUV.x);
            float gridY = step(0.33, normalizedCrateUV.y) - step(0.67, normalizedCrateUV.y);
            gridY += step(0.67, normalizedCrateUV.y);
            
            // Dark brown for the grid lines
            float3 gridColor = float3(0.3, 0.15, 0.05);
            
            // Light brown for the wood panels
            float3 woodColor = float3(0.6, 0.35, 0.15);
            
            // Create the crate appearance with grid pattern
            float3 crateColor = mix(woodColor, gridColor, (1.0-gridX) * (1.0-gridY) * 0.8);
            
            // Add the crate color to the beer (with high visibility)
            color = mix(color, crateColor, 0.95);
        }
    }
    return float4(color, 1.0);
}
