"use client";

import { useEffect, useState } from "react";
import { useTheme } from "./theme-provider";

export function RealMap() {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [MapComponent, setMapComponent] = useState<React.ComponentType<{ isDark: boolean }> | null>(null);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!mounted) return;

    // Dynamically import Leaflet only on client side
    import("leaflet").then((L) => {
      import("react-leaflet").then(({ MapContainer, TileLayer, Polyline, CircleMarker }) => {
        // Fix Leaflet default marker icon issue
        delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)._getIconUrl;
        L.Icon.Default.mergeOptions({
          iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png",
          iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png",
          shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png",
        });

        // School location (shifted far right - Indore, India)
        const schoolPosition: [number, number] = [22.7350, 75.9400];
        
        // Simulated route points - shifted to the far right side of the viewport
        const routePoints: [number, number][] = [
          [22.7200, 75.9250],
          [22.7280, 75.9320],
          [22.7350, 75.9400],
          [22.7420, 75.9480],
          [22.7500, 75.9550],
        ];

        // Stop locations - shifted far right
        const stops: { position: [number, number]; name: string }[] = [
          { position: [22.7200, 75.9250], name: "Green Valley School" },
          { position: [22.7280, 75.9320], name: "Stop 1 - Vijay Nagar" },
          { position: [22.7350, 75.9400], name: "Stop 2 - Scheme 78" },
          { position: [22.7420, 75.9480], name: "Stop 3 - AB Road" },
          { position: [22.7500, 75.9550], name: "Stop 4 - Palasia" },
        ];

        // Create a functional component for the map
        const MapWrapper = ({ isDark }: { isDark: boolean }) => {
          const [vehiclePos, setVehiclePos] = useState<[number, number]>(routePoints[0]);

          useEffect(() => {
            const duration = 20000; // 20 seconds for full route
            const startTime = Date.now();
            
            const interval = setInterval(() => {
              const elapsed = (Date.now() - startTime) % duration;
              const progress = elapsed / duration;
              
              // Find which segment we are in
              const totalSegments = routePoints.length - 1;
              const segmentProgress = progress * totalSegments;
              const currentSegment = Math.floor(segmentProgress);
              const t = segmentProgress - currentSegment; // 0 to 1
              
              if (currentSegment < totalSegments) {
                const startPoint = routePoints[currentSegment];
                const endPoint = routePoints[currentSegment + 1];
                
                const lat = startPoint[0] + (endPoint[0] - startPoint[0]) * t;
                const lng = startPoint[1] + (endPoint[1] - startPoint[1]) * t;
                
                setVehiclePos([lat, lng]);
              }
            }, 50); // 20fps for smooth CSS transition
            
            return () => clearInterval(interval);
          }, []);

          // CartoDB free tiles - no authentication required
          const tileUrl = isDark 
            ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
            : "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png";

          return (
            <MapContainer
              key={isDark ? "dark" : "light"}
              center={schoolPosition}
              zoom={13}
              scrollWheelZoom={false}
              zoomControl={false}
              dragging={false}
              doubleClickZoom={false}
              className="w-full h-full"
              style={{ background: "transparent" }}
            >
              <TileLayer
                attribution='&copy; <a href="https://carto.com/">CARTO</a>'
                url={tileUrl}
                subdomains="abcd"
              />
              
              {/* Route line */}
              <Polyline
                positions={routePoints}
                pathOptions={{ 
                  color: "#c99225", 
                  weight: 4, 
                  opacity: 0.8,
                  dashArray: "10, 10"
                }}
              />
              
              {/* Stop markers */}
              {stops.map((stop, index) => (
                <CircleMarker
                  key={index}
                  center={stop.position}
                  radius={index === 0 ? 12 : 8}
                  pathOptions={{
                    color: "#c99225",
                    fillColor: index === 0 ? "#c99225" : isDark ? "#0a0a0a" : "#ffffff",
                    fillOpacity: 1,
                    weight: 3
                  }}
                />
              ))}

              {/* Moving vehicle marker */}
              <CircleMarker
                center={vehiclePos}
                radius={10}
                pathOptions={{
                  color: "#22c55e",
                  fillColor: "#22c55e",
                  fillOpacity: 1,
                  weight: 2,
                  className: "vehicle-marker"
                }}
              />
            </MapContainer>
          );
        };

        setMapComponent(() => MapWrapper);
      });
    });
  }, [mounted]);

  const isDark = theme === "dark";

  return (
    <div className="absolute inset-0 z-0 overflow-hidden">
      {/* Gradient overlays - lighter for better map visibility, stronger on left for text readability */}
      <div className="absolute inset-0 bg-gradient-to-r from-background via-background/40 to-transparent z-10" />
      <div className="absolute inset-0 bg-gradient-to-t from-background/80 via-transparent to-background/20 z-10" />
      <div className="absolute inset-0 bg-gradient-to-b from-background/20 via-transparent to-background/60 z-10" />
      
      {/* Leaflet CSS */}
      <link
        rel="stylesheet"
        href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
        integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
        crossOrigin=""
      />
      
      {/* Map - shifted to the right */}
      <div className="absolute -right-[10%] top-0 w-[80%] h-full opacity-95">
        {MapComponent ? <MapComponent isDark={isDark} /> : (
          <div className="w-full h-full bg-map-bg animate-pulse" />
        )}
      </div>
    </div>
  );
}
