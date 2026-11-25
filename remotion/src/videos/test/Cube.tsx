import React, { useMemo, useEffect } from "react";
import { ThreeCanvas } from "@remotion/three";
import { useThree, useFrame } from "@react-three/fiber";
import { EffectComposer, RenderPass, EffectPass, ToneMappingEffect, ToneMappingMode, BloomEffect } from "postprocessing";
import { AbsoluteFill, useCurrentFrame } from "remotion";
const Post: React.FC = () => { const { gl, scene, camera, size } = useThree();
  const comp = useMemo(() => { const c = new EffectComposer(gl); c.addPass(new RenderPass(scene, camera)); c.addPass(new EffectPass(camera, new BloomEffect(), new ToneMappingEffect({ mode: ToneMappingMode.NEUTRAL }))); return c; }, [gl, scene, camera]);
  useEffect(() => { comp.setSize(size.width, size.height); }, [comp, size]);
  useFrame(() => { comp.render(); }, 1); return null; };
export const Cube: React.FC = () => { const f = useCurrentFrame();
 return <AbsoluteFill style={{background:"#222"}}><ThreeCanvas width={1080} height={1920} camera={{position:[0,0,5]}}>
  <ambientLight intensity={0.5}/><directionalLight position={[2,3,4]}/>
  <mesh rotation={[f*0.05,f*0.07,0]}><boxGeometry args={[1.5,1.5,1.5]}/><meshStandardMaterial color="orange"/></mesh>
  <Post/>
 </ThreeCanvas></AbsoluteFill>; };
