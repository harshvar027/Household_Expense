import{r as a,u as R,p as T,j as t}from"./index-BRMIGsPG.js";import{S as E,U as I,a as U,M as A,R as V,e as L,u as p,B as O,P as W,V as u,C as x,b as D,F as B}from"./Float-BdHlYZXA.js";function d(){return d=Object.assign?Object.assign.bind():function(o){for(var e=1;e<arguments.length;e++){var n=arguments[e];for(var s in n)({}).hasOwnProperty.call(n,s)&&(o[s]=n[s])}return o},d.apply(null,arguments)}function N(o,e,n,s){var i;return i=class extends E{constructor(r){super({vertexShader:e,fragmentShader:n,...r});for(const l in o)this.uniforms[l]=new I(o[l]),Object.defineProperty(this,l,{get(){return this.uniforms[l].value},set(m){this.uniforms[l].value=m}});this.uniforms=U.clone(this.uniforms)}},i.key=A.generateUUID(),i}const H=()=>parseInt(V.replace(/\D+/g,"")),X=H(),Y=N({cellSize:.5,sectionSize:1,fadeDistance:100,fadeStrength:1,fadeFrom:1,cellThickness:.5,sectionThickness:1,cellColor:new x,sectionColor:new x,infiniteGrid:!1,followCamera:!1,worldCamProjPosition:new u,worldPlanePosition:new u},`
    varying vec3 localPosition;
    varying vec4 worldPosition;

    uniform vec3 worldCamProjPosition;
    uniform vec3 worldPlanePosition;
    uniform float fadeDistance;
    uniform bool infiniteGrid;
    uniform bool followCamera;

    void main() {
      localPosition = position.xzy;
      if (infiniteGrid) localPosition *= 1.0 + fadeDistance;
      
      worldPosition = modelMatrix * vec4(localPosition, 1.0);
      if (followCamera) {
        worldPosition.xyz += (worldCamProjPosition - worldPlanePosition);
        localPosition = (inverse(modelMatrix) * worldPosition).xyz;
      }

      gl_Position = projectionMatrix * viewMatrix * worldPosition;
    }
  `,`
    varying vec3 localPosition;
    varying vec4 worldPosition;

    uniform vec3 worldCamProjPosition;
    uniform float cellSize;
    uniform float sectionSize;
    uniform vec3 cellColor;
    uniform vec3 sectionColor;
    uniform float fadeDistance;
    uniform float fadeStrength;
    uniform float fadeFrom;
    uniform float cellThickness;
    uniform float sectionThickness;

    float getGrid(float size, float thickness) {
      vec2 r = localPosition.xz / size;
      vec2 grid = abs(fract(r - 0.5) - 0.5) / fwidth(r);
      float line = min(grid.x, grid.y) + 1.0 - thickness;
      return 1.0 - min(line, 1.0);
    }

    void main() {
      float g1 = getGrid(cellSize, cellThickness);
      float g2 = getGrid(sectionSize, sectionThickness);

      vec3 from = worldCamProjPosition*vec3(fadeFrom);
      float dist = distance(from, worldPosition.xyz);
      float d = 1.0 - min(dist / fadeDistance, 1.0);
      vec3 color = mix(cellColor, sectionColor, min(1.0, sectionThickness * g2));

      gl_FragColor = vec4(color, (g1 + g2) * pow(d, fadeStrength));
      gl_FragColor.a = mix(0.75 * gl_FragColor.a, gl_FragColor.a, g2);
      if (gl_FragColor.a <= 0.0) discard;

      #include <tonemapping_fragment>
      #include <${X>=154?"colorspace_fragment":"encodings_fragment"}>
    }
  `),$=a.forwardRef(({args:o,cellColor:e="#000000",sectionColor:n="#2080ff",cellSize:s=.5,sectionSize:i=1,followCamera:r=!1,infiniteGrid:l=!1,fadeDistance:m=100,fadeStrength:w=1,fadeFrom:v=1,cellThickness:P=.5,sectionThickness:y=1,side:j=O,...C},M)=>{L({GridMaterial:Y});const c=a.useRef(null);a.useImperativeHandle(M,()=>c.current,[]);const g=new W,z=new u(0,1,0),b=new u(0,0,0);p(G=>{g.setFromNormalAndCoplanarPoint(z,b).applyMatrix4(c.current.matrixWorld);const h=c.current.material,_=h.uniforms.worldCamProjPosition,k=h.uniforms.worldPlanePosition;g.projectPoint(G.camera.position,_.value),k.value.set(0,0,0).applyMatrix4(c.current.matrixWorld)});const S={cellSize:s,sectionSize:i,cellColor:e,sectionColor:n,cellThickness:P,sectionThickness:y},F={fadeDistance:m,fadeStrength:w,fadeFrom:v,infiniteGrid:l,followCamera:r};return a.createElement("mesh",d({ref:c,frustumCulled:!1},C),a.createElement("gridMaterial",d({transparent:!0,"extensions-derivatives":!0,side:j},S,F)),a.createElement("planeGeometry",{args:o}))});function q(){const o=a.useRef({x:0,y:0});return a.useEffect(()=>{const e=n=>{o.current.x=n.clientX/window.innerWidth*2-1,o.current.y=n.clientY/window.innerHeight*2-1};return window.addEventListener("mousemove",e,{passive:!0}),()=>window.removeEventListener("mousemove",e)},[]),o}function J({children:o}){const e=a.useRef(null),n=q();return p((s,i)=>{if(!e.current)return;const r=1-Math.exp(-i*2.4);e.current.rotation.y+=(n.current.x*.18-e.current.rotation.y)*r,e.current.rotation.x+=(-n.current.y*.1-e.current.rotation.x)*r}),t.jsx("group",{ref:e,children:o})}function K({count:o,color:e}){const n=a.useRef(null),s=a.useMemo(()=>{const i=new Float32Array(o*3);for(let r=0;r<o;r++)i[r*3]=(Math.random()-.5)*16,i[r*3+1]=(Math.random()-.2)*8,i[r*3+2]=(Math.random()-.5)*12-1;return i},[o]);return p((i,r)=>{n.current&&(n.current.rotation.y+=r*.018)}),t.jsxs("points",{ref:n,children:[t.jsx("bufferGeometry",{children:t.jsx("bufferAttribute",{attach:"attributes-position",args:[s,3]})}),t.jsx("pointsMaterial",{size:.028,color:e,transparent:!0,opacity:.45,sizeAttenuation:!0,depthWrite:!1})]})}function f({position:o,color:e,scale:n=1,type:s="octa"}){return t.jsx(B,{speed:1.1,rotationIntensity:.45,floatIntensity:.7,children:t.jsxs("mesh",{position:o,scale:n,children:[s==="torus"?t.jsx("torusGeometry",{args:[.55,.012,12,64]}):s==="ico"?t.jsx("icosahedronGeometry",{args:[.42,0]}):t.jsx("octahedronGeometry",{args:[.38,0]}),t.jsx("meshStandardMaterial",{color:e,emissive:e,emissiveIntensity:.4,metalness:.55,roughness:.28,wireframe:!0,transparent:!0,opacity:.85})]})})}function Q({isDark:o}){const e=o?"#3cefb0":"#0e7a68",n=o?"#e8c36a":"#c4921a",s=o?"#7ee0d0":"#3d8f86",i=o?"#1a3d34":"#b7c9c0",r=o?"#2a8f74":"#0c6b5c",l=typeof window<"u"&&window.innerWidth<768?220:420;return t.jsxs(t.Fragment,{children:[t.jsx("ambientLight",{intensity:o?.35:.7}),t.jsx("pointLight",{position:[4,3,2],intensity:o?1.1:.85,color:e}),t.jsx("pointLight",{position:[-5,1,-2],intensity:.55,color:n}),t.jsxs(J,{children:[t.jsx($,{infiniteGrid:!0,fadeDistance:22,fadeStrength:1.35,sectionSize:2,sectionThickness:.85,cellSize:.5,cellThickness:.4,cellColor:i,sectionColor:r,position:[0,-2.05,0]}),t.jsx(f,{position:[-2.4,.35,-1.2],color:e,type:"octa"}),t.jsx(f,{position:[2.8,.9,-.6],color:n,type:"ico",scale:1.15}),t.jsx(f,{position:[.2,1.35,-2.1],color:s,type:"torus",scale:1.4}),t.jsx(f,{position:[-1.1,-.4,.8],color:e,type:"ico",scale:.7}),t.jsx(K,{count:l,color:e})]})]})}function oe(){const{isDark:o}=R();return T()?null:t.jsx("div",{className:"pointer-events-none fixed inset-0 -z-0","aria-hidden":!0,children:t.jsx(D,{dpr:[1,1.25],camera:{position:[0,1.1,7.2],fov:42},gl:{antialias:!1,alpha:!0,premultipliedAlpha:!1,powerPreference:"low-power"},onCreated:({gl:e})=>{e.setClearColor(0,0),e.setClearAlpha(0)},style:{width:"100%",height:"100%",background:"transparent"},children:t.jsx(Q,{isDark:o})})})}export{oe as default};
