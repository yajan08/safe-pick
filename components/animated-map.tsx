"use client";

import { motion } from "framer-motion";
import { useEffect, useState } from "react";
import { useTheme } from "./theme-provider";

interface MapNode {
  id: number;
  x: number;
  y: number;
  delay: number;
}

interface MapLine {
  id: number;
  x1: number;
  y1: number;
  x2: number;
  y2: number;
  delay: number;
}

interface AnimatedMapProps {
  focusPoint?: { x: number; y: number };
}

export function AnimatedMap({ focusPoint }: AnimatedMapProps) {
  const [nodes, setNodes] = useState<MapNode[]>([]);
  const [lines, setLines] = useState<MapLine[]>([]);
  const { theme } = useTheme();

  const isDark = theme === "dark";

  useEffect(() => {
    // Generate random nodes
    const generatedNodes: MapNode[] = Array.from({ length: 20 }, (_, i) => ({
      id: i,
      x: Math.random() * 100,
      y: Math.random() * 100,
      delay: Math.random() * 2,
    }));
    setNodes(generatedNodes);

    // Generate connecting lines
    const generatedLines: MapLine[] = [];
    for (let i = 0; i < generatedNodes.length - 1; i++) {
      if (Math.random() > 0.3) {
        generatedLines.push({
          id: i,
          x1: generatedNodes[i].x,
          y1: generatedNodes[i].y,
          x2: generatedNodes[i + 1].x,
          y2: generatedNodes[i + 1].y,
          delay: Math.random() * 2,
        });
      }
    }
    setLines(generatedLines);
  }, []);

  // Colors based on theme
  const nodeColor = isDark ? "#c99225" : "#c99225";
  const lineColor = isDark ? "rgba(201, 146, 37, 0.2)" : "rgba(0, 0, 0, 0.15)";
  const pulseColor = isDark ? "rgba(201, 146, 37, 0.3)" : "rgba(201, 146, 37, 0.4)";

  return (
    <div className="absolute inset-0 overflow-hidden map-grid">
      {/* Gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-l from-transparent via-transparent to-background z-10" />
      <div className="absolute inset-0 bg-gradient-to-t from-background via-transparent to-background/50 z-10" />

      <motion.svg 
        className="w-full h-full" 
        viewBox="0 0 100 100" 
        preserveAspectRatio="xMidYMid slice"
        animate={focusPoint ? { 
          viewBox: `${focusPoint.x - 25} ${focusPoint.y - 25} 50 50` 
        } : {}}
        transition={{ duration: 1.5, ease: "easeInOut" }}
      >
        {/* Animated lines */}
        {lines.map((line) => (
          <motion.line
            key={`line-${line.id}`}
            x1={line.x1}
            y1={line.y1}
            x2={line.x2}
            y2={line.y2}
            stroke={lineColor}
            strokeWidth="0.2"
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: 1, opacity: [0, 0.5, 0.2] }}
            transition={{
              duration: 3,
              delay: line.delay,
              repeat: Infinity,
              repeatType: "reverse",
            }}
          />
        ))}

        {/* Moving vehicle indicator */}
        <motion.circle
          r="0.8"
          fill={nodeColor}
          initial={{ cx: 20, cy: 80 }}
          animate={{
            cx: [20, 40, 60, 80, 60, 40, 20],
            cy: [80, 60, 50, 30, 50, 60, 80],
          }}
          transition={{
            duration: 15,
            repeat: Infinity,
            ease: "linear",
          }}
        >
          <animate
            attributeName="opacity"
            values="1;0.5;1"
            dur="1s"
            repeatCount="indefinite"
          />
        </motion.circle>

        {/* Pulse ring around vehicle */}
        <motion.circle
          r="2"
          fill="none"
          stroke={nodeColor}
          strokeWidth="0.1"
          initial={{ cx: 20, cy: 80 }}
          animate={{
            cx: [20, 40, 60, 80, 60, 40, 20],
            cy: [80, 60, 50, 30, 50, 60, 80],
            r: [1, 3, 1],
            opacity: [0.8, 0, 0.8],
          }}
          transition={{
            duration: 15,
            repeat: Infinity,
            ease: "linear",
          }}
        />

        {/* Static nodes (stops) */}
        {nodes.map((node) => (
          <motion.g key={`node-${node.id}`}>
            <motion.circle
              cx={node.x}
              cy={node.y}
              r="0.5"
              fill={nodeColor}
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: [0.3, 0.8, 0.3] }}
              transition={{
                duration: 2,
                delay: node.delay,
                repeat: Infinity,
                repeatType: "reverse",
              }}
            />
            <motion.circle
              cx={node.x}
              cy={node.y}
              r="1.5"
              fill="none"
              stroke={pulseColor}
              strokeWidth="0.1"
              initial={{ scale: 0 }}
              animate={{ scale: [1, 1.5, 1], opacity: [0.5, 0, 0.5] }}
              transition={{
                duration: 3,
                delay: node.delay,
                repeat: Infinity,
              }}
            />
          </motion.g>
        ))}
      </motion.svg>
    </div>
  );
}
