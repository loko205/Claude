import React from "react";
import { Composition } from "remotion";
import { BAShort, BA_FRAMES } from "./videos/ba5390/Short";
import { AlcatrazShort, AZ_FRAMES } from "./videos/alcatraz/Short";
import { Sheet } from "./videos/ba5390/Sheet";
import { Cube } from "./videos/test/Cube";
import { BridgeShort, BRIDGE_FRAMES } from "./videos/bridge/Bridge";
export const Root: React.FC = () => (<>
  <Composition id="BridgeShort" component={BridgeShort} durationInFrames={BRIDGE_FRAMES} fps={30} width={1080} height={1920} />
  <Composition id="Cube" component={Cube} durationInFrames={60} fps={30} width={1080} height={1920} />
  <Composition id="Sheet" component={Sheet} durationInFrames={1} fps={30} width={1080} height={1920} />
  <Composition id="BA5390" component={BAShort} durationInFrames={BA_FRAMES} fps={30} width={1080} height={1920} />
  <Composition id="Alcatraz" component={AlcatrazShort} durationInFrames={AZ_FRAMES} fps={30} width={1080} height={1920} />
</>);
