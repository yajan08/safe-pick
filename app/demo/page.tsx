"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { ArrowLeft, Play } from "lucide-react";

export default function DemoPage() {
  return (
    <main className="min-h-screen bg-background">
      {/* Back Navigation */}
      <div className="fixed top-0 left-0 right-0 z-50 px-6 py-4">
        <div className="max-w-7xl mx-auto">
          <Link href="/">
            <motion.button
              className="flex items-center gap-2 px-4 py-2 rounded-full glass border border-gold/20 text-foreground hover:text-gold transition-colors"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <ArrowLeft className="w-4 h-4" />
              <span className="text-sm">Back to Home</span>
            </motion.button>
          </Link>
        </div>
      </div>

      {/* Demo Content */}
      <div className="flex items-center justify-center min-h-screen px-6">
        <div className="max-w-4xl w-full">
          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="text-center mb-12"
          >
            <h1 className="text-3xl md:text-4xl font-bold text-foreground mb-4">
              <span className="text-gold">SafePick</span> Demo
            </h1>
            <p className="text-muted max-w-2xl mx-auto">
              See how SafePick ensures your child&apos;s safety with real-time tracking and verified pickups
            </p>
          </motion.div>

          {/* Video Skeleton Container */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="relative aspect-video rounded-2xl overflow-hidden glass border border-gold/20"
          >
            {/* Skeleton Background */}
            <div className="absolute inset-0 bg-ebony-light">
              {/* Animated gradient skeleton */}
              <div className="absolute inset-0 bg-gradient-to-r from-ebony via-ebony-light to-ebony animate-pulse" />
              
              {/* Grid Pattern */}
              <div 
                className="absolute inset-0 opacity-30"
                style={{
                  backgroundImage: `
                    linear-gradient(rgba(201, 146, 37, 0.1) 1px, transparent 1px),
                    linear-gradient(90deg, rgba(201, 146, 37, 0.1) 1px, transparent 1px)
                  `,
                  backgroundSize: '40px 40px'
                }}
              />
            </div>

            {/* Play Button Placeholder */}
            <div className="absolute inset-0 flex items-center justify-center">
              <motion.div
                className="w-20 h-20 rounded-full bg-gold/20 border-2 border-gold flex items-center justify-center cursor-pointer"
                whileHover={{ scale: 1.1, backgroundColor: "rgba(201, 146, 37, 0.3)" }}
                whileTap={{ scale: 0.95 }}
              >
                <Play className="w-8 h-8 text-gold ml-1" />
              </motion.div>
            </div>

            {/* Coming Soon Badge */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.5 }}
              className="absolute top-4 right-4 px-4 py-2 rounded-full bg-gold/10 border border-gold/30"
            >
              <span className="text-sm text-gold font-medium">Video Coming Soon</span>
            </motion.div>

            {/* Video Controls Skeleton */}
            <div className="absolute bottom-0 left-0 right-0 p-4">
              <div className="flex items-center gap-4">
                {/* Progress bar skeleton */}
                <div className="flex-1 h-1 bg-foreground/10 rounded-full overflow-hidden">
                  <motion.div
                    className="h-full bg-gold/50 rounded-full"
                    initial={{ width: 0 }}
                    animate={{ width: "30%" }}
                    transition={{ duration: 2, repeat: Infinity, repeatType: "reverse" }}
                  />
                </div>
                {/* Time skeleton */}
                <div className="text-xs text-muted/50 font-mono">0:00 / 2:30</div>
              </div>
            </div>
          </motion.div>

          {/* Feature highlights below video */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.4 }}
            className="grid md:grid-cols-3 gap-6 mt-12"
          >
            {[
              { title: "Real-Time Tracking", desc: "Live GPS updates every 10 seconds" },
              { title: "QR Verification", desc: "Secure boarding confirmation" },
              { title: "Instant Alerts", desc: "Push notifications to parents" },
            ].map((feature, index) => (
              <div
                key={index}
                className="p-6 rounded-xl glass border border-gold/10 text-center"
              >
                <h3 className="text-foreground font-semibold mb-2">{feature.title}</h3>
                <p className="text-sm text-muted">{feature.desc}</p>
              </div>
            ))}
          </motion.div>
        </div>
      </div>
    </main>
  );
}
