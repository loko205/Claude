// Warm/cool light pools (lamps, flashlight, searchlight) added on top of the two-tone shading, for world materials
// and character cards alike. Up to 8 pools, set per frame: pos.xyz + radius, colour (linear, can exceed 1).
import * as THREE from "three";
export const NP = 8;
export const POOLS = {
  uPoolP: { value: Array.from({ length: NP }, () => new THREE.Vector4(0, -999, 0, 0.001)) },
  uPoolC: { value: Array.from({ length: NP }, () => new THREE.Color(0, 0, 0)) },
};
export const clearPools = () => { for (let i = 0; i < NP; i++) { POOLS.uPoolP.value[i].set(0, -999, 0, 0.001); POOLS.uPoolC.value[i].setRGB(0, 0, 0); } };
let pi = 0;
export const resetPools = () => { clearPools(); pi = 0; };
export const pool = (x: number, y: number, z: number, r: number, c: THREE.ColorRepresentation, k = 1) => {
  if (pi >= NP) return; POOLS.uPoolP.value[pi].set(x, y, z, r); POOLS.uPoolC.value[pi].set(c).multiplyScalar(k); pi++;
};
const DECL = `\nuniform vec4 uPoolP[${NP}]; uniform vec3 uPoolC[${NP}]; varying vec3 vPW;\n`;
export function poolify<T extends THREE.Material>(m: T, key = "p"): T {
  const prev = m.onBeforeCompile, prevKey = m.customProgramCacheKey?.bind(m);
  m.onBeforeCompile = (sh, r) => {
    prev.call(m, sh, r);
    sh.uniforms.uPoolP = POOLS.uPoolP; sh.uniforms.uPoolC = POOLS.uPoolC;
    sh.vertexShader = sh.vertexShader.replace("#include <common>", "#include <common>\nvarying vec3 vPW;")
      .replace("#include <project_vertex>", `#include <project_vertex>
      { vec4 wp = vec4( transformed, 1.0 );
      #ifdef USE_INSTANCING
        wp = instanceMatrix * wp;
      #endif
        vPW = ( modelMatrix * wp ).xyz; }`);
    sh.fragmentShader = sh.fragmentShader.replace("#include <common>", "#include <common>" + DECL)
      .replace("#include <opaque_fragment>", `
      for ( int i = 0; i < ${NP}; i ++ ) { vec4 P = uPoolP[ i ]; float k = 1.0 - smoothstep( 0.0, P.w, distance( vPW, P.xyz ) ); outgoingLight += diffuseColor.rgb * uPoolC[ i ] * k * k; }
      #include <opaque_fragment>`);
  };
  m.customProgramCacheKey = () => (prevKey ? prevKey() : "") + "_pool_" + key;
  return m;
}
