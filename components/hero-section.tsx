"use client";

import { motion } from "framer-motion";
import { AnimatedMap } from "./animated-map";
import { PhoneMockup } from "./phone-mockup";
import { Shield, QrCode, MapPin } from "lucide-react";

export function HeroSection() {
  const headlineWords = ["Real-Time", "Trust.", "Absolute", "Peace", "of", "Mind."];

  return (
    <section className="relative min-h-screen flex items-center overflow-hidden">
      {/* Animated background map */}
      <AnimatedMap />

      {/* Content */}
      <div className="relative z-20 w-full max-w-7xl mx-auto px-6 py-20 lg:py-0">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left content */}
          <div className="space-y-8">
            {/* Badge */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full glass border border-gold/30"
            >
              <Shield className="w-4 h-4 text-gold" />
              <span className="text-sm text-muted">Trusted by 500+ Schools</span>
            </motion.div>

            {/* Headline */}
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
              className="text-lg md:text-xl text-muted max-w-lg leading-relaxed"
            >
              Verified child pickup and drop confirmations using{" "}
              <span className="text-gold font-medium">QR technology</span>. Know exactly
              where your child is, every moment of their journey.
            </motion.p>

            {/* Feature pills */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.9 }}
              className="flex flex-wrap gap-3"
            >
              {[
                { icon: MapPin, text: "Live GPS Tracking" },
                { icon: QrCode, text: "QR Verification" },
                { icon: Shield, text: "Anti-Cheat System" },
              ].map((feature, index) => (
                <div
                  key={index}
                  className="flex items-center gap-2 px-4 py-2 rounded-full bg-ebony-light border border-border"
                >
                  <feature.icon className="w-4 h-4 text-gold" />
                  <span className="text-sm text-foreground">{feature.text}</span>
                </div>
              ))}
            </motion.div>

            {/* CTA Buttons */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 1.1 }}
              className="flex flex-wrap gap-4 pt-4"
            >
              <motion.button
                className="group relative px-8 py-4 rounded-full bg-gold text-background font-semibold overflow-hidden"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <span className="relative z-10">Get Started Free</span>
                <motion.div
                  className="absolute inset-0 bg-gold-light"
                  initial={{ x: "-100%" }}
                  whileHover={{ x: 0 }}
                  transition={{ duration: 0.3 }}
                />
              </motion.button>
              <motion.button
                className="px-8 py-4 rounded-full border border-gold/50 text-gold font-semibold hover:bg-gold/10 transition-colors"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                Watch Demo
              </motion.button>
            </motion.div>
          </div>

          {/* Right content - Phone mockup */}
          <div className="flex justify-center lg:justify-end">
            <PhoneMockup />
          </div>
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
