import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { loadFont } from "@remotion/google-fonts/Cairo";

const { fontFamily } = loadFont();

// Brand palette (Sudan-flag dark theme, matches the Flutter app).
const AMBER = "#FFB000";
const GOLD = "#FFD700";
const GREEN = "#007A3D";
const BG = "#0A0A0A";

// Approximate, recognizable Sudan silhouette in a 0..1000 coordinate box.
// Flat northern (Egypt) border, Red Sea coast + Hala'ib jut (NE), Ethiopia/
// Eritrea frontier (SE), South-Sudan border (S), Darfur bulge to Chad (W).
const SUDAN_PATH =
  "M250 150 L770 150 L815 250 L875 270 L835 360 L700 480 L665 560 " +
  "L705 620 L650 700 L615 765 L510 800 L430 775 L360 805 L295 760 " +
  "L235 690 L150 565 L120 430 L185 330 L215 235 Z";

// Map placement inside the 1080x1920 frame.
const MAP_SCALE = 0.72;
const MAP_X = 180;
const MAP_Y = 560;

// Pin tip / portal origin in screen coords (≈ map centroid).
const PX = MAP_X + 470 * MAP_SCALE; // 518.4
const PY = MAP_Y + 470 * MAP_SCALE; // 898.4

export const SudanOnboarding: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();

  // ── Phase A: opening logo ──
  const logoIn = interpolate(frame, [0, 16], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: (t) => 1 - Math.pow(1 - t, 3),
  });
  const logoOut = interpolate(frame, [30, 44], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const logoOpacity = logoIn * logoOut;
  const logoScale = interpolate(logoIn, [0, 1], [0.8, 1]);

  // ── Phase C: map draw ──
  const drawProgress = interpolate(frame, [18, 62], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: (t) => 1 - Math.pow(1 - t, 2),
  });
  const mapGlow = interpolate(frame, [18, 40], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // ── Phase D: pin pop (spring) ──
  const pinSpring = spring({
    frame: frame - 58,
    fps,
    config: { damping: 9, mass: 0.8, stiffness: 140 },
  });
  const pinScale = interpolate(pinSpring, [0, 1], [0, 1]);

  // ── Phase F: portal zoom ──
  const portalProgress = interpolate(frame, [96, 128], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: (t) => t * t,
  });
  const maxRadius = Math.hypot(
    Math.max(PX, width - PX),
    Math.max(PY, height - PY),
  ) + 80;
  const portalRadius = portalProgress * maxRadius;

  // Pin fades as the portal swallows it.
  const pinOpacity = interpolate(frame, [96, 112], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // ── Phase G: final brand on green ──
  const brandIn = interpolate(frame, [120, 138], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: (t) => 1 - Math.pow(1 - t, 3),
  });
  const brandY = interpolate(brandIn, [0, 1], [24, 0]);

  return (
    <AbsoluteFill style={{ backgroundColor: BG, fontFamily }}>
      {/* Warm radial glow behind the map */}
      <AbsoluteFill
        style={{
          opacity: mapGlow * 0.7 * (1 - portalProgress),
          background: `radial-gradient(circle at ${PX}px ${PY}px, rgba(255,176,0,0.22), transparent 45%)`,
        }}
      />

      {/* Opening logo */}
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          opacity: logoOpacity,
        }}
      >
        <div style={{ transform: `scale(${logoScale})`, textAlign: "center" }}>
          <div
            style={{
              fontSize: 150,
              fontWeight: 800,
              color: AMBER,
              textShadow: "0 0 40px rgba(255,176,0,0.6)",
            }}
          >
            سوقنا
          </div>
          <div style={{ fontSize: 42, color: "#EDEDED", marginTop: 8 }}>
            كل ما تحتاجه في مكان واحد
          </div>
        </div>
      </AbsoluteFill>

      {/* Map + pin + ripples (SVG, aligned by screen coordinates) */}
      <AbsoluteFill style={{ opacity: 1 - portalProgress }}>
        <svg
          width={width}
          height={height}
          viewBox={`0 0 ${width} ${height}`}
          style={{ filter: `drop-shadow(0 0 18px rgba(255,176,0,${0.85 * mapGlow}))` }}
        >
          <g transform={`translate(${MAP_X},${MAP_Y}) scale(${MAP_SCALE})`}>
            <path
              d={SUDAN_PATH}
              fill={`rgba(255,176,0,${0.06 * drawProgress})`}
              stroke={AMBER}
              strokeWidth={6 / MAP_SCALE}
              strokeLinejoin="round"
              strokeLinecap="round"
              pathLength={1}
              strokeDasharray={1}
              strokeDashoffset={1 - drawProgress}
            />
          </g>

          {/* Ripples from the pin */}
          {[0, 1, 2].map((i) => {
            const start = 72 + i * 8;
            const p = interpolate(frame, [start, start + 26], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            });
            if (p <= 0 || p >= 1) return null;
            return (
              <circle
                key={i}
                cx={PX}
                cy={PY}
                r={p * 240}
                fill="none"
                stroke={GOLD}
                strokeWidth={4}
                opacity={(1 - p) * 0.6 * pinOpacity}
              />
            );
          })}

          {/* Location pin (tip at PX,PY) */}
          <g
            transform={`translate(${PX},${PY - 20}) scale(${pinScale})`}
            opacity={pinOpacity}
            style={{ filter: "drop-shadow(0 0 22px rgba(255,176,0,0.95))" }}
          >
            <path
              d="M0,20 C-26,-14 -26,-46 0,-46 C26,-46 26,-14 0,20 Z"
              fill={AMBER}
            />
            <circle cx={0} cy={-40} r={11} fill={BG} />
          </g>
        </svg>
      </AbsoluteFill>

      {/* Portal disc that fills the screen with brand green */}
      <AbsoluteFill>
        <svg width={width} height={height}>
          <circle cx={PX} cy={PY} r={portalRadius} fill={GREEN} />
        </svg>
      </AbsoluteFill>

      {/* Final brand reveal on green */}
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          opacity: brandIn,
        }}
      >
        <div style={{ transform: `translateY(${brandY}px)`, textAlign: "center" }}>
          <div style={{ fontSize: 160, fontWeight: 800, color: "#FFFFFF" }}>
            سوقنا
          </div>
          <div style={{ fontSize: 44, color: "rgba(255,255,255,0.92)", marginTop: 4 }}>
            كل ما تحتاجه في مكان واحد
          </div>
          <div
            style={{
              width: 90,
              height: 6,
              borderRadius: 3,
              backgroundColor: GOLD,
              margin: "26px auto 0",
            }}
          />
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
