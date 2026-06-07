import "./index.css";
import { Composition } from "remotion";
import { SudanOnboarding } from "./SudanOnboarding";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="SudanOnboarding"
        component={SudanOnboarding}
        durationInFrames={150}
        fps={30}
        width={1080}
        height={1920}
      />
    </>
  );
};
