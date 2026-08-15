import { useEffect, useMemo, useRef, useState } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Float } from '@react-three/drei';
import * as THREE from 'three';
import { useTheme } from '../context/ThemeContext';

function useBudget() {
  const [budget, setBudget] = useState({ particles: 1400, dprMax: 1.5 });
  useEffect(() => {
    const narrow = window.matchMedia('(max-width: 767px)').matches;
    const coarse = window.matchMedia('(pointer: coarse)').matches;
    if (narrow && coarse) setBudget({ particles: 480, dprMax: 1 });
    else if (narrow || coarse) setBudget({ particles: 800, dprMax: 1.2 });
  }, []);
  return budget;
}

function Particles({ count, color }: { count: number; color: string }) {
  const ref = useRef<THREE.Points>(null);
  const positions = useMemo(() => {
    const arr = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      const r = 5.5 + Math.random() * 8;
      const theta = Math.random() * Math.PI * 2;
      const phi = Math.acos(2 * Math.random() - 1);
      arr[i * 3] = r * Math.sin(phi) * Math.cos(theta);
      arr[i * 3 + 1] = r * Math.sin(phi) * Math.sin(theta) * 0.5;
      arr[i * 3 + 2] = r * Math.cos(phi) - 3.5;
    }
    return arr;
  }, [count]);

  useFrame((state, delta) => {
    if (!ref.current) return;
    ref.current.rotation.y += delta * 0.03;
    ref.current.rotation.x += (state.pointer.y * 0.1 - ref.current.rotation.x) * 0.04;
    ref.current.rotation.z += (state.pointer.x * 0.08 - ref.current.rotation.z) * 0.03;
  });

  return (
    <points ref={ref}>
      <bufferGeometry>
        <bufferAttribute attach="attributes-position" args={[positions, 3]} />
      </bufferGeometry>
      <pointsMaterial
        size={0.034}
        color={color}
        transparent
        opacity={0.62}
        sizeAttenuation
        depthWrite={false}
      />
    </points>
  );
}

function VaultOrb({ isDark }: { isDark: boolean }) {
  const mesh = useRef<THREE.Mesh>(null);
  useFrame((_, delta) => {
    if (!mesh.current) return;
    mesh.current.rotation.y += delta * 0.35;
    mesh.current.rotation.x += delta * 0.12;
  });

  const wire = isDark ? '#3cefb0' : '#0e7a68';
  const glow = isDark ? '#7ee0d0' : '#c4921a';

  return (
    <Float speed={1.4} rotationIntensity={0.35} floatIntensity={0.8}>
      <mesh ref={mesh} position={[2.15, 0.15, 0]}>
        <icosahedronGeometry args={[1.15, 1]} />
        <meshStandardMaterial
          color={wire}
          emissive={wire}
          emissiveIntensity={isDark ? 0.55 : 0.35}
          metalness={0.72}
          roughness={0.22}
          wireframe
        />
      </mesh>
      <mesh position={[2.15, 0.15, 0]}>
        <icosahedronGeometry args={[0.72, 0]} />
        <meshStandardMaterial
          color={glow}
          emissive={glow}
          emissiveIntensity={0.35}
          metalness={0.4}
          roughness={0.35}
          transparent
          opacity={0.35}
        />
      </mesh>
    </Float>
  );
}

function clearTransparent(gl: THREE.WebGLRenderer) {
  gl.setClearColor(0x000000, 0);
  gl.setClearAlpha(0);
}

export default function HeroScene() {
  const budget = useBudget();
  const { isDark } = useTheme();
  const particle = isDark ? '#3cefb0' : '#0e7a68';

  return (
    <Canvas
      dpr={[1, budget.dprMax]}
      camera={{ position: [0, 0.2, 6.2], fov: 42 }}
      gl={{ antialias: true, alpha: true, premultipliedAlpha: false }}
      onCreated={({ gl }) => clearTransparent(gl)}
      style={{ width: '100%', height: '100%', background: 'transparent' }}
    >
      <ambientLight intensity={isDark ? 0.4 : 0.85} />
      <directionalLight position={[4, 3, 2]} intensity={isDark ? 1.15 : 0.95} color={particle} />
      <pointLight position={[-3, -2, 2]} intensity={0.75} color={isDark ? '#e8c36a' : '#c4921a'} />
      <Particles count={budget.particles} color={particle} />
      <VaultOrb isDark={isDark} />
    </Canvas>
  );
}
