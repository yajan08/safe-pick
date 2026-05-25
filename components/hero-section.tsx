"use client";

import { motion } from "framer-motion";
import { RealMap } from "./real-map";

export function HeroSection() {
  const headlineWords = ["Real-Time", "Trust.", "Absolute", "Peace", "of", "Mind."];

  return (
    <section className="relative min-h-screen flex items-center overflow-hidden">
      {/* Real map background */}
      <RealMap />

      {/* Content */}
      <div className="relative z-20 w-full max-w-7xl mx-auto px-6 py-20 lg:py-0">
        <div className="max-w-2xl">
          {/* Headline - Left aligned */}
          <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight">
            {headlineWords.map((word, index) => (
              <motion.span
                key={index}
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{
                  duration: 0.5,
                  delay: index * 0.1,
                }}
                className={`inline-block mr-3 ${
                  index < 2 ? "text-gold text-glow" : "text-foreground"
                }`}
              >
                {word}
              </motion.span>
            ))}
          </h1>

          {/* Subheadline */}
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.7 }}
            className="mt-6 text-lg md:text-xl text-muted max-w-lg leading-relaxed"
          >
            Verified child pickup and drop confirmations using{" "}
            <span className="text-gold font-medium">QR technology</span>. Know exactly
            where your child is, every moment of their journey.
          </motion.p>

          {/* Trust badges */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.9 }}
            className="mt-10 flex flex-wrap gap-4"
          >
            {["End-to-End Encrypted", "Real-Time Updates", "Verified Identity"].map((badge, index) => (
              <motion.div
                key={badge}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 1 + index * 0.1 }}
                className="glass px-4 py-2 rounded-full flex items-center gap-2"
              >
                <div className="w-2 h-2 rounded-full bg-gold animate-pulse" />
                <span className="text-sm text-foreground">{badge}</span>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </div>

      {/* Scroll indicator */}
      <motion.div
        className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.5 }}
      >
        <span className="text-xs text-muted">Scroll to explore</span>
        <motion.div
          className="w-6 h-10 rounded-full border-2 border-gold/50 flex justify-center pt-2"
          animate={{ y: [0, 5, 0] }}
          transition={{ duration: 1.5, repeat: Infinity }}
        >
          <motion.div
            className="w-1 h-2 bg-gold rounded-full"
            animate={{ y: [0, 8, 0], opacity: [1, 0, 1] }}
            transition={{ duration: 1.5, repeat: Infinity }}
          />
        </motion.div>
      </motion.div>
    </section>
  );
}
