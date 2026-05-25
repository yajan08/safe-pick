"use client";

import { motion, AnimatePresence } from "framer-motion";
import { useState, useEffect } from "react";
import { Shield, QrCode, AlertTriangle, CheckCircle, Clock, MapPin, User } from "lucide-react";

interface TripStage {
  id: number;
  title: string;
  description: string;
  icon: React.ReactNode;
  status: "pending" | "active" | "complete" | "warning";
  details: string[];
}

const tripStages: TripStage[] = [
  {
    id: 1,
    title: "Trip Initialization",
    description: "Van #12 has started the morning route",
    icon: <MapPin className="w-5 h-5" />,
    status: "complete",
    details: [
      "Driver: Rajesh Kumar (Verified)",
      "Route: Green Valley School - Sector 7",
      "Expected Students: 12",
      "Start Time: 7:15 AM"
    ]
  },
  {
    id: 2,
    title: "Verified QR Boarding",
    description: "Rahul has boarded the van",
    icon: <QrCode className="w-5 h-5" />,
    status: "active",
    details: [
      "Student: Rahul Sharma",
      "QR Scanned: 7:28 AM",
      "Parent Notified: Priya Sharma",
      "Boarding Location: Stop #3 - Vijay Nagar"
    ]
  },
  {
    id: 3,
    title: "Security Edge-Case",
    description: "Aarav forgot QR card - Manual verification required",
    icon: <AlertTriangle className="w-5 h-5" />,
    status: "warning",
    details: [
      "Student: Aarav Patel",
      "Status: Pending Verification",
      "Action: Photo sent to parent",
      "Parent Response: Awaiting approval"
    ]
  }
];

export function TripSimulator() {
  const [currentStage, setCurrentStage] = useState(0);
  const [isPlaying, setIsPlaying] = useState(true);

  useEffect(() => {
    if (!isPlaying) return;
    
    const interval = setInterval(() => {
      setCurrentStage((prev) => (prev + 1) % tripStages.length);
    }, 4000);
    
    return () => clearInterval(interval);
  }, [isPlaying]);

  const getStatusColor = (status: TripStage["status"]) => {
    switch (status) {
      case "complete": return "text-green-500";
      case "active": return "text-gold";
      case "warning": return "text-orange-500";
      default: return "text-muted";
    }
  };

  const getStatusBg = (status: TripStage["status"]) => {
    switch (status) {
      case "complete": return "bg-green-500/20 border-green-500/50";
      case "active": return "bg-gold/20 border-gold/50";
      case "warning": return "bg-orange-500/20 border-orange-500/50";
      default: return "bg-muted/20 border-muted/50";
    }
  };

  return (
    <section className="relative py-24 overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 bg-gradient-to-b from-background via-ebony-light to-background" />
      
      <div className="relative z-10 max-w-7xl mx-auto px-6">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold text-foreground mb-4">
            See SafePick in <span className="text-gold text-glow">Action</span>
          </h2>
          <p className="text-muted text-lg max-w-2xl mx-auto">
            Experience how our system handles real-world scenarios with precision and care
          </p>
        </motion.div>

        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Timeline */}
          <div className="space-y-6">
            {tripStages.map((stage, index) => (
              <motion.div
                key={stage.id}
                initial={{ opacity: 0, x: -30 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.15 }}
                onClick={() => {
                  setCurrentStage(index);
                  setIsPlaying(false);
                }}
                className={`relative cursor-pointer transition-all duration-300 ${
                  currentStage === index ? "scale-[1.02]" : "opacity-70 hover:opacity-100"
                }`}
              >
                {/* Connecting line */}
                {index < tripStages.length - 1 && (
                  <div className="absolute left-6 top-14 w-0.5 h-[calc(100%+1rem)] bg-gradient-to-b from-gold/50 to-transparent" />
                )}
                
                <div className={`glass rounded-2xl p-5 border-2 transition-all duration-300 ${
                  currentStage === index ? getStatusBg(stage.status) : "border-transparent"
                }`}>
                  <div className="flex items-start gap-4">
                    {/* Icon */}
                    <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                      currentStage === index ? getStatusBg(stage.status) : "bg-ebony"
                    } ${getStatusColor(stage.status)}`}>
                      {stage.icon}
                    </div>
                    
                    {/* Content */}
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold text-foreground">{stage.title}</h3>
                        {stage.status === "complete" && <CheckCircle className="w-4 h-4 text-green-500" />}
                        {stage.status === "warning" && <AlertTriangle className="w-4 h-4 text-orange-500" />}
                      </div>
                      <p className="text-sm text-muted">{stage.description}</p>
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          {/* Detail Card */}
          <AnimatePresence mode="wait">
            <motion.div
              key={currentStage}
              initial={{ opacity: 0, y: 20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -20, scale: 0.95 }}
              transition={{ duration: 0.3 }}
              className="glass rounded-3xl p-8 border-2 border-gold/30 glow-gold"
            >
              <div className="flex items-center gap-3 mb-6">
                <div className={`w-14 h-14 rounded-2xl flex items-center justify-center ${
                  getStatusBg(tripStages[currentStage].status)
                } ${getStatusColor(tripStages[currentStage].status)}`}>
                  {tripStages[currentStage].icon}
                </div>
                <div>
                  <h3 className="text-xl font-bold text-foreground">
                    {tripStages[currentStage].title}
                  </h3>
                  <p className="text-sm text-muted">{tripStages[currentStage].description}</p>
                </div>
              </div>

              {/* Details */}
              <div className="space-y-3">
                {tripStages[currentStage].details.map((detail, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="flex items-center gap-3 p-3 rounded-xl bg-ebony/50"
                  >
                    <div className="w-2 h-2 rounded-full bg-gold" />
                    <span className="text-sm text-foreground">{detail}</span>
                  </motion.div>
                ))}
              </div>

              {/* Status Badge */}
              <div className="mt-6 flex items-center justify-between">
                <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-full ${
                  getStatusBg(tripStages[currentStage].status)
                }`}>
                  {tripStages[currentStage].status === "complete" && <CheckCircle className="w-4 h-4 text-green-500" />}
                  {tripStages[currentStage].status === "active" && <Clock className="w-4 h-4 text-gold" />}
                  {tripStages[currentStage].status === "warning" && <AlertTriangle className="w-4 h-4 text-orange-500" />}
                  <span className={`text-sm font-medium capitalize ${getStatusColor(tripStages[currentStage].status)}`}>
                    {tripStages[currentStage].status === "warning" ? "Pending Verification" : tripStages[currentStage].status}
                  </span>
                </div>

                {/* Play/Pause */}
                <button
                  onClick={() => setIsPlaying(!isPlaying)}
                  className="text-sm text-muted hover:text-gold transition-colors"
                >
                  {isPlaying ? "Pause" : "Play"} Demo
                </button>
              </div>
            </motion.div>
          </AnimatePresence>
        </div>
      </div>
    </section>
  );
}
