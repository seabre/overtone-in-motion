float hue2rgb(float p, float q, float t)
{
  if(t < 0.0) t += 1.0;
  if(t > 1.0) t -= 1.0;
  if(t < 1.0/6.0) return p + (q - p) * 6.0 * t;
  if(t < 1.0/2.0) return q;
  if(t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
  return p;
}

vec3 hslToRgb(float h, float s, float l)
{
    vec3 rgb;
    if(s == 0.0)
  {
        rgb = vec3( l );
    }
  else
  {
        float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
        float p = 2.0 * l - q;
        rgb = vec3( hue2rgb(p, q, h + 0.33333), hue2rgb(p, q, h), hue2rgb(p, q, h - 0.33333) );
    }

    return rgb;
}

float intersectAuroraPlane( vec3 ro, vec3 rd, float planeZ )
{
  return ( -ro.z + planeZ ) / rd.z;
}

float intersectWaterPlane( vec3 ro, vec3 rd, float waterY )
{
  return ( -ro.y + waterY ) / rd.y;
}

// Clasic Perlin noise functions copied from the internet...

vec3 mod289(vec3 x) 
{
    return x - floor(x * (1.0 / 289.0)) * 289.0;
} 

vec4 mod289(vec4 x)
{
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}
 
vec4 permute(vec4 x)
{
    return mod289(((x*34.0)+1.0)*x);
}
 
vec4 taylorInvSqrt(vec4 r)
{
    return 1.79284291400159 - 0.85373472095314 * r;
}
 
vec2 fade(vec2 t) {
    return t*t*t*(t*(t*6.0-15.0)+10.0);
}

vec3 fade(vec3 t) {
  return t*t*t*(t*(t*6.0-15.0)+10.0);
}

float cnoise(vec3 P)
{
  vec3 Pi0 = floor(P); // Integer part for indexing
  vec3 Pi1 = Pi0 + vec3(1.0); // Integer part + 1
  Pi0 = mod289(Pi0);
  Pi1 = mod289(Pi1);
  vec3 Pf0 = fract(P); // Fractional part for interpolation
  vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
  vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  vec4 iy = vec4(Pi0.yy, Pi1.yy);
  vec4 iz0 = Pi0.zzzz;
  vec4 iz1 = Pi1.zzzz;

  vec4 ixy = permute(permute(ix) + iy);
  vec4 ixy0 = permute(ixy + iz0);
  vec4 ixy1 = permute(ixy + iz1);

  vec4 gx0 = ixy0 * (1.0 / 7.0);
  vec4 gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
  gx0 = fract(gx0);
  vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
  vec4 sz0 = step(gz0, vec4(0.0));
  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
  gy0 -= sz0 * (step(0.0, gy0) - 0.5);

  vec4 gx1 = ixy1 * (1.0 / 7.0);
  vec4 gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
  gx1 = fract(gx1);
  vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
  vec4 sz1 = step(gz1, vec4(0.0));
  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
  gy1 -= sz1 * (step(0.0, gy1) - 0.5);

  vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
  vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
  vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
  vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
  vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
  vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
  vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
  vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);

  vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;

  float n000 = dot(g000, Pf0);
  float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
  float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
  float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
  float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
  float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
  float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
  float n111 = dot(g111, Pf1);

  vec3 fade_xyz = fade(Pf0);
  vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
  vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
  float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x); 
  return 2.2 * n_xyz;
}

float FBM( vec2 uv, float z )
{
  float lacunarity = 2.0;
  float gain = 0.25;
    float amplitude = 1.0;
    float frequency = 1.0;
    float sum = 0.0;
    for(int i = 0; i < 4; ++i)
    {
        sum += amplitude * cnoise(vec3( uv * frequency, z ));
        amplitude *= gain;
        frequency *= lacunarity;
    }
    return sum;
}

float calcAurora( vec3 ro, vec3 rd, out vec3 pt, out vec3 color )
{
  float angle = 1.0;
  vec3 aro = ro;
  vec3 ard = rd;
  
  float at = intersectAuroraPlane( aro, ard, 1.0 );
  pt = aro + at * ard;
  
  vec2 uv = pt.xy - vec2( -0.5, 0.7 );
  
  vec3 fft = hslToRgb( 
    uv.y * 0.4 - 0.05 + texture2D( iChannel1, vec2( uv.x * 0.05 + iGlobalTime * 0.002, 0.0 ) ).x * 0.1
    , .5, .5 ) * 0.95;
  
  fft *= texture2D( iChannel0, vec2( mod( abs( uv.x ) * 0.35, 1.0 ), 0.0 ) ).xyz * 0.3
    +  texture2D( iChannel0, vec2( mod( abs( uv.x * 0.1 ) * 0.35, 1.0 ), 0.0 ) ).xyz * 0.7;
  float dist = 1.0 - min( 1.0, max( 0.0, length( vec2( 0.5, 0.2 ) - uv ) * 0.8 ) );
  color = vec3( fft ) * smoothstep( 0.0, 1.0, dist );
  
  vec3 stars = vec3( 0.0, 0.1, 0.2 );
  for( float i = 0.0; i < 60.0; i+=1.0 ) 
  {
    vec3 star = texture2D( iChannel1, vec2( i * 0.03, 0.1 ) ).xyz; // 0-1;0-1
    star.x = mod( star.x - iGlobalTime * 0.0015 * (texture2D( iChannel1, vec2( i * 0.03, 0.0 ) ).x * 3.0 + 1.0)
           , 1.0 );
    star.x -= 0.3;
    star.x *= 2.3;
    star.z = ( star.z * 0.6 + 0.4 ) * 300.0;
    float lumi = smoothstep( 0.0, 1.0, max( 0.0, min( 1.0, ( 1.1 - length( uv - star.xy ) * star.z ) ) ) ) * 0.8 *
      abs( sin( iGlobalTime * 0.1 * (1.0+i*0.111) ) * texture2D( iChannel1, vec2( i * 0.3, 0.0 ) ).x * 0.6 );
      
    stars += vec3( min( vec3( 1.0, 1.0, 1.0 ), color + vec3( 0.5,0.5,0.5 ) ) * lumi );
  }
  color += stars;
  // pseudo landscape
  color *= clamp( (uv.y*3.0-FBM(uv * 10.0, 0.) * .2) * 50.0 - 10.0, 0.0, 1.0 );
  
  return at;
}

float pattern( vec2 uv )
{
  return FBM( uv, iGlobalTime );
}

vec3 colorize( vec2 uv, vec3 ro, vec3 rd )
{
  // aurora
  vec3 aurora = vec3(0.0,0.0,0.0);
  vec3 apt = vec3(0.0,0.0,0.0);
  float at = calcAurora( ro, rd, apt, aurora );
  
  // water
  float waterH = 0.7;
  if ( apt.y < waterH )
  {
    float wt = intersectWaterPlane( ro, rd, waterH );
    {
      vec3 wpt = ro + wt * rd;
      vec2 uvfbm = uv * 100.0;
      uvfbm.y *= 1.5;
      uvfbm.y += iGlobalTime * 0.1;
      vec2 disturb = vec2( pattern( uvfbm ), pattern( uvfbm + vec2( 5.2, 1.3 ) ) );
      disturb *= 0.1;
      vec3 normal = normalize( vec3( disturb.x, 1.0, disturb.y ) );
      vec3 R = reflect( normalize( -rd ), normal );
      at = calcAurora( wpt, R, apt, aurora );
    }
  }
  
  return aurora;
}

void main(void)
{
  vec2 uv = gl_FragCoord.xy / iResolution.xy;
  
  vec3 ro = vec3( 0.0, 1.0, -0.2 );
  vec3 rd = vec3( uv - vec2(0.5, 0.5), 1.0 );
  rd.x *= iResolution.x / iResolution.y;
  
  vec3 color = colorize( uv, ro, rd );
  
  gl_FragColor = vec4(color,1.0);
}
