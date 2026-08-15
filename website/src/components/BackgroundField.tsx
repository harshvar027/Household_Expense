import { useEffect, useMemo, useRef, type ReactNode } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Float, Grid } from '@react-three/drei';
import * as THREE from 'three';
import { useTheme } from '../context/ThemeContext';
import { prefersReducedMotion } from '../lib/motion';

function usePointer() {
  const pointer = useRef({ x: 0, y: 0 });
  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      pointer.current.x = (e.clientX / window.innerWidth) * 2 - 1;
      pointer.current.y = (e.clientY / window.innerHeight) * 2 - 1;
    };
    window.addEventListener('mousemove', onMove, { passive: true });
    return () => window.removeEventListener('mousemove', onMove);
  }, []);
  return pointer;
}

function Rig({ children }: { children: ReactNode }) {
  const ref = useRef<THREE.Group>(null);
  const pointer = usePointer();

  useFrame((_, delta) => {
    if (!ref.current) return;
    const k = 1 - Math.exp(-delta * 2.4);
    ref.current.rotation.y += (pointer.current.x * 0.18 - ref.current.rotation.y) * k;
    ref.current.rotation.x += (-pointer.current.y * 0.1 - ref.current.rotation.x) * k;
  });

  return <group ref={ref}>{children}</group>;
}

function Dust({ count, color }: { count: number; color: string }) {
  const ref = useRef<THREE.Points>(null);
  const positions = useMemo(() => {
    const arr = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      arr[i * 3] = (Math.random() - 0.5) * 16;
      arr[i * 3 + 1] = (Math.random() - 0.2) * 8;
      arr[i * 3 + 2] = (Math.random() - 0.5) * 12 - 1;
    }
    return arr;
  }, [count]);

  useFrame((_, delta) => {
    if (ref.current) ref.current.rotation.y += delta * 0.018;
  });

  return (
    <points ref={ref}>
      <bufferGeometry>
        <bufferAttribute attach="attributes-position" args={[positions, 3]} />
      </bufferGeometry>
      <pointsMaterial
        size={0.028}
        color={color}
        transparent
        opacity={0.45}
        sizeAttenuation
        depthWrite={false}
      />
    </points>
  );
}

function Crystal({
  position,
  color,
  scale = 1,
  type = 'octa',
}: {
  position: [number, number, number];
  color: string;
  scale?: number;
  type?: 'octa' | 'ico' | 'torus';
}) {
  return (
    <Float speed={1.1} rotationIntensity={0.45} floatIntensity={0.7}>
      <mesh position={position} scale={scale}>
        {type === 'torus' ? (
          <torusGeometry args={[0.55, 0.012, 12, 64]} />
        ) : type === 'ico' ? (
          <icosahedronGeometry args={[0.42, 0]} />
        ) : (
          <octahedronGeometry args={[0.38, 0]} />
        )}
        <meshStandardMaterial
          color={color}
          emissive={color}
          emissiveIntensity={0.4}
          metalness={0.55}
          roughness={0.28}
          wireframe
          transparent
          opacity={0.85}
        />
      </mesh>
    </Float>
  );
}

function Scene({ isDark }: { isDark: boolean }) {
  const mint = isDark ? '#3cefb0' : '#0e7a68';
  const amber = isDark ? '#e8c36a' : '#c4921a';
  const cyan = isDark ? '#7ee0d0' : '#3d8f86';
  const cell = isDark ? '#1a3d34' : '#b7c9c0';
  const section = isDark ? '#2a8f74' : '#0c6b5c';
  const count = typeof window !== 'undefined' && window.innerWidth < 768 ? 220 : 420;

  return (
    <>
      <ambientLight intensity={isDark ? 0.35 : 0.7} />
      <pointLight position={[4, 3, 2]} intensity={isDark ? 1.1 : 0.85} color={mint} />
      <pointLight position={[-5, 1, -2]} intensity={0.55} color={amber} />
      <Rig>
        <Grid
          infiniteGrid
          fadeDistance={22}
          fadeStrength={1.35}
          sectionSize={2}
          sectionThickness={0.85}
          cellSize={0.5}
          cellThickness={0.4}
          cellColor={cell}
          sectionColor={section}
          position={[0, -2.05, 0]}
        />
        <Crystal position={[-2.4, 0.35, -1.2]} color={mint} type="octa" />
        <Crystal position={[2.8, 0.9, -0.6]} color={amber} type="ico" scale={1.15} />
        <Crystal position={[0.2, 1.35, -2.1]} color={cyan} type="torus" scale={1.4} />
        <Crystal position={[-1.1, -0.4, 0.8]} color={mint} type="ico" scale={0.7} />
        <Dust count={count} color={mint} />
      </Rig>
    </>
  );
}

export default function BackgroundField() {
  const { isDark } = useTheme();
  if (prefersReducedMotion()) return null;

  return (
    <div className="pointer-events-none fixed inset-0 -z-0" aria-hidden>
      <Canvas
        dpr={[1, 1.25]}
        camera={{ position: [0, 1.1, 7.2], fov: 42 }}
        gl={{ antialias: false, alpha: true, premultipliedAlpha: false, powerPreference: 'low-power' }}
        onCreated={({ gl }) => {
          gl.setClearColor(0x000000, 0);
          gl.setClearAlpha(0);
        }}
        style={{ width: '100%', height: '100%', background: 'transparent' }}
      >
        <Scene isDark={isDark} />
      </Canvas>
    </div>
  );
}
