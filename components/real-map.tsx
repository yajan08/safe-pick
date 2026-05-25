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

        // School location (shifted right - Indore, India)
        const schoolPosition: [number, number] = [22.7300, 75.9000];
        
        // Simulated route points - shifted to the right side of the viewport
        const routePoints: [number, number][] = [
          [22.7250, 75.8900],
          [22.7300, 75.8950],
          [22.7350, 75.9000],
          [22.7400, 75.9050],
          [22.7450, 75.9100],
        ];

        // Stop locations - shifted right
        const stops: { position: [number, number]; name: string }[] = [
          { position: [22.7250, 75.8900], name: "Green Valley School" },
          { position: [22.7300, 75.8950], name: "Stop 1 - Vijay Nagar" },
          { position: [22.7350, 75.9000], name: "Stop 2 - Scheme 78" },
          { position: [22.7400, 75.9050], name: "Stop 3 - AB Road" },
          { position: [22.7450, 75.9100], name: "Stop 4 - Palasia" },
        ];

        // Create a functional component for the map
        const MapWrapper = ({ isDark }: { isDark: boolean }) => {
          const [vehiclePosition, setVehiclePosition] = useState(0);

          useEffect(() => {
            const interval = setInterval(() => {
              setVehiclePosition((prev) => (prev + 1) % routePoints.length);
            }, 3000);
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
                center={routePoints[vehiclePosition]}
                radius={10}
                pathOptions={{
                  color: "#22c55e",
                  fillColor: "#22c55e",
                  fillOpacity: 1,
                  weight: 2
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
      
      {/* Map */}
      <div className="w-full h-full opacity-95">
        {MapComponent ? <MapComponent isDark={isDark} /> : (
          <div className="w-full h-full bg-map-bg animate-pulse" />
        )}
      </div>
    </div>
  );
}
