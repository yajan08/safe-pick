"use client";

import { motion } from "framer-motion";
import { useTheme } from "./theme-provider";

export function RealMap() {
  const { theme } = useTheme();
  const isDark = theme === "dark";

  return (
    <div className="absolute inset-0 z-0 overflow-hidden">
      {/* Gradient overlays */}
      <div className="absolute inset-0 bg-gradient-to-r from-background via-background/90 to-transparent z-10" />
      <div className="absolute inset-0 bg-gradient-to-t from-background via-transparent to-background/60 z-10" />
      <div className="absolute inset-0 bg-gradient-to-b from-background/40 via-transparent to-background z-10" />

      {/* Map background with grid pattern */}
      <div className="w-full h-full map-grid opacity-60" />

      {/* Tracking Animation - Positioned on the Right Half */}
      <div className="absolute right-12 md:right-24 lg:right-32 top-1/2 -translate-y-1/2 z-20">
        <svg
          width="300"
          height="400"
          viewBox="0 0 300 400"
          fill="none"
          className="opacity-90"
        >
          {/* Route line - curved path from bottom to destination */}
          <motion.path
            d="M 150 380 C 150 320, 100 280, 120 220 C 140 160, 180 140, 150 80"
            stroke="#c99225"
            strokeWidth="3"
            strokeLinecap="round"
            fill="none"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            transition={{ duration: 2, ease: "easeInOut" }}
          />

          {/* Animated dashed overlay for visual effect */}
          <motion.path
            d="M 150 380 C 150 320, 100 280, 120 220 C 140 160, 180 140, 150 80"
            stroke={isDark ? "rgba(201, 146, 37, 0.3)" : "rgba(201, 146, 37, 0.4)"}
            strokeWidth="6"
            strokeLinecap="round"
            strokeDasharray="8 12"
            fill="none"
            initial={{ strokeDashoffset: 100 }}
            animate={{ strokeDashoffset: 0 }}
            transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
          />

          {/* Starting point node */}
          <circle
            cx="150"
            cy="380"
            r="8"
            fill={isDark ? "#1a1a1a" : "#ffffff"}
            stroke="#c99225"
            strokeWidth="3"
          />
          <circle cx="150" cy="380" r="3" fill="#c99225" />

          {/* Destination marker - School/Drop-off Location */}
          <g transform="translate(150, 60)">
            {/* Pin body */}
            <motion.path
              d="M 0 -30 C -15 -30, -20 -15, -20 -5 C -20 10, 0 25, 0 25 C 0 25, 20 10, 20 -5 C 20 -15, 15 -30, 0 -30 Z"
              fill="#c99225"
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 1.5, duration: 0.5, type: "spring" }}
            />
            {/* Inner circle */}
            <motion.circle
              cx="0"
              cy="-8"
              r="8"
              fill={isDark ? "#0a0a0a" : "#ffffff"}
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 1.8, duration: 0.3 }}
            />
            {/* Pulsing glow effect */}
            <motion.circle
              cx="0"
              cy="-8"
              r="25"
              fill="none"
              stroke="#c99225"
              strokeWidth="2"
              initial={{ scale: 0.5, opacity: 0.8 }}
              animate={{ scale: 1.5, opacity: 0 }}
              transition={{ duration: 2, repeat: Infinity, ease: "easeOut" }}
            />
          </g>

          {/* Moving vehicle dot */}
          <motion.g
            initial={{ offsetDistance: "0%" }}
            animate={{ offsetDistance: "100%" }}
            transition={{
              duration: 6,
              repeat: Infinity,
              ease: "linear",
            }}
            style={{
              offsetPath: `path("M 150 380 C 150 320, 100 280, 120 220 C 140 160, 180 140, 150 80")`,
            }}
          >
            {/* Vehicle glow */}
            <motion.circle
              cx="0"
              cy="0"
              r="16"
              fill="#c99225"
              opacity="0.3"
              animate={{ scale: [1, 1.3, 1] }}
              transition={{ duration: 1.5, repeat: Infinity }}
            />
            {/* Vehicle dot */}
            <circle cx="0" cy="0" r="8" fill="#c99225" />
            <circle
              cx="0"
              cy="0"
              r="4"
              fill={isDark ? "#0a0a0a" : "#ffffff"}
            />
          </motion.g>

          {/* Waypoint markers along the route */}
          <g>
            <circle
              cx="120"
              cy="220"
              r="5"
              fill={isDark ? "#1a1a1a" : "#ffffff"}
              stroke="#c99225"
              strokeWidth="2"
            />
            <circle
              cx="140"
              cy="160"
              r="5"
              fill={isDark ? "#1a1a1a" : "#ffffff"}
              stroke="#c99225"
              strokeWidth="2"
            />
          </g>
        </svg>

        {/* Label for destination */}
        <motion.div
          className="absolute -top-2 left-1/2 -translate-x-1/2 glass px-3 py-1.5 rounded-lg"
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 2, duration: 0.5 }}
        >
          <span className="text-xs font-medium text-gold whitespace-nowrap">
            School Drop-off
          </span>
        </motion.div>
      </div>
    </div>
  );
}
