"use client";

import { motion, AnimatePresence } from "framer-motion";
import { useState } from "react";
import { MapPin, QrCode, AlertTriangle, Check, Clock } from "lucide-react";

interface Stage {
  id: number;
  title: string;
  description: string;
  mapFocus: { x: number; y: number };
}

const stages: Stage[] = [
  {
    id: 1,
    title: "Trip Initialization",
    description: "Driver starts the route. All parents receive notification.",
    mapFocus: { x: 20, y: 80 },
  },
  {
    id: 2,
    title: "Verified QR Boarding",
    description: "Child scans QR code. Instant verification sent to parents.",
    mapFocus: { x: 50, y: 50 },
  },
  {
    id: 3,
    title: "Security Edge-Cases",
    description: "What happens when a child forgets their QR card?",
    mapFocus: { x: 70, y: 30 },
  },
];

export function TripSimulator() {
  const [currentStage, setCurrentStage] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);

  const handleStageClick = (index: number) => {
    setCurrentStage(index);
  };

  const handlePlayDemo = () => {
    setIsPlaying(true);
    setCurrentStage(0);
    
    // Auto-advance through stages
    const interval = setInterval(() => {
      setCurrentStage((prev) => {
        if (prev >= stages.length - 1) {
          clearInterval(interval);
          setIsPlaying(false);
          return prev;
        }
        return prev + 1;
      });
    }, 3000);
  };

  return (
    <section className="relative py-24 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl md:text-4xl font-bold text-foreground mb-4">
            Interactive <span className="text-gold">Trip Simulator</span>
          </h2>
          <p className="text-muted max-w-2xl mx-auto">
            Experience how SafePick keeps your child safe at every step of the journey
          </p>
        </motion.div>

        {/* Timeline Navigation */}
        <div className="flex justify-center mb-12">
          <div className="flex items-center gap-4">
            {stages.map((stage, index) => (
              <div key={stage.id} className="flex items-center">
                <motion.button
                  onClick={() => handleStageClick(index)}
                  className={`relative flex items-center justify-center w-12 h-12 rounded-full border-2 transition-all ${
                    currentStage >= index
                      ? "bg-gold border-gold text-background"
                      : "bg-transparent border-border text-muted hover:border-gold/50"
                  }`}
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <span className="font-bold">{stage.id}</span>
                  {currentStage > index && (
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      className="absolute inset-0 flex items-center justify-center bg-gold rounded-full"
                    >
                      <Check className="w-5 h-5 text-background" />
                    </motion.div>
                  )}
                </motion.button>
                {index < stages.length - 1 && (
                  <div className="w-16 md:w-24 h-0.5 bg-border mx-2">
                    <motion.div
                      className="h-full bg-gold"
                      initial={{ width: 0 }}
                      animate={{ width: currentStage > index ? "100%" : "0%" }}
                      transition={{ duration: 0.5 }}
                    />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Stage Content */}
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left - Stage Info */}
          <div className="space-y-6">
            <AnimatePresence mode="wait">
              <motion.div
                key={currentStage}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                transition={{ duration: 0.3 }}
                className="space-y-4"
              >
                <h3 className="text-2xl md:text-3xl font-bold text-foreground">
                  {stages[currentStage].title}
                </h3>
                <p className="text-lg text-muted">
                  {stages[currentStage].description}
                </p>
              </motion.div>
            </AnimatePresence>

            {/* Play Demo Button */}
            <motion.button
              onClick={handlePlayDemo}
              disabled={isPlaying}
              className={`px-8 py-3 rounded-full font-semibold transition-all ${
                isPlaying
                  ? "bg-gold/50 text-background/70 cursor-not-allowed"
                  : "bg-gold text-background hover:shadow-lg hover:shadow-gold/30"
              }`}
              whileHover={!isPlaying ? { scale: 1.02 } : {}}
              whileTap={!isPlaying ? { scale: 0.98 } : {}}
            >
              {isPlaying ? "Playing..." : "Play Full Demo"}
            </motion.button>
          </div>

          {/* Right - Phone Mockup with Stage Content */}
          <div className="flex justify-center">
            <motion.div
              className="relative w-[280px] h-[580px] rounded-[3rem] bg-ebony-light border-4 border-border overflow-hidden"
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
            >
              {/* Phone Notch */}
              <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-7 bg-background rounded-b-2xl z-20" />
              
              {/* Phone Screen */}
              <div className="absolute inset-2 rounded-[2.5rem] bg-card overflow-hidden">
                <AnimatePresence mode="wait">
                  {/* Stage 1 - Trip Started */}
                  {currentStage === 0 && (
                    <motion.div
                      key="stage1"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      className="h-full flex flex-col"
                    >
                      <div className="bg-gold p-4 text-center">
                        <h4 className="text-background font-bold">SafePick</h4>
                      </div>
                      <div className="flex-1 p-4 space-y-4">
                        <motion.div
                          initial={{ y: 20, opacity: 0 }}
                          animate={{ y: 0, opacity: 1 }}
                          transition={{ delay: 0.3 }}
                          className="p-4 rounded-xl bg-ebony border border-gold/30"
                        >
                          <div className="flex items-center gap-3 mb-3">
                            <div className="w-10 h-10 rounded-full bg-gold/20 flex items-center justify-center">
                              <MapPin className="w-5 h-5 text-gold" />
                            </div>
                            <div>
                              <p className="font-semibold text-foreground text-sm">Trip Started</p>
                              <p className="text-xs text-muted">7:45 AM</p>
                            </div>
                          </div>
                          <p className="text-sm text-muted">
                            School van has departed from Delhi Public School
                          </p>
                        </motion.div>
                        <motion.div
                          initial={{ y: 20, opacity: 0 }}
                          animate={{ y: 0, opacity: 1 }}
                          transition={{ delay: 0.6 }}
                          className="p-3 rounded-lg bg-gold/10 border border-gold/20"
                        >
                          <p className="text-xs text-gold">
                            ETA to your stop: 12 minutes
                          </p>
                        </motion.div>
                      </div>
                    </motion.div>
                  )}

                  {/* Stage 2 - QR Boarding */}
                  {currentStage === 1 && (
                    <motion.div
                      key="stage2"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      className="h-full flex flex-col"
                    >
                      <div className="bg-gold p-4 text-center">
                        <h4 className="text-background font-bold">SafePick</h4>
                      </div>
                      <div className="flex-1 p-4 space-y-4">
                        <motion.div
                          initial={{ scale: 0.8, opacity: 0 }}
                          animate={{ scale: 1, opacity: 1 }}
                          transition={{ delay: 0.3, type: "spring" }}
                          className="p-4 rounded-xl bg-green-500/10 border border-green-500/30"
                        >
                          <div className="flex items-center gap-3 mb-3">
                            <div className="w-10 h-10 rounded-full bg-green-500/20 flex items-center justify-center">
                              <QrCode className="w-5 h-5 text-green-500" />
                            </div>
                            <div>
                              <p className="font-semibold text-foreground text-sm">Rahul Boarded</p>
                              <p className="text-xs text-green-500">Verified</p>
                            </div>
                          </div>
                          <p className="text-sm text-muted">
                            QR code scanned successfully at 7:52 AM
                          </p>
                        </motion.div>
                        <motion.div
                          initial={{ y: 20, opacity: 0 }}
                          animate={{ y: 0, opacity: 1 }}
                          transition={{ delay: 0.6 }}
                          className="flex items-center gap-2 p-3 rounded-lg bg-ebony"
                        >
                          <Clock className="w-4 h-4 text-gold" />
                          <p className="text-xs text-muted">
                            Timestamp verified by GPS location
                          </p>
                        </motion.div>
                      </div>
                    </motion.div>
                  )}

                  {/* Stage 3 - Edge Case */}
                  {currentStage === 2 && (
                    <motion.div
                      key="stage3"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      className="h-full flex flex-col"
                    >
                      <div className="bg-gold p-4 text-center">
                        <h4 className="text-background font-bold">SafePick</h4>
                      </div>
                      <div className="flex-1 p-4 space-y-4">
                        <motion.div
                          initial={{ scale: 0.8, opacity: 0 }}
                          animate={{ scale: 1, opacity: 1 }}
                          transition={{ delay: 0.3, type: "spring" }}
                          className="p-4 rounded-xl bg-orange-500/10 border border-orange-500/30"
                        >
                          <div className="flex items-center gap-3 mb-3">
                            <div className="w-10 h-10 rounded-full bg-orange-500/20 flex items-center justify-center">
                              <AlertTriangle className="w-5 h-5 text-orange-500" />
                            </div>
                            <div>
                              <p className="font-semibold text-foreground text-sm">Pending Verification</p>
                              <p className="text-xs text-orange-500">Action Required</p>
                            </div>
                          </div>
                          <p className="text-sm text-muted">
                            Rahul forgot QR card. Manual verification requested.
                          </p>
                        </motion.div>
                        <motion.div
                          initial={{ y: 20, opacity: 0 }}
                          animate={{ y: 0, opacity: 1 }}
                          transition={{ delay: 0.6 }}
                          className="space-y-2"
                        >
                          <button className="w-full py-3 rounded-xl bg-gold text-background font-semibold text-sm">
                            Approve Boarding
                          </button>
                          <button className="w-full py-3 rounded-xl border border-border text-foreground font-semibold text-sm">
                            Call Driver
                          </button>
                        </motion.div>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>

              {/* Home Indicator */}
              <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-32 h-1 bg-foreground/30 rounded-full" />
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  );
}
