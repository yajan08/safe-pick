"use client";

import { motion, AnimatePresence } from "framer-motion";
import { useState, useEffect } from "react";
import { MapPin, Clock, CheckCircle2, Bus, Bell } from "lucide-react";

const statuses = [
  {
    icon: Bus,
    text: "Trip Started",
    time: "7:45 AM",
    color: "text-gold",
  },
  {
    icon: CheckCircle2,
    text: "Rahul Boarded",
    time: "7:52 AM",
    color: "text-emerald-400",
  },
  {
    icon: MapPin,
    text: "En Route to School",
    time: "7:55 AM",
    color: "text-gold",
  },
  {
    icon: Clock,
    text: "Arriving in 5 mins",
    time: "8:10 AM",
    color: "text-gold-light",
  },
  {
    icon: Bell,
    text: "Dropped at School",
    time: "8:15 AM",
    color: "text-emerald-400",
  },
];

export function PhoneMockup() {
  const [currentStatus, setCurrentStatus] = useState(0);
  const [isHovered, setIsHovered] = useState(false);

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentStatus((prev) => (prev + 1) % statuses.length);
    }, 2500);
    return () => clearInterval(interval);
  }, []);

  const status = statuses[currentStatus];
  const StatusIcon = status.icon;

  return (
    <motion.div
      className="relative"
      onHoverStart={() => setIsHovered(true)}
      onHoverEnd={() => setIsHovered(false)}
      initial={{ opacity: 0, y: 50 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.8, delay: 0.5 }}
    >
      {/* Phone frame */}
      <motion.div
        className="relative w-[280px] h-[560px] rounded-[3rem] bg-ebony-light border-4 border-border p-2 glow-gold"
        animate={{
          scale: isHovered ? 1.05 : 1,
          boxShadow: isHovered
            ? "0 0 60px rgba(201, 146, 37, 0.5)"
            : "0 0 30px rgba(201, 146, 37, 0.3)",
        }}
        transition={{ duration: 0.3 }}
      >
        {/* Notch */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-7 bg-ebony-light rounded-b-2xl z-20" />

        {/* Screen */}
        <div className="w-full h-full rounded-[2.5rem] bg-background overflow-hidden relative">
          {/* Status bar */}
          <div className="flex justify-between items-center px-8 pt-3 pb-2 text-xs text-muted">
            <span>9:41</span>
            <div className="flex gap-1">
              <div className="w-4 h-2 bg-muted rounded-sm" />
              <div className="w-4 h-2 bg-muted rounded-sm" />
              <div className="w-6 h-3 bg-gold rounded-sm" />
            </div>
          </div>

          {/* App header */}
          <div className="px-4 py-3 border-b border-border">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-gold/20 flex items-center justify-center">
                <Bus className="w-4 h-4 text-gold" />
              </div>
              <div>
                <p className="text-sm font-semibold text-foreground">SafePick</p>
                <p className="text-xs text-muted">Live Tracking</p>
              </div>
            </div>
          </div>

          {/* Mini map */}
          <div className="mx-4 mt-4 h-32 rounded-xl bg-ebony-light border border-border overflow-hidden relative">
            <div className="absolute inset-0 map-grid opacity-50" />
            <motion.div
              className="absolute w-3 h-3 bg-gold rounded-full"
              animate={{
                left: ["20%", "40%", "60%", "80%", "60%"],
                top: ["60%", "50%", "40%", "30%", "40%"],
              }}
              transition={{ duration: 8, repeat: Infinity }}
            />
            <div className="absolute bottom-2 right-2 px-2 py-1 bg-background/80 rounded text-xs text-gold">
              Live
            </div>
          </div>

          {/* Status card */}
          <div className="mx-4 mt-4 p-4 rounded-xl glass border border-gold/20">
            <p className="text-xs text-muted mb-2">Current Status</p>
            <AnimatePresence mode="wait">
              <motion.div
                key={currentStatus}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.3 }}
                className="flex items-center gap-3"
              >
                <div className="w-10 h-10 rounded-full bg-gold/10 flex items-center justify-center">
                  <StatusIcon className={`w-5 h-5 ${status.color}`} />
                </div>
                <div>
                  <p className="font-medium text-foreground">{status.text}</p>
                  <p className="text-xs text-muted">{status.time}</p>
                </div>
              </motion.div>
            </AnimatePresence>
          </div>

          {/* Quick actions */}
          <div className="mx-4 mt-4 grid grid-cols-2 gap-2">
            <div className="p-3 rounded-lg bg-ebony-light border border-border text-center">
              <p className="text-xs text-muted">ETA</p>
              <p className="text-lg font-bold text-gold">5 min</p>
            </div>
            <div className="p-3 rounded-lg bg-ebony-light border border-border text-center">
              <p className="text-xs text-muted">Distance</p>
              <p className="text-lg font-bold text-foreground">1.2 km</p>
            </div>
          </div>

          {/* Bottom notification */}
          <motion.div
            className="absolute bottom-4 left-4 right-4 p-3 rounded-xl bg-gold/10 border border-gold/30"
            animate={{ opacity: [0.7, 1, 0.7] }}
            transition={{ duration: 2, repeat: Infinity }}
          >
            <div className="flex items-center gap-2">
              <Bell className="w-4 h-4 text-gold" />
              <p className="text-xs text-gold">QR verification required at pickup</p>
            </div>
          </motion.div>
        </div>
      </motion.div>

      {/* Floating badge */}
      <motion.div
        className="absolute -top-4 -right-4 px-3 py-1 rounded-full bg-gold text-background text-xs font-semibold"
        animate={{ y: [0, -5, 0] }}
        transition={{ duration: 2, repeat: Infinity }}
      >
        LIVE
      </motion.div>
    </motion.div>
  );
}
